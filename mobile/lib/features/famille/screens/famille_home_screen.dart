import 'package:flutter/material.dart';

import '../../auth/widgets/role_home_template.dart';

class FamilleHomeScreen extends StatelessWidget {
  const FamilleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeTemplate(
      title: 'Espace Famille',
      subtitle: 'Le suivi de votre proche apparaitra ici apres association.',
      accentColor: Color(0xFFE58E73),
      icon: Icons.family_restroom_outlined,
      cards: [
        InfoCardData(
          title: 'Statut actuel',
          description: 'Vous verrez ici si votre proche est present, en deplacement ou en alerte.',
          icon: Icons.health_and_safety_outlined,
        ),
        InfoCardData(
          title: 'Progression',
          description: 'Les etapes franchies seront affichees sur une timeline simple a suivre.',
          icon: Icons.timeline_outlined,
        ),
        InfoCardData(
          title: 'Notifications',
          description: 'Les mises a jour importantes et resolutions d incidents seront centralisees ici.',
          icon: Icons.notifications_active_outlined,
        ),
      ],
    );
  }
}
