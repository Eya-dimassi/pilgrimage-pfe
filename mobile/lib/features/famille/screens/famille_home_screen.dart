import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/role_home_template.dart';
import '../../../core/widgets/role_profile_template.dart';
import '../../../core/widgets/role_shell.dart';
import '../../auth/domain/auth_exception.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/auth_feedback.dart';
import '../../notifications/screens/mobile_alerts_screen.dart';
import '../domain/family_link.dart';
import '../providers/family_links_provider.dart';
import '../../planning/screens/role_planning_pages.dart';

class FamilleHomeScreen extends ConsumerStatefulWidget {
  const FamilleHomeScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  ConsumerState<FamilleHomeScreen> createState() => _FamilleHomeScreenState();
}

class _FamilleHomeScreenState extends ConsumerState<FamilleHomeScreen> {
  late int _shellIndex;
  String? _selectedFamilyGroupId;

  @override
  void initState() {
    super.initState();
    _shellIndex = widget.initialTabIndex;
  }

  @override
  void didUpdateWidget(covariant FamilleHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _shellIndex = widget.initialTabIndex;
    }
  }

  Future<void> _openAddRelativeDialog(BuildContext screenContext) async {
    final codeController = TextEditingController();
    var submitting = false;

    await showDialog<void>(
      context: screenContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogInnerContext, setLocalState) {
            return AlertDialog(
              title: const Text('Ajouter un proche'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Entrez le code unique du pelerin pour lier un nouveau proche a votre compte famille.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: codeController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Code unique',
                      hintText: 'XXXXXXXX',
                      prefixIcon: Icon(Icons.qr_code_rounded),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          try {
                            setLocalState(() => submitting = true);
                            final message = await ref
                                .read(authProvider.notifier)
                                .addFamilyLink(codeUnique: codeController.text);
                            if (!mounted || !dialogContext.mounted) return;
                            ref.invalidate(familyLinksProvider);
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.of(dialogContext).pop();
                            if (!mounted) return;
                            showAuthSnackBar(screenContext, message);
                          } on AuthException catch (error) {
                            if (!mounted) return;
                            showAuthSnackBar(screenContext, error.message);
                            if (dialogInnerContext.mounted) {
                              setLocalState(() => submitting = false);
                            }
                          } catch (_) {
                            if (!mounted) return;
                            showAuthSnackBar(
                              screenContext,
                              'Une erreur est survenue',
                            );
                            if (dialogInnerContext.mounted) {
                              setLocalState(() => submitting = false);
                            }
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );

    codeController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull?.user;
    final familyLinksAsync = ref.watch(familyLinksProvider);

    if (user == null) {
      return const SizedBox.shrink();
    }

    return RoleShell(
      initialIndex: _shellIndex,
      homeChild: RoleHomeTemplate(
        title: 'Vos proches, reunis dans un seul espace.',
        subtitle:
            'Retrouvez rapidement les pelerins lies a votre compte et ouvrez leur planning du jour en un geste.',
        roleLabel: 'Famille - Mobile',
        accentColor: const Color(0xFFE58E73),
        icon: Icons.family_restroom_outlined,
        stats: const [],
        cards: const [],
        headerExtra: _FamilyHomeSummary(
          linksAsync: familyLinksAsync,
          accentColor: const Color(0xFFE58E73),
        ),
        footer: _FamilyLinksSection(
          linksAsync: familyLinksAsync,
          onAddRelative: () => _openAddRelativeDialog(context),
          onSelectLink: (link) => _handleLinkSelection(context, link),
          selectedGroupId: _selectedFamilyGroupId,
        ),
      ),
      planningChild: FamillePlanningPage(
        preferredGroupId: _selectedFamilyGroupId,
      ),
      alertsChild: const MobileAlertsScreen(),
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

  void _handleLinkSelection(BuildContext context, FamilyLink link) {
    final groupId = link.groupe?.id;
    if (groupId == null || groupId.isEmpty) {
      showAuthSnackBar(
        context,
        'Ce proche n a pas encore de groupe actif a afficher.',
      );
      return;
    }

    setState(() {
      _selectedFamilyGroupId = groupId;
      _shellIndex = 1;
    });
  }
}

class _FamilyHomeSummary extends StatelessWidget {
  const _FamilyHomeSummary({
    required this.linksAsync,
    required this.accentColor,
  });

  final AsyncValue<List<FamilyLink>> linksAsync;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final linkedCount = linksAsync.maybeWhen(
      data: (links) => links.length,
      orElse: () => null,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.people_alt_outlined,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linkedCount == null
                      ? 'Chargement de vos proches'
                      : '$linkedCount proche(s) lie(s)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choisissez un proche pour ouvrir directement son planning du jour.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyLinksSection extends StatelessWidget {
  const _FamilyLinksSection({
    required this.linksAsync,
    required this.onAddRelative,
    required this.onSelectLink,
    required this.selectedGroupId,
  });

  final AsyncValue<List<FamilyLink>> linksAsync;
  final VoidCallback onAddRelative;
  final ValueChanged<FamilyLink> onSelectLink;
  final String? selectedGroupId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Mes proches',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ajoutez un pelerin avec son code unique ou touchez une carte pour voir sa journee en direct.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onAddRelative,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Ajouter un proche'),
        ),
        const SizedBox(height: 14),
        linksAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Text(
              error.toString(),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          data: (links) {
            if (links.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: const Text(
                  'Aucun proche lie pour le moment.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              );
            }

            return Column(
              children: links
                  .map(
                    (link) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FamilyLinkCard(
                        link: link,
                        selected: link.groupe?.id == selectedGroupId,
                        onTap: () => onSelectLink(link),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _FamilyLinkCard extends StatelessWidget {
  const _FamilyLinkCard({
    required this.link,
    required this.selected,
    required this.onTap,
  });

  final FamilyLink link;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final groupLabel = link.groupe == null
        ? 'Sans groupe actif'
        : '${link.groupe!.nom} - ${link.groupe!.typeVoyage == 'HAJJ' ? 'Hajj' : 'Omra'} ${link.groupe!.annee}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? const Color(0xFFE58E73) : AppColors.borderSoft,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE58E73).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFFE58E73),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.fullName.isNotEmpty ? link.fullName : link.codeUnique,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code ${link.codeUnique}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textFaint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      groupLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: selected
                    ? const Color(0xFFE58E73)
                    : AppColors.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
