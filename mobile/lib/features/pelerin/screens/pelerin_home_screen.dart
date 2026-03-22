import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/role_home_template.dart';

class PelerinHomeScreen extends ConsumerWidget {
  const PelerinHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final session = authState.valueOrNull;
    final user = session?.user;
    final name = user?.fullName.isNotEmpty == true ? user!.fullName : user?.email ?? '';

    return RoleHomeTemplate(
      title: 'Espace Pelerin',
      subtitle: name,
      accentColor: const Color(0xFFD4AF37),
      icon: Icons.mosque_outlined,
      cards: const [
        InfoCardData(
          title: 'Mon parcours',
          description: 'Les etapes du Hajj seront affichees ici des que le backend mobile est pret.',
          icon: Icons.route_outlined,
        ),
        InfoCardData(
          title: 'Planning du jour',
          description: 'Le planning quotidien viendra ici avec les horaires et points de rendez-vous.',
          icon: Icons.calendar_month_outlined,
        ),
        InfoCardData(
          title: 'Mon statut',
          description: 'Vous pourrez bientot declarer present, en deplacement ou besoin d aide.',
          icon: Icons.verified_user_outlined,
        ),
      ],
    );
  }
}
