import 'package:flutter/material.dart';

import '../../auth/widgets/role_home_template.dart';

class FamilleHomeScreen extends StatelessWidget {
  const FamilleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeTemplate(
      title: 'Gardez le lien avec votre proche.',
      subtitle: 'Le suivi famille reprend le meme langage visuel que le web pour rendre les informations plus rassurantes et plus lisibles.',
      roleLabel: 'Famille · Mobile',
      accentColor: Color(0xFFE58E73),
      icon: Icons.family_restroom_outlined,
      stats: [
        HomeStatData(value: 'Live', label: 'nouvelles'),
        HomeStatData(value: 'Statut', label: 'proche suivi'),
        HomeStatData(value: 'Alertes', label: 'prioritaires'),
      ],
      cards: [
        InfoCardData(
          title: 'Statut actuel',
          description: 'Vous verrez ici si votre proche est present, en deplacement ou en alerte avec un resume tres clair.',
          icon: Icons.health_and_safety_outlined,
          tag: 'Statut',
        ),
        InfoCardData(
          title: 'Progression',
          description: 'Les etapes franchies seront affichees sur une timeline simple a suivre depuis votre telephone.',
          icon: Icons.timeline_outlined,
          tag: 'Timeline',
          toneColor: Color(0xFF6B7FD7),
        ),
        InfoCardData(
          title: 'Notifications',
          description: 'Les mises a jour importantes et les resolutions d incidents seront centralisees ici dans un seul flux.',
          icon: Icons.notifications_active_outlined,
          tag: 'Alertes',
          toneColor: Color(0xFF2D7A4A),
        ),
      ],
    );
  }
}
