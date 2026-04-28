import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationNavigationService {
  NotificationNavigationService._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static String? _pendingLocation;

  static void openFromPayload(Map<String, dynamic> payload, {required String role}) {
    final location = _resolveLocation(payload, role);
    if (location == null) return;

    final context = navigatorKey.currentContext;
    if (context != null) {
      GoRouter.of(context).go(location);
      return;
    }

    _pendingLocation = location;
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 100), flushPending),
    );
  }

  static Future<void> flushPending() async {
    final location = _pendingLocation;
    final context = navigatorKey.currentContext;
    if (location == null || context == null) return;

    _pendingLocation = null;
    GoRouter.of(context).go(location);
  }

  static String? _resolveLocation(Map<String, dynamic> payload, String role) {
    final directRoute = payload['route']?.toString().trim();
    if (directRoute != null && directRoute.isNotEmpty) {
      return directRoute;
    }

    final tab = payload['tab']?.toString().trim();
    if (tab != null && tab.isNotEmpty) {
      return '${_basePathForRole(role)}?tab=$tab';
    }

    final type = payload['type']?.toString().trim();
    switch (type) {
      case 'planning_update':
      case 'upcoming_rendezvous':
      case 'planning':
        return '${_basePathForRole(role)}?tab=planning';
      case 'notification':
      case 'alert':
      default:
        return '${_basePathForRole(role)}?tab=alerts';
    }
  }

  static String _basePathForRole(String role) {
    switch (role) {
      case 'GUIDE':
        return '/guide-home';
      case 'FAMILLE':
        return '/famille-home';
      case 'PELERIN':
      default:
        return '/home';
    }
  }
}
