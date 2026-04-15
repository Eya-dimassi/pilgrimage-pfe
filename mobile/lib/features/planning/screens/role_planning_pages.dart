import 'package:flutter/material.dart';

import 'mobile_planning_screen.dart';

class GuidePlanningPage extends StatelessWidget {
  const GuidePlanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MobilePlanningScreen(
      view: PlanningRoleView.guide,
      accentColor: Color(0xFF67C9B7),
    );
  }
}

class PelerinPlanningPage extends StatelessWidget {
  const PelerinPlanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MobilePlanningScreen(
      view: PlanningRoleView.pelerin,
      accentColor: Color(0xFFD4AF37),
    );
  }
}

class FamillePlanningPage extends StatelessWidget {
  const FamillePlanningPage({
    super.key,
    this.preferredGroupId,
  });

  final String? preferredGroupId;

  @override
  Widget build(BuildContext context) {
    return MobilePlanningScreen(
      view: PlanningRoleView.famille,
      accentColor: const Color(0xFFE58E73),
      preferredGroupId: preferredGroupId,
    );
  }
}
