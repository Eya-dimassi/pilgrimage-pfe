import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/role_home_template.dart';
import '../../../core/widgets/role_profile_template.dart';
import '../../../core/widgets/role_shell.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/famille_parcours_pelerins.dart';

class FamilleHomeScreen extends ConsumerWidget {
  const FamilleHomeScreen({
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

    void openParcoursSheet() {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const FamilleParcoursPelerinsSheet(),
      );
    }

    return RoleShell(
      initialIndex: initialTabIndex,
      homeChild: RoleHomeTemplate(
        title: 'Gardez le lien avec votre proche.',
        subtitle:
            'Le suivi famille reprend le meme langage visuel que le web pour rendre les informations plus rassurantes et plus lisibles.',
        roleLabel: 'Famille · Mobile',
        accentColor: Color(0xFFE58E73),
        icon: Icons.family_restroom_outlined,
        stats: const [
          HomeStatData(value: 'Live', label: 'nouvelles'),
          HomeStatData(value: 'Statut', label: 'proche suivi'),
          HomeStatData(value: 'Alertes', label: 'prioritaires'),
        ],
        cards: [
          const InfoCardData(
            title: 'Statut actuel',
            description:
                'Vous verrez ici si votre proche est present, en deplacement ou en alerte avec un resume tres clair.',
            icon: Icons.health_and_safety_outlined,
            tag: 'Statut',
          ),
          InfoCardData(
            title: 'Progression',
            description:
                'Les etapes franchies seront affichees sur une timeline simple a suivre depuis votre telephone.',
            icon: Icons.timeline_outlined,
            tag: 'Timeline',
            toneColor: Color(0xFF6B7FD7),
            onTap: openParcoursSheet,
          ),
          const InfoCardData(
            title: 'Notifications',
            description:
                'Les mises a jour importantes et les resolutions d incidents seront centralisees ici dans un seul flux.',
            icon: Icons.notifications_active_outlined,
            tag: 'Alertes',
            toneColor: Color(0xFF2D7A4A),
          ),
        ],
      ),
      profileChild: RoleProfileTemplate(
        user: user,
        roleLabel: 'Famille',
        accentColor: const Color(0xFFE58E73),
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
