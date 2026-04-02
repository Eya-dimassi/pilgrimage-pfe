import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/brand_frame.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/edit_profile_screen.dart';
import '../features/auth/screens/family_signup_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/intro_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/famille/screens/famille_home_screen.dart';
import '../features/guide/screens/guide_home_screen.dart';
import '../features/pelerin/screens/pelerin_home_screen.dart';

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
        path: '/intro',
        builder: (context, state) => const IntroScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/family-signup',
        builder: (context, state) => const FamilySignupScreen(),
      ),
      GoRoute(
        path: '/profile-edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => PelerinHomeScreen(
          initialTabIndex: _tabIndexFromState(state),
        ),
      ),
      GoRoute(
        path: '/guide-home',
        builder: (context, state) => GuideHomeScreen(
          initialTabIndex: _tabIndexFromState(state),
        ),
      ),
      GoRoute(
        path: '/famille-home',
        builder: (context, state) => FamilleHomeScreen(
          initialTabIndex: _tabIndexFromState(state),
        ),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;
      final isSplash = location == '/splash';
      final isIntro = location == '/intro';
      final isLogin = location == '/login';
      final isForgotPassword = location == '/forgot-password';
      final isFamilySignup = location == '/family-signup';
      final isProfileEdit = location == '/profile-edit';

      if (authState.isLoading) {
        return isSplash ? null : '/splash';
      }

      final session = authState.valueOrNull;
      if (session == null) {
        if (isIntro || isLogin || isForgotPassword || isFamilySignup) {
          return null;
        }
        return '/intro';
      }

      final targetPath = _pathForRole(session.user.role);
      if (targetPath == null) {
        return '/login';
      }

      if (isSplash ||
          isIntro ||
          isLogin ||
          isForgotPassword ||
          isFamilySignup) {
        return targetPath;
      }

      if (!isProfileEdit && location != targetPath) {
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

int _tabIndexFromState(GoRouterState state) {
  final tab = state.uri.queryParameters['tab'];
  switch (tab) {
    case 'planning':
      return 1;
    case 'alerts':
      return 2;
    case 'profile':
      return 3;
    default:
      return 0;
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandBackdrop(
        child: SafeArea(
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.94, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  BrandWordmark(
                    caption: 'Votre centre pour le voyage sacre',
                    markSize: 64,
                    titleSize: 28,
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Pelerin, guide et famille dans un meme repere mobile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: 28),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
