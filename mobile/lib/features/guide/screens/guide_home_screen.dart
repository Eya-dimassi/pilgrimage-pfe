import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/adhan_panel.dart';
import '../../../core/widgets/role_home_template.dart';
import '../../../core/widgets/role_profile_template.dart';
import '../../../core/widgets/role_shell.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/screens/mobile_alerts_screen.dart';
import '../../planning/screens/role_planning_pages.dart';

class GuideHomeScreen extends ConsumerWidget {
  const GuideHomeScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull?.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return RoleShell(
      initialIndex: initialTabIndex,
      homeChild: const RoleHomeTemplate(
        title: 'Le terrain, coordonne depuis le mobile.',
        subtitle:
            'Retrouvez votre groupe, la localisation live et les actions prioritaires dans une interface plus proche du web.',
        roleLabel: 'Guide · Mobile',
        accentColor: Color(0xFF67C9B7),
        icon: Icons.map_outlined,
        headerExtra: AdhanPanel(
          accentColor: Color(0xFF67C9B7),
          roleToneLabel:
              'Un rappel spirituel discret pour guider avec calme et presence.',
        ),
        stats: [
          HomeStatData(value: 'GPS', label: 'suivi live'),
          HomeStatData(value: 'Groupe', label: 'coordination'),
          HomeStatData(value: 'SOS', label: 'actions rapides'),
        ],
        cards: [
          InfoCardData(
            title: 'Vue complete',
            description:
                'Gardez le fil de tout le voyage pour anticiper les deplacements et briefer votre groupe.',
            icon: Icons.route_outlined,
            tag: 'Lecture',
          ),
          InfoCardData(
            title: 'Journee actuelle',
            description:
                'Retrouvez les rendez-vous du jour dans l ordre, sans action d edition depuis le mobile.',
            icon: Icons.calendar_month_outlined,
            tag: 'Planning',
            toneColor: Color(0xFF6B7FD7),
          ),
          InfoCardData(
            title: 'Coordination',
            description:
                'Le mobile vous aide a informer le groupe, pas a modifier le planning de l agence.',
            icon: Icons.groups_outlined,
            tag: 'Groupe',
            toneColor: Color(0xFFB8962E),
          ),
        ],
      ),
      planningChild: const GuidePlanningPage(),
      alertsChild: const MobileAlertsScreen(),
      profileChild: RoleProfileTemplate(
        user: user,
        roleLabel: 'Guide',
        accentColor: const Color(0xFF67C9B7),
        onEdit: () => context.push('/profile-edit'),
        onLogout: () async {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) {
            context.go('/login');
          }
        },
      ),
    );
  }
}
