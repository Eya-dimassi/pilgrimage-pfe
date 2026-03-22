import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/famille/screens/famille_home_screen.dart';
import '../../features/guide/screens/guide_home_screen.dart';
import '../../features/pelerin/screens/pelerin_home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerRefreshNotifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: routerRefreshNotifier,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const PelerinHomeScreen(),
      ),
      GoRoute(
        path: '/guide-home',
        builder: (context, state) => const GuideHomeScreen(),
      ),
      GoRoute(
        path: '/famille-home',
        builder: (context, state) => const FamilleHomeScreen(),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;
      final isSplash = location == '/splash';
      final isLogin = location == '/login';
      final isForgotPassword = location == '/forgot-password';

      if (authState.isLoading) {
        return isSplash ? null : '/splash';
      }

      final session = authState.valueOrNull;
      if (session == null) {
        if (isLogin || isForgotPassword) {
          return null;
        }
        return '/login';
      }

      final targetPath = _pathForRole(session.user.role);
      if (targetPath == null) {
        return '/login';
      }

      if (isSplash || isLogin || isForgotPassword) {
        return targetPath;
      }

      if (location != targetPath) {
        return targetPath;
      }

      return null;
    },
  );
});

final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(this.ref) {
    ref.listen<AsyncValue<dynamic>>(authProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;
}

String? _pathForRole(String role) {
  switch (role) {
    case 'PELERIN':
      return '/home';
    case 'GUIDE':
      return '/guide-home';
    case 'FAMILLE':
      return '/famille-home';
    default:
      return null;
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0F1A),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      ),
    );
  }
}
