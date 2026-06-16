import prisma from '../../../../config/prisma'
import { sendPushToUsers } from '../../../../utils/push-notifications.utils'

const AUTO_CLOSE_DELAY_MS = 60 * 60 * 1000
const ENDING_WARNING_BEFORE_MS = 10 * 60 * 1000
const WATCH_INTERVAL_MS = 60 * 1000
const NOTIFICATION_TYPE = 'presence_call_ending'

let interval: NodeJS.Timeout | null = null
let isRunning = false

export async function notifyEndingPresenceCalls() {
  if (isRunning) return
  isRunning = true

  try {
    const now = Date.now()
    const warningThreshold = new Date(
      now - (AUTO_CLOSE_DELAY_MS - ENDING_WARNING_BEFORE_MS),
    )

    const appels = await prisma.appelPresence.findMany({
      where: {
        statut: 'EN_COURS',
        date: {
          lte: warningThreshold,
        },
        confirmations: {
          some: {
            statut: 'EN_ATTENTE',
          },
        },
      },
      select: {
        id: true,
        groupeId: true,
        guide: {
          select: {
            utilisateurId: true,
          },
        },
        _count: {
          select: {
            confirmations: {
              where: {
                statut: 'EN_ATTENTE',
              },
            },
          },
        },
      },
    })

    for (const appel of appels) {
      const pendingCount = appel._count.confirmations
      if (pendingCount <= 0) continue

      const existingNotification = await prisma.notification.findFirst({
        where: {
          utilisateurId: appel.guide.utilisateurId,
          type: NOTIFICATION_TYPE,
          eventId: appel.id,
        },
        select: {
          id: true,
        },
      })

      if (existingNotification) continue

      await sendPushToUsers({
        userIds: [appel.guide.utilisateurId],
        role: 'GUIDE',
        title: 'Appel presque termine',
        body: `${pendingCount} pelerin(s) encore en attente.`,
        data: {
          type: NOTIFICATION_TYPE,
          tab: 'alerts',
          groupeId: appel.groupeId,
          eventId: appel.id,
          etape: 'PRESENCE',
        },
      })
    }
  } catch (error) {
    console.warn('Presence ending watcher failed:', error)
  } finally {
    isRunning = false
  }
}

export function startPresenceEndingWatcher() {
  if (interval) return

  void notifyEndingPresenceCalls()
  interval = setInterval(() => {
    void notifyEndingPresenceCalls()
  }, WATCH_INTERVAL_MS)
}
