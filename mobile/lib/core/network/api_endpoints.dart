class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
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
  static const String mobileNotifications = '/mobile/notifications';
  static const String mobileNotificationToken =
      '/mobile/notifications/device-token';

  static String mobilePlanningGroup(String groupeId) =>
      '/mobile/planning/groupes/$groupeId';

  static String mobileNotificationRead(String notificationId) =>
      '/mobile/notifications/$notificationId/read';

  static const String mobileNotificationsReadAll =
      '/mobile/notifications/read-all';
}
