import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/auth/domain/auth_user.dart';
import '../theme/app_theme.dart';
import 'app_surfaces.dart';

class RoleProfileTemplate extends StatelessWidget {
  const RoleProfileTemplate({
    super.key,
    required this.user,
    required this.roleLabel,
    required this.accentColor,
    required this.onEdit,
    required this.onLogout,
  });

  final AuthUser user;
  final String roleLabel;
  final Color accentColor;
  final VoidCallback onEdit;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final fullName = user.fullName.isNotEmpty ? user.fullName : user.email;
    final email = user.email.isNotEmpty ? user.email : 'Not provided';
    final phone = user.telephone?.isNotEmpty == true
        ? user.telephone!
        : 'Not provided';
    final birthDate = _formatDate(user.dateNaissance);
    final nationality = user.nationalite?.isNotEmpty == true
        ? user.nationalite!
        : 'Not provided';
    final passport = user.numeroPasseport?.isNotEmpty == true
        ? user.numeroPasseport!
        : 'Not provided';
    final specialite = user.specialite?.isNotEmpty == true
        ? user.specialite!
        : 'Not provided';
    final groupeNom = user.groupeNom?.isNotEmpty == true
        ? user.groupeNom!
        : 'Not assigned';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const SectionTitle(
          'Profile',
          subtitle:
              'Your mobile identity, linked journey details, and account actions.',
          bottomPadding: AppSpacing.sm,
          titleStyle: TextStyle(
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
                      label: '$roleLabel · Active account',
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
          title: 'Personal information',
          children: [
            _ProfileTile(
              icon: Icons.person_outline_rounded,
              title: 'First name',
              subtitle: user.prenom.isEmpty ? '-' : user.prenom,
            ),
            _ProfileTile(
              icon: Icons.badge_outlined,
              title: 'Last name',
              subtitle: user.nom.isEmpty ? '-' : user.nom,
            ),
            _ProfileTile(
              icon: Icons.alternate_email_rounded,
              title: 'Email',
              subtitle: email,
            ),
            _ProfileTile(
              icon: Icons.phone_outlined,
              title: 'Phone number',
              subtitle: phone,
            ),
            if (user.lienParente?.isNotEmpty == true)
              _ProfileTile(
                icon: Icons.family_restroom_outlined,
                title: 'Relationship',
                subtitle: user.lienParente!,
              ),
            if (user.role == 'GUIDE')
              _ProfileTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Speciality',
                subtitle: specialite,
              ),
            if (user.role == 'PELERIN') ...[
              _ProfileTile(
                icon: Icons.groups_outlined,
                title: 'Current group',
                subtitle: groupeNom,
              ),
              _ProfileTile(
                icon: Icons.cake_outlined,
                title: 'Birth date',
                subtitle: birthDate,
              ),
              _ProfileTile(
                icon: Icons.public_outlined,
                title: 'Nationality',
                subtitle: nationality,
              ),
              _ProfileTile(
                icon: Icons.airplane_ticket_outlined,
                title: 'Passport number',
                subtitle: passport,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppListTileCard(
          icon: Icons.edit_note_rounded,
          title: 'Edit profile',
          subtitle: 'Update your personal information and journey details.',
          iconTone: accentColor,
          onTap: onEdit,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppListTileCard(
          icon: Icons.logout_rounded,
          title: 'Log out',
          subtitle: 'End your current session on this device.',
          iconTone: AppColors.red,
          onTap: () async => onLogout(),
        ),
      ],
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Not provided';
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
      const SnackBar(content: Text('Unique code copied')),
    );
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
