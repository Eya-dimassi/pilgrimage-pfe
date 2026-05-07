import prisma from '../../../../config/prisma'
import { sendPushToUsers } from '../../../../utils/push-notifications.utils'

export class PresenceService {
  /**
   * Creer un appel de presence pour un groupe
   */
  static async creerAppelPresence(guideId: string, groupeId: string) {
    const assignment = await prisma.groupeGuide.findFirst({
      where: {
        guideId,
        groupeId,
        actif: true,
      },
    })

    if (!assignment) {
      throw new Error('Vous n\'etes pas assigne a ce groupe')
    }

    const appelEnCours = await prisma.appelPresence.findFirst({
      where: {
        groupeId,
        statut: 'EN_COURS',
      },
      include: {
        confirmations: {
          include: {
            pelerin: {
              include: {
                utilisateur: {
                  select: {
                    nom: true,
                    prenom: true,
                  },
                },
              },
            },
          },
        },
      },
      orderBy: {
        date: 'desc',
      },
    })

    if (appelEnCours) {
      return {
        message: 'Un appel de presence est deja en cours',
        appel: appelEnCours,
        totalPelerins: appelEnCours.confirmations.length,
        isExisting: true,
      }
    }

    const membres = await prisma.groupePelerin.findMany({
      where: {
        groupeId,
        actif: true,
      },
      include: {
        pelerin: {
          include: {
            utilisateur: {
              select: {
                id: true,
                nom: true,
                prenom: true,
              },
            },
          },
        },
      },
    })

    if (membres.length === 0) {
      throw new Error('Aucun pelerin dans ce groupe')
    }

    const appel = await prisma.$transaction(async (tx) => {
      const nouvelAppel = await tx.appelPresence.create({
        data: {
          groupeId,
          guideId,
          statut: 'EN_COURS',
        },
      })

      const confirmations = await Promise.all(
        membres.map((membre) =>
          tx.confirmationPresence.create({
            data: {
              appelPresenceId: nouvelAppel.id,
              pelerinId: membre.pelerinId,
              statut: 'EN_ATTENTE',
            },
            include: {
              pelerin: {
                include: {
                  utilisateur: {
                    select: {
                      nom: true,
                      prenom: true,
                    },
                  },
                },
              },
            },
          }),
        ),
      )

      return {
        ...nouvelAppel,
        confirmations,
      }
    })

    const pelerinUserIds = Array.from(
      new Set(
        membres
          .map((membre) => membre.pelerin.utilisateur.id)
          .filter(Boolean),
      ),
    )

    if (pelerinUserIds.length > 0) {
      await sendPushToUsers({
        userIds: pelerinUserIds,
        role: 'PELERIN',
        title: 'Appel de presence en cours',
        body: 'Votre guide vous demande de confirmer votre presence.',
        data: {
          type: 'presence_call',
          tab: 'alerts',
          groupeId,
          eventId: appel.id,
          etape: 'PRESENCE',
        },
      })
    }

    return {
      message: 'Appel de presence cree',
      appel,
      totalPelerins: membres.length,
      isExisting: false,
    }
  }

  /**
   * Recuperer un appel de presence
   */
  static async getAppelPresence(guideId: string, appelId: string) {
    const appel = await prisma.appelPresence.findFirst({
      where: {
        id: appelId,
        guideId,
      },
      include: {
        groupe: {
          select: {
            id: true,
            nom: true,
          },
        },
        confirmations: {
          include: {
            pelerin: {
              include: {
                utilisateur: {
                  select: {
                    nom: true,
                    prenom: true,
                  },
                },
              },
            },
          },
          orderBy: [
            { statut: 'asc' },
            { pelerin: { utilisateur: { nom: 'asc' } } },
          ],
        },
      },
    })

    if (!appel) {
      throw new Error('Appel de presence introuvable')
    }

    const stats = {
      total: appel.confirmations.length,
      presents: appel.confirmations.filter((c) => c.statut === 'PRESENT').length,
      absents: appel.confirmations.filter((c) => c.statut === 'ABSENT').length,
      excuses: appel.confirmations.filter((c) => c.statut === 'EXCUSE').length,
      enAttente: appel.confirmations.filter((c) => c.statut === 'EN_ATTENTE').length,
    }

    return {
      appel,
      stats,
    }
  }

  /**
   * Marquer la presence d'un pelerin
   */
  static async marquerPresence(
    guideId: string,
    confirmationId: string,
    data: {
      statut: 'PRESENT' | 'ABSENT' | 'EXCUSE'
      mode?: 'AUTOMATIQUE' | 'MANUEL'
      note?: string
    },
  ) {
    const confirmation = await prisma.confirmationPresence.findFirst({
      where: {
        id: confirmationId,
        appelPresence: {
          guideId,
          statut: 'EN_COURS',
        },
      },
      include: {
        pelerin: {
          include: {
            utilisateur: {
              select: {
                nom: true,
                prenom: true,
              },
            },
          },
        },
      },
    })

    if (!confirmation) {
      throw new Error('Confirmation introuvable ou appel cloture')
    }

    const updated = await prisma.confirmationPresence.update({
      where: { id: confirmationId },
      data: {
        statut: data.statut,
        confirmeMode: data.mode || 'MANUEL',
        confirmeAt: new Date(),
        note: data.note?.trim() || null,
      },
      include: {
        pelerin: {
          include: {
            utilisateur: {
              select: {
                nom: true,
                prenom: true,
              },
            },
          },
        },
      },
    })

    return {
      message: 'Presence mise a jour',
      confirmation: updated,
    }
  }

  /**
   * Marquer plusieurs presences en masse
   */
  static async marquerPresenceBulk(
    guideId: string,
    appelId: string,
    data: {
      confirmations: Array<{
        confirmationId: string
        statut: 'PRESENT' | 'ABSENT' | 'EXCUSE'
        note?: string
      }>
    },
  ) {
    const appel = await prisma.appelPresence.findFirst({
      where: {
        id: appelId,
        guideId,
        statut: 'EN_COURS',
      },
    })

    if (!appel) {
      throw new Error('Appel introuvable ou deja cloture')
    }

    const updates = await prisma.$transaction(
      data.confirmations.map((item) =>
        prisma.confirmationPresence.updateMany({
          where: {
            id: item.confirmationId,
            appelPresenceId: appelId,
          },
          data: {
            statut: item.statut,
            confirmeMode: 'MANUEL',
            confirmeAt: new Date(),
            note: item.note?.trim() || null,
          },
        }),
      ),
    )

    const totalUpdated = updates.reduce((sum, u) => sum + u.count, 0)

    return {
      message: `${totalUpdated} presence(s) mise(s) a jour`,
      updated: totalUpdated,
    }
  }

  /**
   * Cloturer un appel de presence
   */
  static async cloturerAppel(guideId: string, appelId: string) {
    const appel = await prisma.appelPresence.findFirst({
      where: {
        id: appelId,
        guideId,
        statut: 'EN_COURS',
      },
    })

    if (!appel) {
      throw new Error('Appel introuvable ou deja cloture')
    }

    await prisma.confirmationPresence.updateMany({
      where: {
        appelPresenceId: appelId,
        statut: 'EN_ATTENTE',
      },
      data: {
        statut: 'ABSENT',
        confirmeMode: 'AUTOMATIQUE',
        confirmeAt: new Date(),
      },
    })

    const updated = await prisma.appelPresence.update({
      where: { id: appelId },
      data: {
        statut: 'CLOTURE',
        clotureAt: new Date(),
      },
    })

    return {
      message: 'Appel de presence cloture',
      appel: updated,
    }
  }

  /**
   * Recuperer l'historique des appels d'un groupe
   */
  static async getHistoriqueAppels(guideId: string, groupeId: string) {
    const assignment = await prisma.groupeGuide.findFirst({
      where: {
        guideId,
        groupeId,
        actif: true,
      },
    })

    if (!assignment) {
      throw new Error('Acces refuse a ce groupe')
    }

    const appels = await prisma.appelPresence.findMany({
      where: { groupeId },
      include: {
        guide: {
          include: {
            utilisateur: {
              select: {
                nom: true,
                prenom: true,
              },
            },
          },
        },
        confirmations: {
          select: {
            id: true,
            statut: true,
          },
        },
      },
      orderBy: { date: 'desc' },
    })

    const appelsAvecStats = appels.map((entry) => {
      const stats = {
        total: entry.confirmations.length,
        presents: entry.confirmations.filter((c) => c.statut === 'PRESENT').length,
        absents: entry.confirmations.filter((c) => c.statut === 'ABSENT').length,
        excuses: entry.confirmations.filter((c) => c.statut === 'EXCUSE').length,
      }

      return {
        id: entry.id,
        date: entry.date,
        statut: entry.statut,
        guide: `${entry.guide.utilisateur.prenom} ${entry.guide.utilisateur.nom}`,
        stats,
      }
    })

    return appelsAvecStats
  }

  /**
   * Statistiques de presence d'un pelerin
   */
  static async getStatsPelerin(guideId: string, pelerinId: string) {
    const confirmations = await prisma.confirmationPresence.findMany({
      where: {
        pelerinId,
        appelPresence: {
          guide: {
            id: guideId,
          },
        },
      },
      include: {
        appelPresence: {
          select: {
            date: true,
            statut: true,
          },
        },
      },
      orderBy: {
        appelPresence: {
          date: 'desc',
        },
      },
    })

    const stats = {
      total: confirmations.length,
      presents: confirmations.filter((c) => c.statut === 'PRESENT').length,
      absents: confirmations.filter((c) => c.statut === 'ABSENT').length,
      excuses: confirmations.filter((c) => c.statut === 'EXCUSE').length,
      tauxPresence:
        confirmations.length > 0
          ? Math.round(
              (confirmations.filter((c) => c.statut === 'PRESENT').length /
                confirmations.length) *
                100,
            )
          : 0,
    }

    return {
      stats,
      historique: confirmations,
    }
  }
}
