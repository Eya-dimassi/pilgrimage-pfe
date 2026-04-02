import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_frame.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.eyebrow,
    this.title,
    this.subtitle,
    this.leading,
    this.footer,
  });

  final String? eyebrow;
  final String? title;
  final String? subtitle;
  final Widget child;
  final Widget? leading;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final hasHeader = (eyebrow?.isNotEmpty ?? false) ||
        (title?.isNotEmpty ?? false) ||
        (subtitle?.isNotEmpty ?? false);

    return Scaffold(
      body: BrandBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 12),
                    ],
                    const Expanded(
                      child: BrandWordmark(
                        caption: 'Votre centre pour le voyage sacre',
                        markSize: 40,
                        titleSize: 18,
                      ),
                    ),
                  ],
                ),
                if (hasHeader) ...[
                  const SizedBox(height: 24),
                  if (eyebrow?.isNotEmpty ?? false) ...[
                    BrandPill(label: eyebrow!),
                    const SizedBox(height: 16),
                  ],
                  if (title?.isNotEmpty ?? false) ...[
                    Text(
                      title!,
                      style: GoogleFonts.syne(
                        fontSize: 30,
                        height: 1.08,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.9,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (subtitle?.isNotEmpty ?? false) ...[
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ] else
                    const SizedBox(height: 18),
                ] else
                  const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.borderSoft),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 28,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: child,
                ),
                if (footer != null) ...[
                  const SizedBox(height: 18),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
