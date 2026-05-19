// ignore_for_file: control_flow_in_finally

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../../../core/widgets/role_journey_home_content.dart';
import '../../../core/widgets/role_profile_template.dart';
import '../../../core/widgets/role_shell.dart';
import '../../auth/domain/auth_exception.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/auth_feedback.dart';
import '../../chat/screens/mobile_chat_screen.dart';
import '../../planning/domain/mobile_planning_models.dart';
import '../../planning/providers/mobile_planning_provider.dart';
import '../../notifications/screens/mobile_alerts_screen.dart';
import '../../planning/screens/role_planning_pages.dart';
import '../widgets/guide_groupes_sheet.dart';
import '../widgets/guide_groupe_pelerins_sheet.dart';

class GuideHomeScreen extends ConsumerStatefulWidget {
  const GuideHomeScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  ConsumerState<GuideHomeScreen> createState() => _GuideHomeScreenState();
}

class _GuideHomeScreenState extends ConsumerState<GuideHomeScreen> {
  bool _isUpdatingDisponibilite = false;
  bool? _optimisticDisponibilite;

  Future<void> _updateDisponibiliteGuide(bool isDisponible) async {
    if (_isUpdatingDisponibilite) {
      return;
    }

    final session = ref.read(authProvider).valueOrNull;
    final user = session?.user;
    if (user == null || user.role != 'GUIDE') {
      return;
    }

    setState(() {
      _optimisticDisponibilite = isDisponible;
      _isUpdatingDisponibilite = true;
    });

    try {
      await ref.read(authProvider.notifier).updateProfile(
            nom: user.nom,
            prenom: user.prenom,
            email: user.email,
            telephone: user.telephone,
            specialite: user.specialite,
            disponibilite: isDisponible ? 'DISPONIBLE' : 'INDISPONIBLE',
          );

      if (mounted) {
        showAuthSnackBar(
          context,
          isDisponible
              ? 'guide.home.disponible_toast'.tr()
              : 'guide.home.indisponible_toast'.tr(),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        showAuthSnackBar(context, error.message);
      }
    } catch (_) {
      if (mounted) {
        showAuthSnackBar(context, 'guide.home.disponibilite_error'.tr());
      }
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUpdatingDisponibilite = false;
        _optimisticDisponibilite = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull?.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final fullName = user.fullName.trim();
    final firstName = user.prenom.trim().isNotEmpty
        ? user.prenom.trim()
        : (fullName.isNotEmpty ? fullName.split(' ').first : user.email);
    final planningGroupsAsync = ref.watch(mobilePlanningGroupsProvider);
    final guideGroups = planningGroupsAsync.valueOrNull ?? const <MobilePlanningGroup>[];

    void openGroupesSheet() {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const GuideGroupesSheet(),
      );
    }

    void openPelerinsSheet() {
      if (guideGroups.isEmpty) {
        openGroupesSheet();
        return;
      }

      if (guideGroups.length > 1) {
        openGroupesSheet();
        return;
      }

      final targetGroup = guideGroups.first;

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => GuideGroupePelerinsSheet(
          groupeId: targetGroup.id,
          groupeNom: targetGroup.nom,
          groupeStatus: targetGroup.status,
        ),
      );
    }

    return RoleShell(
      key: ValueKey('guide-shell-${user.id}'),
      initialIndex: widget.initialTabIndex,
      accountActions: [
        RoleShellAccountAction(
          label: 'guide.home.groupes_list'.tr(),
          icon: Icons.history_rounded,
          toneColor: const Color(0xFF67C9B7),
          onTap: (_) async => openGroupesSheet(),
        ),
        RoleShellAccountAction(
          label: 'guide.home.pelerins_list'.tr(),
          icon: Icons.groups_outlined,
          toneColor: const Color(0xFF2D7A4A),
          onTap: (_) async => openPelerinsSheet(),
        ),
        RoleShellAccountAction(
          label: 'guide.home.language'.tr(),
          icon: Icons.language_rounded,
          toneColor: AppColors.blue,
          onTap: (context) async => _showLanguagePicker(context),
        ),
        RoleShellAccountAction(
          label: 'guide.home.logout'.tr(),
          icon: Icons.logout_rounded,
          toneColor: AppColors.red,
          onTap: (context) async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) {
              context.go('/login');
            }
          },
        ),
      ],
      homeChild: RoleJourneyHomeContent(
        firstName: firstName,
        groupeNom: user.groupeNom,
        groupsAsync: planningGroupsAsync,
        accentColor: const Color(0xFF67C9B7),
        heroAssetPath: 'assets/images/mosque_guide.png',
        roleToneLabel: '',
        quickActions: const [],
        showOverviewSection: false,
        extraSections: [
          _GuidePresenceEntryCard(
            onTap: () => context.push('/guide-presence-home'),
          ),
        ],
      ),
      planningChild: const GuidePlanningPage(),
      alertsChild: const MobileAlertsScreen(),
      chatbotChild: const MobileChatScreen(),
      profileChild: RoleProfileTemplate(
        user: user,
        roleLabel: 'roles.guide'.tr(),
        accentColor: const Color(0xFF67C9B7),
        onEdit: () => context.push('/profile-edit'),
        onGuideDisponibiliteChanged: _updateDisponibiliteGuide,
        guideDisponibiliteUpdating: _isUpdatingDisponibilite,
        guideDisponibiliteOverride: _optimisticDisponibilite,
      ),
    );
  }
}

Future<void> _showLanguagePicker(BuildContext context) async {
  final selectedLocale = await showModalBottomSheet<Locale>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        _LanguagePickerSheet(currentLocale: context.locale),
  );

  if (selectedLocale == null) {
    return;
  }

  if (!context.mounted) {
    return;
  }

  await context.setLocale(selectedLocale);
}

class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet({required this.currentLocale});

  final Locale currentLocale;

  @override
  Widget build(BuildContext context) {
    final options = <({Locale locale, String key})>[
      (locale: const Locale('fr'), key: 'guide.home.language_french'),
      (locale: const Locale('en'), key: 'guide.home.language_english'),
      (locale: const Locale('ar'), key: 'guide.home.language_arabic'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Material(
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.borderSoft),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'guide.home.choose_language'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map(
                  (option) => _LanguageOptionTile(
                    label: option.key.tr(),
                    isSelected:
                        option.locale.languageCode ==
                        currentLocale.languageCode,
                    onTap: () => Navigator.of(context).pop(option.locale),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.goldSoft
              : AppColors.section.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.borderSoft,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.gold : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.gold,
              ),
          ],
        ),
      ),
    );
  }
}

class _GuidePresenceEntryCard extends StatelessWidget {
  const _GuidePresenceEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: 20,
      borderColor: const Color(0xFFB7E6C8),
      gradient: const LinearGradient(
        colors: [Color(0xFFE9F8EE), Color(0xFFD8F0E2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'guide.presence.card_title'.tr(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF145434),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'guide.presence.card_subtitle'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C6D47),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF145434),
            size: 22,
          ),
        ],
      ),
    );
  }
}
