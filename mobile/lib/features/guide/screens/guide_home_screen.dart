import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/role_home_template.dart';
import '../../../core/widgets/role_profile_template.dart';
import '../../../core/widgets/role_shell.dart';
import '../../auth/providers/auth_provider.dart';
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

    void openParcoursSheet() {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const GuideGroupesSheet(
          openPelerinsOnTap: false,
        ),
      );
    }

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
      homeChild: RoleHomeTemplate(
        title: 'Le terrain, coordonne depuis le mobile.',
        subtitle:
            'Retrouvez votre groupe, la localisation live et les actions prioritaires dans une interface plus proche du web.',
        roleLabel: 'Guide · Mobile',
        accentColor: Color(0xFF67C9B7),
        icon: Icons.map_outlined,
        stats: const [
          HomeStatData(value: 'GPS', label: 'suivi live'),
          HomeStatData(value: 'Groupe', label: 'coordination'),
          HomeStatData(value: 'SOS', label: 'actions rapides'),
        ],
        cards: [
          InfoCardData(
            title: 'Groupe du jour',
            description:
                'Consultez la liste de vos pelerins pour chaque groupe.',
            icon: Icons.groups_outlined,
            tag: 'Coordination',
            onTap: openGroupesSheet,
          ),
          InfoCardData(
            title: 'Etape actuelle',
            description:
                'Vous pourrez mettre a jour l etape du groupe pour les familles et l agence sans quitter votre ecran principal.',
            icon: Icons.flag_outlined,
            tag: 'Progression',
            toneColor: Color(0xFF6B7FD7),
            onTap: openParcoursSheet,
          ),
          const InfoCardData(
            title: 'Incidents et SOS',
            description:
                'Les alertes et signalements arriveront ici avec les actions a mener en priorite.',
            icon: Icons.emergency_outlined,
            tag: 'Urgence',
            toneColor: Color(0xFFB8962E),
          ),
        ],
      ),
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
