// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../features/auth/domain/auth_user.dart';
import '../theme/app_theme.dart';
import 'app_surfaces.dart';

typedef GuideDisponibiliteChanged = Future<void> Function(bool isDisponible);

class RoleProfileTemplate extends StatelessWidget {
  const RoleProfileTemplate({
    super.key,
    required this.user,
    required this.roleLabel,
    required this.accentColor,
    required this.onEdit,
    this.onGuideDisponibiliteChanged,
    this.guideDisponibiliteUpdating = false,
    this.guideDisponibiliteOverride,
    this.extraChildren = const [],
  });

  final AuthUser user;
  final String roleLabel;
  final Color accentColor;
  final VoidCallback onEdit;
  final GuideDisponibiliteChanged? onGuideDisponibiliteChanged;
  final bool guideDisponibiliteUpdating;
  final bool? guideDisponibiliteOverride;
  final List<Widget> extraChildren;

  @override
  Widget build(BuildContext context) {
    final fullName = user.fullName.isNotEmpty ? user.fullName : user.email;
    final email = user.email.isNotEmpty
        ? user.email
        : 'profile.common.not_provided'.tr();
    final phone = user.telephone?.isNotEmpty == true
        ? user.telephone!
        : 'profile.common.not_provided'.tr();
    final birthDate = _formatDate(user.dateNaissance);
    final nationality = user.nationalite?.isNotEmpty == true
        ? user.nationalite!
        : 'profile.common.not_provided'.tr();
    final passport = user.numeroPasseport?.isNotEmpty == true
        ? user.numeroPasseport!
        : 'profile.common.not_provided'.tr();
    final specialite = user.specialite?.isNotEmpty == true
        ? user.specialite!
        : 'profile.common.not_provided'.tr();
    final disponibiliteGuide =
        guideDisponibiliteOverride ?? user.disponibilite != 'INDISPONIBLE';
    final groupeNom = user.groupeNom?.isNotEmpty == true
        ? user.groupeNom!
        : 'profile.common.not_assigned'.tr();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        SectionTitle(
          'profile.title'.tr(),
          bottomPadding: AppSpacing.sm,
          titleStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
          ),
        ),
        AppCard(
          padding: const EdgeInsets.all(16),
          radius: 24,
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.95),
              accentColor.withValues(alpha: 0.74),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: Colors.transparent,
          shadow: AppShadows.lifted,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileAvatar(
                user: user,
                accentColor: accentColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.90),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppStatusChip(
                      label: 'profile.account_active'.tr(
                        namedArgs: {'role': roleLabel},
                      ),
                      icon: Icons.verified_rounded,
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      foregroundColor: Colors.white,
                      compact: true,
                    ),
                    if (user.codeUnique?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      _CopyableCodeChip(
                        code: user.codeUnique!,
                        onCopy: () => _copyCode(context, user.codeUnique!),
                      ),
                    ],
                    if (user.role == 'PELERIN' &&
                        user.codeUnique?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showQrModal(context, user.codeUnique!),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white70),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                        label: Text('profile.qr.button'.tr()),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: Colors.white.withValues(alpha: 0.18),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onEdit,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        _ProfileSection(
          title: 'profile.personal_info'.tr(),
          children: [
            _ProfileTile(
              icon: Icons.person_outline_rounded,
              title: 'profile.fields.first_name'.tr(),
              subtitle: user.prenom.isEmpty ? '-' : user.prenom,
            ),
            _ProfileTile(
              icon: Icons.badge_outlined,
              title: 'profile.fields.last_name'.tr(),
              subtitle: user.nom.isEmpty ? '-' : user.nom,
            ),
            _ProfileTile(
              icon: Icons.alternate_email_rounded,
              title: 'profile.fields.email'.tr(),
              subtitle: email,
            ),
            _ProfileTile(
              icon: Icons.phone_outlined,
              title: 'profile.fields.phone'.tr(),
              subtitle: phone,
            ),
            if (user.lienParente?.isNotEmpty == true)
              _ProfileTile(
                icon: Icons.family_restroom_outlined,
                title: 'profile.fields.relationship'.tr(),
                subtitle: _profileRelationshipLabel(user.lienParente!),
              ),
            if (user.role == 'GUIDE')
              _ProfileTile(
                icon: Icons.workspace_premium_outlined,
                title: 'profile.fields.specialty'.tr(),
                subtitle: specialite,
              ),
            if (user.role == 'GUIDE')
              _GuideDisponibiliteTile(
                icon: Icons.event_available_outlined,
                title: 'profile.fields.availability'.tr(),
                isDisponible: disponibiliteGuide,
                isUpdating: guideDisponibiliteUpdating,
                onChanged: onGuideDisponibiliteChanged,
              ),
            if (user.role == 'PELERIN') ...[
              _ProfileTile(
                icon: Icons.groups_outlined,
                title: 'profile.fields.current_group'.tr(),
                subtitle: groupeNom,
              ),
              _ProfileTile(
                icon: Icons.cake_outlined,
                title: 'profile.fields.birth_date'.tr(),
                subtitle: birthDate,
              ),
              _ProfileTile(
                icon: Icons.public_outlined,
                title: 'profile.fields.nationality'.tr(),
                subtitle: nationality,
              ),
              _ProfileTile(
                icon: Icons.airplane_ticket_outlined,
                title: 'profile.fields.passport_number'.tr(),
                subtitle: passport,
              ),
            ],
          ],
        ),
        if (extraChildren.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ...extraChildren,
        ],
      ],
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'profile.common.not_provided'.tr();
    }
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text('profile.code_copied'.tr())),
    );
  }

  void _showQrModal(BuildContext context, String codeUnique) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.92,
            minChildSize: 0.7,
            maxChildSize: 0.98,
            builder: (_, controller) {
              return SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'profile.qr.title'.tr(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'profile.qr.unique_code'.tr(
                        namedArgs: {'code': codeUnique},
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: QrImageView(
                        data: codeUnique,
                        version: QrVersions.auto,
                        size: 260,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'profile.qr.description'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: codeUnique),
                          );
                          if (!sheetContext.mounted) {
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(sheetContext);
                          messenger.hideCurrentSnackBar();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('profile.qr.copy_success'.tr()),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: Text('profile.qr.copy_button'.tr()),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

String _profileRelationshipLabel(String value) {
  switch (value.trim()) {
    case 'Mere':
      return 'edit_profile.relationship_options.mother'.tr();
    case 'Pere':
      return 'edit_profile.relationship_options.father'.tr();
    case 'Frere':
      return 'edit_profile.relationship_options.brother'.tr();
    case 'Soeur':
      return 'edit_profile.relationship_options.sister'.tr();
    case 'Epoux':
      return 'edit_profile.relationship_options.husband'.tr();
    case 'Epouse':
      return 'edit_profile.relationship_options.wife'.tr();
    case 'Enfant':
      return 'edit_profile.relationship_options.child'.tr();
    case 'Autre':
      return 'edit_profile.relationship_options.other'.tr();
    default:
      return value;
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.user,
    required this.accentColor,
  });

  final AuthUser user;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;

    if (hasPhoto) {
      return CircleAvatar(
        radius: 32,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        backgroundImage: NetworkImage(photoUrl),
      );
    }

    return CircleAvatar(
      radius: 32,
      backgroundColor: Colors.white.withValues(alpha: 0.94),
      child: Text(
        _initials(user),
        style: TextStyle(
          color: accentColor,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _initials(AuthUser user) {
    final prenom = user.prenom.trim();
    final nom = user.nom.trim();
    final first = prenom.isNotEmpty ? prenom[0] : '';
    final last = nom.isNotEmpty ? nom[0] : '';
    final result = '$first$last'.trim();
    return result.isEmpty ? 'SJ' : result.toUpperCase();
  }
}

class _CopyableCodeChip extends StatelessWidget {
  const _CopyableCodeChip({
    required this.code,
    required this.onCopy,
  });

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onCopy,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_rounded,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: AppSpacing.s),
              Flexible(
                child: Text(
                  code,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              const Icon(
                Icons.copy_rounded,
                size: 14,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox.shrink(),
          AppIconBadge(
            icon: icon,
            size: 38,
            backgroundColor: AppColors.section,
            foregroundColor: AppColors.textPrimary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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

class _GuideDisponibiliteTile extends StatelessWidget {
  const _GuideDisponibiliteTile({
    required this.icon,
    required this.title,
    required this.isDisponible,
    required this.isUpdating,
    this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool isDisponible;
  final bool isUpdating;
  final GuideDisponibiliteChanged? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox.shrink(),
          AppIconBadge(
            icon: icon,
            size: 38,
            backgroundColor: AppColors.section,
            foregroundColor: AppColors.textPrimary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isUpdating
                      ? 'profile.availability.updating'.tr()
                      : isDisponible
                      ? 'profile.availability.available_desc'.tr()
                      : 'profile.availability.unavailable_desc'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          if (isUpdating)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.green,
              ),
            )
          else
            Switch.adaptive(
              value: isDisponible,
              onChanged: onChanged == null
                  ? null
                  : (value) {
                      onChanged!(value);
                    },
              activeColor: AppColors.green,
            ),
        ],
      ),
    );
  }
}

