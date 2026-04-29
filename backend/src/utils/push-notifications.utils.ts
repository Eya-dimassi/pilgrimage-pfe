import admin from 'firebase-admin'

import prisma from '../config/prisma'
import { env } from '../config/env'

let firebaseApp: admin.app.App | null = null

function parseServiceAccount() {
  if (env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    try {
      return JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON)
    } catch (error) {
      console.warn('Firebase service account JSON is invalid:', error)
      return null
    }
  }

  if (env.FIREBASE_PROJECT_ID && env.FIREBASE_CLIENT_EMAIL && env.FIREBASE_PRIVATE_KEY) {
    return {
      projectId: env.FIREBASE_PROJECT_ID,
      clientEmail: env.FIREBASE_CLIENT_EMAIL,
      privateKey: env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    }
  }

  return null
}

function getFirebaseApp() {
  if (firebaseApp) return firebaseApp

  const serviceAccount = parseServiceAccount()
  if (!serviceAccount) {
    return null
  }

  firebaseApp = admin.apps.length
    ? admin.app()
    : admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      })

  return firebaseApp
}

type PushPayload = {
  userIds: string[]
  role: 'GUIDE' | 'PELERIN' | 'FAMILLE'
  title: string
  body: string
  data?: Record<string, string>
}

export async function sendPushToUsers(payload: PushPayload) {
  const uniqueUserIds = Array.from(new Set(payload.userIds.filter(Boolean)))

  if (uniqueUserIds.length) {
    await prisma.notification.createMany({
      data: uniqueUserIds.map((utilisateurId) => ({
        utilisateurId,
        title: payload.title,
        body: payload.body,
        type: payload.data?.type,
        tab: payload.data?.tab,
        groupeId: payload.data?.groupeId,
        eventId: payload.data?.eventId,
        etape: payload.data?.etape,
      })),
    })
  }

  try {
    const app = getFirebaseApp()
    if (!app || uniqueUserIds.length === 0) {
      return {
        sentCount: 0,
        failedCount: 0,
        skipped: true,
      }
    }

    const deviceTokens = await prisma.deviceToken.findMany({
      where: {
        utilisateurId: { in: uniqueUserIds },
      },
      select: {
        id: true,
        token: true,
      },
    })

    const tokens = Array.from(new Set(deviceTokens.map((item) => item.token).filter(Boolean)))
    if (!tokens.length) {
      return {
        sentCount: 0,
        failedCount: 0,
        skipped: true,
      }
    }

    const response = await admin.messaging(app).sendEachForMulticast({
      tokens,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: {
        role: payload.role,
        ...payload.data,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'high_importance_channel',
        },
      },
    })

    const invalidTokens = response.responses
      .map((item, index) => ({ item, token: tokens[index] }))
      .filter(({ item }) => !item.success)
      .filter(({ item }) =>
        item.error?.code === 'messaging/registration-token-not-registered' ||
        item.error?.code === 'messaging/invalid-registration-token',
      )
      .map(({ token }) => token)

    if (invalidTokens.length) {
      await prisma.deviceToken.deleteMany({
        where: {
          token: { in: invalidTokens },
        },
      })
    }

    return {
      sentCount: response.successCount,
      failedCount: response.failureCount,
      skipped: false,
    }
  } catch (error) {
    console.warn('Push delivery failed:', error)
    return {
      sentCount: 0,
      failedCount: 0,
      skipped: true,
    }
  }
}
