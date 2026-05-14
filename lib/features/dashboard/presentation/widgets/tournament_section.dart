import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_states.dart';
import '../../domain/providers/dashboard_providers.dart';
import '../../../tournaments/domain/models/tournament_model.dart';
import 'tournament_card.dart';

class TournamentSection extends ConsumerStatefulWidget {
  const TournamentSection({super.key});

  @override
  ConsumerState<TournamentSection> createState() => _TournamentSectionState();
}

class _TournamentSectionState extends ConsumerState<TournamentSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab navigation
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Ongoing'),
              Tab(text: 'Finished'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTournamentList('upcoming'),
              _buildTournamentList('ongoing'),
              _buildTournamentList('finished'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentList(String type) {
    final provider = _getTournamentProvider(type);

    return ref.watch(provider).when(
          data: (tournaments) {
            if (tournaments.isEmpty) {
              return _buildEmptyState(type);
            }

            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: tournaments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return TournamentCard(tournament: tournaments[index]);
              },
            );
          },
          loading: () => ListView.separated(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => _buildTournamentCardSkeleton(),
          ),
          error: (error, st) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    'Failed to load tournaments',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildEmptyState(String type) {
    final message = _getEmptyStateMessage(type);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Flexible(
            child: Text(
              message,
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

  Widget _buildTournamentCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner skeleton
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
          const SizedBox(height: 12),
          // Title skeleton
          Container(
            height: 16,
            width: 200,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          // Info skeleton
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  AutoDisposeStreamProvider<List<TournamentModel>> _getTournamentProvider(
      String type) {
    switch (type) {
      case 'upcoming':
        return upcomingTournamentsStreamProvider;
      case 'ongoing':
        return activeTournamentsStreamProvider;
      case 'finished':
        return finishedTournamentsStreamProvider;
      default:
        return upcomingTournamentsStreamProvider;
    }
  }

  String _getEmptyStateMessage(String type) {
    switch (type) {
      case 'upcoming':
        return 'No upcoming tournaments';
      case 'ongoing':
        return 'No tournaments currently ongoing';
      case 'finished':
        return 'No finished tournaments';
      default:
        return 'No tournaments found';
    }
  }
}
