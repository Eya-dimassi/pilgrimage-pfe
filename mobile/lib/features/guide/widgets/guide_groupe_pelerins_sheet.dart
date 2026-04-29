import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../planning/domain/mobile_planning_models.dart';
import '../../planning/providers/mobile_planning_provider.dart';

class GuideGroupePelerinsSheet extends ConsumerStatefulWidget {
  const GuideGroupePelerinsSheet({
    super.key,
    required this.groupeId,
    required this.groupeNom,
  });

  final String groupeId;
  final String groupeNom;

  @override
  ConsumerState<GuideGroupePelerinsSheet> createState() =>
      _GuideGroupePelerinsSheetState();
}

class _GuideGroupePelerinsSheetState
    extends ConsumerState<GuideGroupePelerinsSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pelerinsAsync = ref.watch(
      mobilePlanningGroupPelerinsProvider(widget.groupeId),
    );
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 14 + bottomInset),
        child: Material(
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: AppColors.borderSoft),
          ),
          child: SizedBox(
            height: height * 0.92,
            child: pelerinsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.gold,
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(18),
                child: _ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(
                    mobilePlanningGroupPelerinsProvider(widget.groupeId),
                  ),
                ),
              ),
              data: (items) {
                final query = _searchController.text.trim().toLowerCase();
                final visibleItems = query.isEmpty
                    ? items
                    : items
                        .where(
                          (p) =>
                              p.fullName.toLowerCase().contains(query) ||
                              (p.telephone ?? '').toLowerCase().contains(query),
                        )
                        .toList();

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(
                    mobilePlanningGroupPelerinsProvider(widget.groupeId).future,
                  ),
                  color: AppColors.gold,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
                    children: [
                      const SizedBox(height: 10),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.groupeNom,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              onPressed: () => ref.invalidate(
                                mobilePlanningGroupPelerinsProvider(widget.groupeId),
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pelerins',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${visibleItems.length} personne(s)',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search_rounded),
                                hintText: 'Rechercher par nom ou telephone',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (visibleItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: _EmptyState(),
                        )
                      else
                        ...visibleItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 9),
                            child: _PelerinCard(item: item),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PelerinCard extends StatelessWidget {
  const _PelerinCard({required this.item});

  final MobileGroupPelerin item;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(item.prenom, item.nom);
    const tone = AppColors.blue;

    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.borderSoft, width: 0.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: tone.withValues(alpha: 0.14),
              child: Text(
                initials,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: tone,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.telephone == null || item.telephone!.trim().isEmpty
                        ? '-'
                        : item.telephone!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.section,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.textMuted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aucun pelerin dans ce groupe pour le moment.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.section,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }
}

String _initials(String prenom, String nom) {
  String first(String v) => v.trim().isEmpty ? '' : v.trim()[0].toUpperCase();
  final a = first(prenom);
  final b = first(nom);
  final s = (a + b).trim();
  return s.isEmpty ? '?' : s;
}
