export const heroSlides = [
  {
    src: 'https://images.unsplash.com/photo-1591604129939-f1efa4d9f7fa?w=1200&q=80',
    alt: 'Masjid Al-Haram - La Mecque',
    caption: 'Masjid Al-Haram - La Mecque',
  },
  {
    src: 'https://images.unsplash.com/photo-1564769625905-50e93615e769?w=1200&q=80',
    alt: 'La Kaaba',
    caption: 'La Kaaba - Coeur du Hajj',
  },
  {
    src: 'https://images.unsplash.com/photo-1563492065599-3520f775eeed?w=1200&q=80',
    alt: 'Masjid An-Nabawi - Medine',
    caption: 'Masjid An-Nabawi - Medine',
  },
  {
    src: 'https://images.unsplash.com/photo-1590108589108-3600131de843?q=80&w=1200',
    alt: 'Pelerins en priere',
    caption: 'Hajj - Rassemblement mondial',
  },
]

export const heroProofItems = ['Agence', 'Guide', 'Famille', 'Mobile']

export const whyStats = [
  { value: '3', suffix: '', label: 'espaces relies' },
  { value: '1', suffix: '', label: 'planning partage' },
  { value: '24h', suffix: '', label: 'visibilite terrain' },
]

export const whyCards = [
  {
    icon: 'building',
    title: 'Tout le voyage au meme endroit',
    text: "Groupes, guides, pelerins, planning et suivi quotidien reunis dans une seule plateforme simple a piloter.",
  },
  {
    icon: 'calendar',
    title: 'Coordination plus claire',
    text: "L'agence organise, le guide execute, le pelerin suit sa prochaine etape et la famille garde une vision rassurante du parcours.",
  },
  {
    icon: 'alert',
    title: 'Alertes et presence plus rapides',
    text: "Notifications, appels de presence et signaux d'urgence aident vos equipes a reagir plus vite quand quelque chose change.",
  },
]

export const agenceFeatureCards = [
  {
    tag: 'Gestion',
    title: 'Creer et organiser vos groupes',
    text: "Ajoutez des pelerins, rattachez un guide et preparez l'organisation du voyage dans le meme espace.",
    ghost: 'G',
    mockRows: [
      { type: 'status', label: 'Groupe G-07 - Alger', value: '48 pelerins', dot: 'go' },
      { type: 'status', label: 'Groupe G-08 - Oran', value: '36 pelerins', dot: 'go' },
      { type: 'status', label: 'Groupe G-09 - Constantine', value: '52 pelerins', dot: 'go' },
    ],
  },
  {
    tag: 'Affectation',
    title: 'Affecter le bon guide',
    text: "Assignez chaque guide a ses groupes et gardez une vue claire sur les disponibilites et responsabilites.",
    ghost: 'A',
    mockRows: [
      { type: 'iconTag', icon: 'user', iconColor: '#6B7FD7', label: 'Ahmed Benali', value: 'Disponible', tone: 'blue' },
      { type: 'iconTag', icon: 'user', iconColor: '#6B7FD7', label: 'Sara Mekki', value: 'Assignee', tone: 'gold' },
      { type: 'iconTag', icon: 'user', iconColor: '#6B7FD7', label: 'Karim Boudali', value: 'Actif', tone: 'green' },
    ],
  },
  {
    tag: 'Communication',
    title: 'Envoyer des alertes utiles',
    text: "Diffusez un rappel, une mise a jour de planning ou une alerte importante au bon groupe en quelques secondes.",
    ghost: 'N',
    mockRows: [
      { type: 'detailTag', icon: 'alert', iconColor: '#2D7A4A', label: 'Rappel - Tawaf 14h00', detail: 'Groupe G-07', value: 'Envoye', tone: 'green' },
      { type: 'detailTag', icon: 'alert', iconColor: '#B8962E', label: 'Point de rendez-vous', detail: 'Tous les guides', value: 'Planifie', tone: 'gold' },
    ],
  },
  {
    tag: 'Suivi',
    title: "Suivre l'activite des groupes",
    text: "Consultez rapidement les groupes actifs, les pelerins suivis et les signaux qui demandent votre attention.",
    ghost: 'S',
    stats: [
      { value: '1 284', label: 'Pelerins actifs' },
      { value: '24', label: 'Groupes' },
      { value: '12', label: 'Guides actifs' },
    ],
  },
]

export const guideFeatureCards = [
  {
    tag: 'Mobile - Guides',
    title: 'Mes groupes et mes pelerins',
    text: "Retrouvez vos groupes, ouvrez la liste des pelerins et accedez vite aux informations utiles depuis l'application.",
    ghost: 'M',
    mockRows: [
      { label: 'Fatima K.', value: 'Presente', tone: 'green', dot: 'gn' },
      { label: 'Mohamed B.', value: 'En route', tone: 'gold', dot: 'go' },
      { label: 'Amina R.', value: 'Chambre 412', tone: 'blue', dot: 'bl' },
    ],
  },
  {
    tag: 'Planning',
    title: 'Suivre les etapes du groupe',
    text: "Visualisez l'etape actuelle, la prochaine action et les evenements du jour pour mieux guider le groupe.",
    ghost: 'P',
    mockRows: [
      { type: 'detailTag', icon: 'calendar', iconColor: '#B8962E', label: 'Depart vers Mina', detail: 'Dans 25 minutes', value: 'A venir', tone: 'gold' },
    ],
  },
  {
    tag: 'Urgence',
    title: 'Presence et situations urgentes',
    text: "Lancez un appel de presence, recevez les confirmations et signalez rapidement un incident si necessaire.",
    ghost: 'U',
    mockRows: [
      { icon: 'users', iconColor: '#2D7A4A', label: 'Appel de presence' },
      { icon: 'alert', iconColor: '#e53e3e', label: 'Signaler une urgence' },
    ],
  },
  {
    tag: 'Echanges',
    title: 'Alertes et echanges',
    text: "Recevez les mises a jour utiles et restez aligne avec l'agence et les pelerins pendant le voyage.",
    ghost: 'C',
    mockRows: [
      { type: 'detailValue', icon: 'mail', iconColor: '#6A6560', label: 'Agence Sacred Journey Hub', detail: 'Rendez-vous a 14h a la porte 1', value: '09:00' },
      { type: 'detailValue', icon: 'mail', iconColor: '#6A6560', label: 'Groupe G-07', detail: 'Tout le monde est arrive', value: '08:42' },
    ],
  },
]

export const homepageFaqs = [
  {
    q: 'Combien coute la plateforme ?',
    a: "L'acces anticipe est gratuit. Les tarifs seront communiques lors du lancement, avec une periode d'essai offerte aux agences inscrites.",
  },
  {
    q: "L'application mobile est-elle incluse ?",
    a: "Oui. L'espace web agence et l'application mobile font partie de la meme solution.",
  },
  {
    q: 'Combien de pelerins puis-je gerer ?',
    a: "La plateforme convient aussi bien a une petite organisation qu'a une agence qui suit plusieurs groupes en parallele.",
  },
  {
    q: 'La plateforme est-elle disponible en arabe ?',
    a: "L'experience multilingue fait partie de la direction produit, avec une interface pensee pour des utilisateurs aux profils differents.",
  },
  {
    q: 'Que se passe-t-il apres ma demande ?',
    a: "Notre equipe vous recontacte pour comprendre votre organisation, configurer votre espace et vous accompagner dans les premieres etapes.",
  },
]
