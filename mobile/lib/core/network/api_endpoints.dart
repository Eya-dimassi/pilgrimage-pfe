class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.18:3000',
  );

  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String familySignup = '/auth/family-signup';
  static const String familyLinks = '/auth/family-links';
  static const String me = '/auth/me';
  static const String updateMe = '/auth/me';
  static const String mobilePlanningGroups = '/mobile/planning/groupes';
  static const String mobilePlanningGroupsHistory =
      '/mobile/planning/groupes/historique';
  static const String mobileNotifications = '/mobile/notifications';
  static const String mobileNotificationToken =
      '/mobile/notifications/device-token';
  static const String mobileSos = '/mobile/sos';
  static const String mobileSosMe = '/mobile/sos/me';
  static const String mobileGuideSos = '/mobile/guide/sos';

  static String mobilePlanningGroup(String groupeId) =>
      '/mobile/planning/groupes/$groupeId';

  static String mobilePlanningGroupPelerins(String groupeId) =>
      '/mobile/planning/groupes/$groupeId/pelerins';

  static String mobilePlanningValidateEvent(String groupeId, String eventId) =>
      '/mobile/planning/groupes/$groupeId/evenements/$eventId/valider';

  static String mobileNotificationRead(String notificationId) =>
      '/mobile/notifications/$notificationId/read';

  static const String mobileNotificationsReadAll =
      '/mobile/notifications/read-all';

  static String mobileGuideSosResolve(String sosId) =>
      '/mobile/guide/sos/$sosId/resolve';

  static String creerAppelPresence() => '/guide/presence/appels';
  
  // Récupérer un appel de présence
  static String getAppelPresence(String appelId) => '/guide/presence/appels/$appelId';
  
  // Marquer une présence individuelle
  static String marquerPresence(String confirmationId) => 
      '/guide/presence/confirmations/$confirmationId';
  
  // Marquer plusieurs présences en masse
  static String marquerPresenceBulk(String appelId) => 
      '/guide/presence/appels/$appelId/bulk';
  
  // Clôturer un appel
  static String cloturerAppel(String appelId) => 
      '/guide/presence/appels/$appelId/cloturer';
  
  // Historique des appels d'un groupe
  static String getHistoriqueAppels(String groupeId) => 
      '/guide/presence/groupes/$groupeId/historique';
  
  // Stats d'un pèlerin
  static String getStatsPelerin(String pelerinId) => 
      '/guide/presence/pelerins/$pelerinId/stats';

  static const String mobilePelerinPresenceActive = '/mobile/presence/active';

  static String mobilePelerinPresenceAppel(String appelId) =>
      '/mobile/presence/appels/$appelId';

  static String mobilePelerinPresenceConfirmation(String confirmationId) =>
      '/mobile/presence/confirmations/$confirmationId';
}
