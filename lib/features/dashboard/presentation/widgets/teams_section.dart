import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/dashboard_providers.dart';
import '../../../teams/domain/models/team_model.dart';
import 'team_card.dart';

class TeamsSection extends ConsumerStatefulWidget {
  const TeamsSection({super.key});

  @override
  ConsumerState<TeamsSection> createState() => _TeamsSectionState();
}

class _TeamsSectionState extends ConsumerState<TeamsSection> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final crossAxisCount = isMobile ? 2 : 3;

    return Column(
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              ref.read(dashboardSearchQueryProvider.notifier).state = value;
            },
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search teams...',
              hintStyle: TextStyle(color: AppColors.textTertiary),
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(dashboardSearchQueryProvider.notifier).state =
                            '';
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Teams grid with filtered results
        Expanded(
          child: ref.watch(filteredTeamsProvider).isEmpty
              ? ref.watch(allTeamsStreamProvider).when(
                    data: (teams) {
                      if (teams.isEmpty) {
                        return _buildEmptyState(context, false);
                      }
                      return _buildEmptyState(context, true);
                    },
                    loading: () => GridView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isMobile ? 0.85 : 0.9,
                      ),
                      itemCount: 6,
                      itemBuilder: (_, __) => _buildTeamCardSkeleton(),
                    ),
                    error: (error, st) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: AppColors.error, size: 48),
                          const SizedBox(height: 12),
                          Text('Failed to load teams'),
                        ],
                      ),
                    ),
                  )
              : GridView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isMobile ? 0.85 : 0.9,
                  ),
                  itemCount: ref.watch(filteredTeamsProvider).length,
                  itemBuilder: (context, index) {
                    return TeamCard(
                        team: ref.watch(filteredTeamsProvider)[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.groups,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Flexible(
            child: Text(
              isSearching ? 'No teams found' : 'No teams registered',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo skeleton
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          const SizedBox(height: 12),
          // Name skeleton
          Container(
            height: 14,
            width: 100,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          // Short name skeleton
          Container(
            height: 12,
            width: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          // Stats skeleton
          Container(
            height: 10,
            width: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
