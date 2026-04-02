import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/auth/domain/auth_user.dart';
import '../theme/app_theme.dart';

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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(alpha: 0.95),
                accentColor.withValues(alpha: 0.72),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileAvatar(
                user: user,
                accentColor: accentColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$roleLabel · Active account',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    if (user.codeUnique?.isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      _CopyableCodeChip(
                        code: user.codeUnique!,
                        onCopy: () => _copyCode(context, user.codeUnique!),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.white.withValues(alpha: 0.18),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onEdit,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
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
        const SizedBox(height: 12),
        _ProfileActionTile(
          icon: Icons.logout_rounded,
          title: 'Log out',
          color: const Color(0xFFB94A48),
          onTap: onLogout,
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
        radius: 30,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        backgroundImage: NetworkImage(photoUrl),
      );
    }

    return CircleAvatar(
      radius: 30,
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
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onCopy,
        borderRadius: BorderRadius.circular(999),
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
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
      ),
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
          const SizedBox(height: 10),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.section,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: AppColors.text),
          ),
          const SizedBox(width: 10),
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
                    color: AppColors.text,
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

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
