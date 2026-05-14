import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/dashboard_providers.dart';
import '../../../matches/domain/models/match_model.dart';
import 'live_match_card.dart';

class LiveMatchesSection extends ConsumerWidget {
  const LiveMatchesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(liveMatchesStreamProvider).when(
          data: (liveMatches) {
            if (liveMatches.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: liveMatches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return LiveMatchCard(match: liveMatches[index]);
              },
            );
          },
          loading: () => ListView.separated(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => _buildLiveMatchCardSkeleton(),
          ),
          error: (error, st) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    'Failed to load live matches',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.live.withOpacity(0.1),
            ),
            child: Icon(
              Icons.sports_soccer,
              size: 48,
              color: AppColors.live.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: Text(
              'No live matches',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              'Check back soon for live updates',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMatchCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        children: [
          // Header skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Container(
                width: 50,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Teams skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home team
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 60,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // Score
              Container(
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Away team
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 60,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
