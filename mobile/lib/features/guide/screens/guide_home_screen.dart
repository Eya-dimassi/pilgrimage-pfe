import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/role_journey_home_content.dart';
import '../../../core/widgets/role_profile_template.dart';
import '../../../core/widgets/role_shell.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/screens/mobile_chat_screen.dart';
import '../../planning/domain/mobile_planning_models.dart';
import '../../planning/providers/mobile_planning_provider.dart';
import '../../notifications/screens/mobile_alerts_screen.dart';
import '../../planning/screens/role_planning_pages.dart';
import '../widgets/guide_groupes_sheet.dart';
import '../widgets/guide_groupe_pelerins_sheet.dart';

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

    final fullName = user.fullName.trim();
    final firstName = user.prenom.trim().isNotEmpty
        ? user.prenom.trim()
        : (fullName.isNotEmpty ? fullName.split(' ').first : user.email);
    final planningGroupsAsync = ref.watch(mobilePlanningGroupsProvider);
    final guideGroups = planningGroupsAsync.valueOrNull ?? const <MobilePlanningGroup>[];

    void openGroupesSheet() {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const GuideGroupesSheet(),
      );
    }

    void openPelerinsSheet() {
      if (guideGroups.isEmpty) {
        openGroupesSheet();
        return;
      }

      if (guideGroups.length > 1) {
        openGroupesSheet();
        return;
      }

      final targetGroup = guideGroups.first;

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => GuideGroupePelerinsSheet(
          groupeId: targetGroup.id,
          groupeNom: targetGroup.nom,
        ),
      );
    }

    return RoleShell(
      key: ValueKey('guide-shell-${user.id}'),
      initialIndex: initialTabIndex,
      accountActions: [
        RoleShellAccountAction(
          label: 'Liste des groupes',
          icon: Icons.history_rounded,
          toneColor: const Color(0xFF67C9B7),
          onTap: (_) async => openGroupesSheet(),
        ),
        RoleShellAccountAction(
          label: 'Liste des pelerins',
          icon: Icons.groups_outlined,
          toneColor: const Color(0xFF2D7A4A),
          onTap: (_) async => openPelerinsSheet(),
        ),
        RoleShellAccountAction(
          label: 'Deconnexion',
          icon: Icons.logout_rounded,
          toneColor: AppColors.red,
          onTap: (context) async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) {
              context.go('/login');
            }
          },
        ),
      ],
      homeChild: RoleJourneyHomeContent(
        firstName: firstName,
        groupeNom: user.groupeNom,
        groupsAsync: planningGroupsAsync,
        accentColor: const Color(0xFF67C9B7),
        heroAssetPath: 'assets/images/mosque_guide.png',
        roleToneLabel: '',
        quickActions: const [],
        showOverviewSection: false,
      ),
      planningChild: const GuidePlanningPage(),
      alertsChild: const MobileAlertsScreen(),
      chatbotChild: const MobileChatScreen(),
      profileChild: RoleProfileTemplate(
        user: user,
        roleLabel: 'Guide',
        accentColor: const Color(0xFF67C9B7),
        onEdit: () => context.push('/profile-edit'),
      ),
    );
  }
}
