import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/role_journey_home_content.dart';
import '../../../core/widgets/role_profile_template.dart';
import '../../../core/widgets/role_shell.dart';
import '../../auth/providers/auth_provider.dart';
import '../../planning/providers/mobile_planning_provider.dart';
import '../../planning/screens/role_planning_pages.dart';
import '../widgets/guide_groupes_sheet.dart';

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

    void openGroupesSheet() {
      showModalBottomSheet<void>( 
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const GuideGroupesSheet(),
      );
    }

    return RoleShell(
      initialIndex: initialTabIndex,
      homeChild: RoleJourneyHomeContent(
        firstName: firstName,
        groupeNom: user.groupeNom,
        groupsAsync: planningGroupsAsync,
        accentColor: const Color(0xFF67C9B7),
        roleToneLabel:
            'Un rappel spirituel discret pour guider avec calme et presence.',
        quickActions: [
          HomeQuickAction(
            label: 'Pelerins',
            description: 'Liste par groupe',
            icon: Icons.groups_outlined,
            toneColor: const Color(0xFF2D7A4A),
            onTap: openGroupesSheet,
          ),
        ],
      ),
      planningChild: const GuidePlanningPage(),
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
