import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/theme/app_theme.dart';
import '../../planning/providers/mobile_planning_provider.dart';
import '../widgets/guide_presence_groups_section.dart';

class GuidePresenceHomeScreen extends ConsumerStatefulWidget {
  const GuidePresenceHomeScreen({super.key});

  @override
  ConsumerState<GuidePresenceHomeScreen> createState() =>
      _GuidePresenceHomeScreenState();
}

class _GuidePresenceHomeScreenState
    extends ConsumerState<GuidePresenceHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(mobilePlanningGroupsProvider);
    final normalizedQuery = _searchQuery.trim().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F3),
      appBar: AppBar(
        title: Text(
          'guide.presence.home.title'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(mobilePlanningGroupsProvider);
          await ref.read(mobilePlanningGroupsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'guide.presence.home.search_hint'.tr(),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.trim().isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 14),
            groupsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (error, _) => _PresenceStateCard(
                icon: Icons.error_outline_rounded,
                title: 'guide.presence.home.load_error_title'.tr(),
                subtitle: error.toString(),
              ),
              data: (groups) {
                if (groups.isEmpty) {
                  return _PresenceStateCard(
                    icon: Icons.groups_outlined,
                    title: 'guide.presence.home.empty_groups_title'.tr(),
                    subtitle: 'guide.presence.home.empty_groups_subtitle'.tr(),
                  );
                }

                final visibleGroups = normalizedQuery.isEmpty
                    ? groups
                    : groups
                          .where(
                            (group) =>
                                group.nom.toLowerCase().contains(normalizedQuery),
                          )
                          .toList();

                if (visibleGroups.isEmpty) {
                  return _PresenceStateCard(
                    icon: Icons.search_off_rounded,
                    title: 'guide.presence.home.no_result_title'.tr(),
                    subtitle: 'guide.presence.home.no_result_subtitle'.tr(),
                  );
                }

                return GuidePresenceGroupsSection(groups: visibleGroups);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PresenceStateCard extends StatelessWidget {
  const _PresenceStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.section,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
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
