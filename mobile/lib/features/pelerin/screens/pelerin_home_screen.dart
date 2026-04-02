import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/role_home_template.dart';
import '../../../core/widgets/role_profile_template.dart';
import '../../../core/widgets/role_shell.dart';
import '../../auth/providers/auth_provider.dart';

class PelerinHomeScreen extends ConsumerWidget {
  const PelerinHomeScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final session = authState.valueOrNull;
    final user = session?.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final name = user.fullName.isNotEmpty ? user.fullName : user.email;

    return RoleShell(
      initialIndex: initialTabIndex,
      homeChild: RoleHomeTemplate(
        title: 'Votre parcours, dans un seul espace.',
        subtitle: name.isEmpty
            ? 'Retrouvez vos etapes, rendez-vous et informations utiles.'
            : '$name, retrouvez vos etapes, rendez-vous et informations utiles.',
        roleLabel: 'Pelerin · Mobile',
        accentColor: const Color(0xFFD4AF37),
        icon: Icons.mosque_outlined,
        stats: const [
          HomeStatData(value: 'Hajj', label: 'parcours'),
          HomeStatData(value: 'Live', label: 'infos groupe'),
          HomeStatData(value: '24/7', label: 'assistance'),
        ],
        cards: const [
          InfoCardData(
            title: 'Mon parcours',
            description:
                'Les etapes du Hajj seront affichees ici avec un fil simple a suivre et des reperes clairs comme sur le web.',
            icon: Icons.route_outlined,
            tag: 'Parcours',
          ),
          InfoCardData(
            title: 'Planning du jour',
            description:
                'Les horaires, points de rendez-vous et rappels de la journee apparaitront dans une carte plus lisible et structuree.',
            icon: Icons.calendar_month_outlined,
            tag: 'Agenda',
            toneColor: Color(0xFF6B7FD7),
          ),
          InfoCardData(
            title: 'Mon statut',
            description:
                'Vous pourrez bientot declarer present, en deplacement ou besoin d aide avec un statut partage a votre guide.',
            icon: Icons.verified_user_outlined,
            tag: 'Statut',
            toneColor: Color(0xFF2D7A4A),
          ),
        ],
      ),
      profileChild: RoleProfileTemplate(
        user: user,
        roleLabel: 'Pelerin',
        accentColor: const Color(0xFFD4AF37),
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
