import prisma from '../../../config/prisma'
import { SupportedLanguage, translateBatch } from '../../../utils/translation.provider'

type DeviceTokenPayload = {
  token: string
  platform: string
}

export async function getMyNotifications(userId: string, language: SupportedLanguage = 'fr') {
  const notifications = await prisma.notification.findMany({
    where: { utilisateurId: userId },
    orderBy: { createdAt: 'desc' },
    take: 50,
    select: {
      id: true,
      title: true,
      body: true,
      type: true,
      tab: true,
      groupeId: true,
      eventId: true,
      etape: true,
      isRead: true,
      readAt: true,
      createdAt: true,
    },
  })

  const unreadCount = await prisma.notification.count({
    where: {
      utilisateurId: userId,
      isRead: false,
    },
  })

  const items = language === 'fr'
    ? notifications
    : await (async () => {
        const fields = notifications.flatMap((notification) => [
          {
            key: `notification:${notification.id}:title`,
            text: notification.title,
          },
          {
            key: `notification:${notification.id}:body`,
            text: notification.body,
          },
        ])

        const translatedFields = await translateBatch(fields, language)
        const translatedByKey = new Map(
          translatedFields.map((item) => [item.key, item.text]),
        )

        return notifications.map((notification) => ({
          ...notification,
          title:
            translatedByKey.get(`notification:${notification.id}:title`) ??
            notification.title,
          body:
            translatedByKey.get(`notification:${notification.id}:body`) ??
            notification.body,
        }))
      })()

  return {
    unreadCount,
    items,
  }
}

export async function registerMyDeviceToken(userId: string, data: DeviceTokenPayload) {
  const token = String(data.token ?? '').trim()
  const platform = String(data.platform ?? '').trim().toUpperCase()

  if (!token) {
    throw new Error('Le token appareil est requis')
  }

  if (!platform) {
    throw new Error('La plateforme appareil est requise')
  }

  return prisma.deviceToken.upsert({
    where: { token },
    update: {
      utilisateurId: userId,
      platform,
      lastSeenAt: new Date(),
    },
    create: {
      utilisateurId: userId,
      token,
      platform,
      lastSeenAt: new Date(),
    },
    select: {
      id: true,
      token: true,
      platform: true,
      lastSeenAt: true,
    },
  })
}

export async function unregisterMyDeviceToken(userId: string, token: string) {
  const normalizedToken = String(token ?? '').trim()

  if (!normalizedToken) {
    throw new Error('Le token appareil est requis')
  }

  const result = await prisma.deviceToken.deleteMany({
    where: {
      utilisateurId: userId,
      token: normalizedToken,
    },
  })

  return {
    deleted: result.count,
  }
}

export async function markMyNotificationAsRead(userId: string, notificationId: string) {
  const notification = await prisma.notification.findFirst({
    where: {
      id: notificationId,
      utilisateurId: userId,
    },
    select: { id: true, isRead: true },
  })

  if (!notification) {
    throw new Error('Notification introuvable')
  }

  if (notification.isRead) {
    return { id: notification.id, isRead: true }
  }

  const updated = await prisma.notification.update({
    where: { id: notification.id },
    data: {
      isRead: true,
      readAt: new Date(),
    },
    select: {
      id: true,
      isRead: true,
      readAt: true,
    },
  })

  return updated
}

export async function markAllMyNotificationsAsRead(userId: string) {
  const result = await prisma.notification.updateMany({
    where: {
      utilisateurId: userId,
      isRead: false,
    },
    data: {
      isRead: true,
      readAt: new Date(),
    },
  })

  return {
    updated: result.count,
  }
}
export async function deleteMyNotification(userId: string, notificationId: string) {
  const notification = await prisma.notification.findFirst({
    where: { id: notificationId, utilisateurId: userId },
    select: { id: true },
  })

  if (!notification) throw new Error('Notification introuvable')

  await prisma.notification.delete({ where: { id: notification.id } })
  return { deleted: 1 }
}
