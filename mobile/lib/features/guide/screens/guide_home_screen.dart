import 'package:flutter/material.dart';

import '../../auth/widgets/role_home_template.dart';

class GuideHomeScreen extends StatelessWidget {
  const GuideHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeTemplate(
      title: 'Espace Guide',
      subtitle: 'Votre suivi terrain sera centralise ici.',
      accentColor: Color(0xFF67C9B7),
      icon: Icons.map_outlined,
      cards: [
        InfoCardData(
          title: 'Groupe du jour',
          description: 'La liste de vos pelerins et l etat de presence seront visibles ici.',
          icon: Icons.groups_outlined,
        ),
        InfoCardData(
          title: 'Etape actuelle',
          description: 'Vous pourrez mettre a jour l etape du groupe pour les familles et l agence.',
          icon: Icons.flag_outlined,
        ),
        InfoCardData(
          title: 'Incidents et SOS',
          description: 'Les alertes et les signalements arriveront ici avec les actions a mener.',
          icon: Icons.emergency_outlined,
        ),
      ],
    );
  }
}
