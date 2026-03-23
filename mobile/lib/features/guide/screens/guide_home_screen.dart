import 'package:flutter/material.dart';

import '../../auth/widgets/role_home_template.dart';

class GuideHomeScreen extends StatelessWidget {
  const GuideHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeTemplate(
      title: 'Le terrain, coordonne depuis le mobile.',
      subtitle: 'Retrouvez votre groupe, la localisation live et les actions prioritaires dans une interface plus proche du web SmartHajj.',
      roleLabel: 'Guide · Mobile',
      accentColor: Color(0xFF67C9B7),
      icon: Icons.map_outlined,
      stats: [
        HomeStatData(value: 'GPS', label: 'suivi live'),
        HomeStatData(value: 'Groupe', label: 'coordination'),
        HomeStatData(value: 'SOS', label: 'actions rapides'),
      ],
      cards: [
        InfoCardData(
          title: 'Groupe du jour',
          description: 'La liste de vos pelerins et leur etat de presence seront visibles ici avec une lecture plus immediate.',
          icon: Icons.groups_outlined,
          tag: 'Coordination',
        ),
        InfoCardData(
          title: 'Etape actuelle',
          description: 'Vous pourrez mettre a jour l etape du groupe pour les familles et l agence sans quitter votre ecran principal.',
          icon: Icons.flag_outlined,
          tag: 'Progression',
          toneColor: Color(0xFF6B7FD7),
        ),
        InfoCardData(
          title: 'Incidents et SOS',
          description: 'Les alertes et signalements arriveront ici avec les actions a mener en priorite.',
          icon: Icons.emergency_outlined,
          tag: 'Urgence',
          toneColor: Color(0xFFB8962E),
        ),
      ],
    );
  }
}
