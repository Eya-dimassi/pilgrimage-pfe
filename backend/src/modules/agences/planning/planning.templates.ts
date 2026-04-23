import type { EtapeVoyage } from "../../../../generated/prisma/enums"

export type PlanningEventType = 'PRIERE' | 'TRANSPORT' | 'VISITE' | 'REPAS' | 'RITE' | 'REPOS' | 'AUTRE'
export type TemplateLocationKey = 'MAKKAH' | 'MINA' | 'ARAFAT' | 'MUZDALIFAH' | 'MEDINA'
export type TemplateDayType = 'HAJJ_FIXED'

export type TemplateEvent = {
  type: PlanningEventType
  key: string
  titre: string
  description?: string
  lieu?: string | string[]
  etape?: EtapeVoyage // ← new
}

export type TemplateDay = {
  title: string
  locationKey: TemplateLocationKey
  events: TemplateEvent[]
  type?: TemplateDayType
  hijriDay?: number
}

function withSequentialTitle(day: TemplateDay, dayNumber: number): TemplateDay {
  const suffix = day.title.split(' - ').slice(1).join(' - ') || day.title
  return {
    ...day,
    title: `Jour ${dayNumber} - ${suffix}`,
    events: day.events.map((event) => ({ ...event })),
  }
}

const UMRAH_ARRIVAL_DAY: TemplateDay = {
  title: 'Jour 1 - Arrivee et installation',
  locationKey: 'MAKKAH',
  events: [
    { type: 'TRANSPORT', key: 'ARRIVEE_HOTEL', titre: "Arrivee et transfert a l'hotel", lieu: ['Aeroport', 'Hotel'] },
    { type: 'REPOS', key: 'INSTALLATION', titre: 'Installation et repos', lieu: 'Hotel' },
  ],
}

const UMRAH_RITES_DAY: TemplateDay = {
  title: 'Jour 2 - Omra principale',
  locationKey: 'MAKKAH',
  events: [
    { type: 'TRANSPORT', key: 'TRANSFERT_MAKKAH', titre: 'Transfert vers La Mecque', lieu: ['Miqat', 'La Mecque'] },
    { type: 'RITE', key: 'IHRAM',    titre: "Entree en etat d'ihram",    lieu: 'Miqat',           etape: 'IHRAM' },
    { type: 'RITE', key: 'TAWAF',    titre: 'Tawaf autour de la Kaaba',  lieu: 'Masjid Al Haram', etape: 'TAWAF_UMRAH' },
    { type: 'RITE', key: 'SAI',      titre: "Sa'i entre Safa et Marwa",  lieu: ['Safa', 'Marwa'], etape: 'SAI' },
    { type: 'RITE', key: 'TAHALLUL', titre: 'Tahallul - fin de la Omra', lieu: 'Masjid Al Haram', etape: 'TAHALLUL' },
  ],
}

const UMRAH_MAKKAH_WORSHIP_DAY: TemplateDay = {
  title: 'Jour X - Journee de priere a La Mecque',
  locationKey: 'MAKKAH',
  events: [
    { type: 'PRIERE', key: 'PRIERE_HARAM', titre: 'Prieres a Masjid Al Haram', lieu: 'Masjid Al Haram' },
    { type: 'RITE', key: 'TAWAF_NAFILA', titre: 'Tawaf surerogatoire', lieu: 'Masjid Al Haram' },
    { type: 'REPOS', key: 'REPOS_HOTEL', titre: 'Repos et temps libre', lieu: 'Hotel' },
  ],
}

const UMRAH_MAKKAH_ZIYARAT_DAY: TemplateDay = {
  title: 'Jour X - Ziyarat a La Mecque',
  locationKey: 'MAKKAH',
  events: [
    { type: 'VISITE', key: 'ZIYARAT_MAKKAH', titre: 'Ziyarat des lieux historiques', lieu: ['Jabal al-Nour', 'Jabal Thawr'] },
    { type: 'PRIERE', key: 'PRIERE_HARAM_ZIYARAT', titre: 'Prieres a Masjid Al Haram', lieu: 'Masjid Al Haram' },
    { type: 'REPOS', key: 'RETOUR_HOTEL', titre: 'Retour et repos', lieu: 'Hotel' },
  ],
}

const UMRAH_MEDINA_WORSHIP_DAY: TemplateDay = {
  title: 'Jour X - Journee de priere a Medina',
  locationKey: 'MEDINA',
  events: [
    { type: 'PRIERE', key: 'PRIERE_NABAWI', titre: 'Prieres a Al Masjid an-Nabawi', lieu: 'Al Masjid an-Nabawi' },
    { type: 'VISITE', key: 'RAWDAH', titre: 'Visite spirituelle et temps de recueillement', lieu: 'Al Masjid an-Nabawi' },
    { type: 'REPOS', key: 'REPOS_MEDINA', titre: 'Repos et temps libre', lieu: 'Hotel' },
  ],
}

const UMRAH_MEDINA_ZIYARAT_DAY: TemplateDay = {
  title: 'Jour X - Ziyarat a Medina',
  locationKey: 'MEDINA',
  events: [
    { type: 'VISITE', key: 'ZIYARAT_QUBA', titre: 'Visite de Quba et des lieux emblematiques', lieu: ['Masjid Quba', 'Uhud'] },
    { type: 'PRIERE', key: 'PRIERE_MEDINA', titre: 'Prieres a Al Masjid an-Nabawi', lieu: 'Al Masjid an-Nabawi' },
    { type: 'REPOS', key: 'RETOUR_MEDINA', titre: 'Retour et repos', lieu: 'Hotel' },
  ],
}

const UMRAH_DEPARTURE_DAY: TemplateDay = {
  title: 'Jour X - Depart',
  locationKey: 'MAKKAH',
  events: [
    { type: 'TRANSPORT', key: 'TRANSFERT_DEPART', titre: 'Transfert vers le depart', lieu: ['Hotel', 'Aeroport'] },
  ],
}

function cloneDay(day: TemplateDay): TemplateDay {
  return {
    ...day,
    events: day.events.map((event) => ({ ...event })),
  }
}

function buildUmrahMiddleDay(index: number, totalDays: number): TemplateDay {
  const beforeDeparture = totalDays - index - 1

  if (beforeDeparture >= 3) {
    return cloneDay(index % 2 === 0 ? UMRAH_MEDINA_WORSHIP_DAY : UMRAH_MEDINA_ZIYARAT_DAY)
  }

  return cloneDay(index % 2 === 0 ? UMRAH_MAKKAH_WORSHIP_DAY : UMRAH_MAKKAH_ZIYARAT_DAY)
}

export const HAJJ_TEMPLATE: TemplateDay[] = [
  {
    title: '8 Dhul Hijja - Yawm at-Tarwiyah',
    locationKey: 'MINA',
    type: 'HAJJ_FIXED',
    hijriDay: 8,
    events: [
      { type: 'RITE',      key: 'IHRAM',       titre: "Entree en etat d'ihram", lieu: 'Miqat / Hotel',  etape: 'IHRAM' },
      { type: 'TRANSPORT', key: 'GO_TO_MINA',  titre: 'Depart vers Mina',       lieu: 'Makkah -> Mina' },
      { type: 'RITE',      key: 'SEJOUR_MINA', titre: 'Sejour a Mina',           lieu: 'Mina',           etape: 'MINA' },
    ],
  },
  {
    title: '9 Dhul Hijja - Arafat',
    locationKey: 'ARAFAT',
    type: 'HAJJ_FIXED',
    hijriDay: 9,
    events: [
      { type: 'TRANSPORT', key: 'GO_TO_ARAFAT',      titre: 'Depart vers Arafat',                           lieu: 'Mina -> Arafat' },
      { type: 'RITE',      key: 'WUQUF',             titre: 'Wuquf - station a Arafat',                     lieu: 'Arafat',              etape: 'ARAFAT' },
      { type: 'PRIERE',    key: 'SALAT_ARAFAT',      titre: 'Priere et invocations a Arafat',               lieu: 'Arafat' },
      { type: 'TRANSPORT', key: 'GO_TO_MUZDALIFAH',  titre: 'Depart vers Muzdalifah',                       lieu: 'Arafat -> Muzdalifah' },
      { type: 'RITE',      key: 'SEJOUR_MUZDALIFAH', titre: 'Sejour a Muzdalifah et collecte des cailloux', lieu: 'Muzdalifah',          etape: 'MUZDALIFAH' },
    ],
  },
  {
    title: '10 Dhul Hijja - Yawm an-Nahr',
    locationKey: 'MINA',
    type: 'HAJJ_FIXED',
    hijriDay: 10,
    events: [
      { type: 'TRANSPORT', key: 'RETURN_TO_MINA',     titre: 'Retour vers Mina',            lieu: 'Muzdalifah -> Mina' },
      { type: 'RITE',      key: 'RAMI_AQABA',         titre: 'Rami Jamarat al-Aqaba',       lieu: 'Jamarat - Mina',  etape: 'RAMI_JAMARAT' },
      { type: 'RITE',      key: 'NAHR',               titre: 'Nahr - sacrifice',             lieu: 'Mina' },
      { type: 'RITE',      key: 'TAHALLUL_AWWAL',     titre: 'Tahallul awwal',               lieu: 'Mina',            etape: 'TAHALLUL' },
      { type: 'TRANSPORT', key: 'GO_TO_HARAM_IFADA',  titre: 'Depart vers Masjid Al Haram', lieu: 'Mina -> Makkah' },
      { type: 'RITE',      key: 'TAWAF_IFADA',        titre: 'Tawaf al-Ifada',               lieu: 'Masjid Al Haram', etape: 'TAWAF_AL_IFADA' },
      { type: 'RITE',      key: 'SAI_HAJJ',           titre: "Sa'i",                         lieu: 'Safa / Marwa',    etape: 'SAI' },
      { type: 'TRANSPORT', key: 'RETURN_TO_MINA_EID', titre: 'Retour vers Mina',             lieu: 'Makkah -> Mina' },
    ],
  },
  {
    title: '11 Dhul Hijja - Ayyam at-Tashriq 1',
    locationKey: 'MINA',
    type: 'HAJJ_FIXED',
    hijriDay: 11,
    events: [
      { type: 'RITE', key: 'RAMI_3_JAMARAT_1', titre: 'Rami des 3 Jamarat', lieu: 'Jamarat - Mina', etape: 'RAMI_JAMARAT' },
      { type: 'RITE', key: 'SEJOUR_MINA_1',    titre: 'Sejour a Mina',       lieu: 'Mina',           etape: 'MINA' },
    ],
  },
  {
    title: '12 Dhul Hijja - Ayyam at-Tashriq 2',
    locationKey: 'MINA',
    type: 'HAJJ_FIXED',
    hijriDay: 12,
    events: [
      { type: 'RITE', key: 'RAMI_3_JAMARAT_2', titre: 'Rami des 3 Jamarat', lieu: 'Jamarat - Mina', etape: 'RAMI_JAMARAT' },
      { type: 'RITE', key: 'NAFAR_AWWAL',       titre: 'Nafar awwal possible', lieu: 'Mina' },
    ],
  },
  {
    title: '13 Dhul Hijja - Ayyam at-Tashriq 3',
    locationKey: 'MINA',
    type: 'HAJJ_FIXED',
    hijriDay: 13,
    events: [
      { type: 'RITE',      key: 'RAMI_3_JAMARAT_3', titre: 'Rami des 3 Jamarat',           lieu: 'Jamarat - Mina',  etape: 'RAMI_JAMARAT' },
      { type: 'TRANSPORT', key: 'RETURN_TO_MAKKAH',  titre: 'Retour vers Makkah',            lieu: 'Mina -> Makkah' },
      { type: 'RITE',      key: 'TAWAF_WADA',        titre: 'Tawaf al-Wada avant le depart', lieu: 'Masjid Al Haram', etape: 'TAWAF_AL_WADA' },
    ],
  },
]

export function buildUmrahPlan(totalDays: number) {
  if (totalDays <= 0) return []
  if (totalDays === 1) {
    return [withSequentialTitle(cloneDay(UMRAH_RITES_DAY), 1)]
  }

  if (totalDays === 2) {
    return [
      withSequentialTitle(cloneDay(UMRAH_ARRIVAL_DAY), 1),
      withSequentialTitle(cloneDay(UMRAH_DEPARTURE_DAY), 2),
    ]
  }

  const ritesDayNumber = totalDays <= 4 ? 2 : 3
  const days: TemplateDay[] = []

  for (let dayNumber = 1; dayNumber <= totalDays; dayNumber += 1) {
    if (dayNumber === 1) {
      days.push(withSequentialTitle(cloneDay(UMRAH_ARRIVAL_DAY), dayNumber))
      continue
    }

    if (dayNumber === totalDays) {
      days.push(withSequentialTitle(cloneDay(UMRAH_DEPARTURE_DAY), dayNumber))
      continue
    }

    if (dayNumber === ritesDayNumber) {
      days.push(withSequentialTitle(cloneDay(UMRAH_RITES_DAY), dayNumber))
      continue
    }

    days.push(withSequentialTitle(buildUmrahMiddleDay(dayNumber, totalDays), dayNumber))
  }

  return days
}

export function buildHajjPlan() {
  const fixedDays = HAJJ_TEMPLATE
    .filter((day) => day.type === 'HAJJ_FIXED')
    .sort((a, b) => (a.hijriDay ?? 0) - (b.hijriDay ?? 0))
  return fixedDays.map((day) => ({
    ...day,
    events: day.events.map((event) => ({ ...event })),
  }))
}
