import prisma from '../../../config/prisma'

type DeviceTokenPayload = {
  token: string
  platform: string
}

export async function getMyNotifications(userId: string) {
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

  return {
    unreadCount,
    items: notifications,
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
