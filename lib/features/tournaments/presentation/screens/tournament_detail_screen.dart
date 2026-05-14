import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../data/repositories/tournament_repository.dart';
import '../../domain/models/tournament_model.dart';
import '../../../../shared/widgets/loading_states.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../matches/data/repositories/match_repository.dart';
import '../../../matches/domain/models/match_model.dart';

class TournamentDetailScreen extends ConsumerWidget {
  final String id;
  const TournamentDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentAsync = ref.watch(tournamentDetailProvider(id));
    final matchesAsync = ref.watch(matchesStreamProvider(id));

    return tournamentAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const ShimmerList(count: 3),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: ErrorState(message: e.toString()),
      ),
      data: (tournament) {
        if (tournament == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(),
            body: const EmptyState(title: 'Tournament not found'),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // Banner App Bar
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: AppColors.surface,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    tournament.name,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  background: tournament.bannerUrl != null
                      ? AppNetworkImage(
                          imageUrl: tournament.bannerUrl,
                          borderRadius: 0,
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.emoji_events,
                              size: 64,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => context.go('/tournaments/$id/edit'),
                  ),
                ],
              ),

              // Info Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status & Type chips
                      Row(
                        children: [
                          _Chip(
                            label: tournament.status.displayName,
                            color: tournament.status == TournamentStatus.ongoing
                                ? AppColors.success
                                : tournament.status == TournamentStatus.upcoming
                                    ? AppColors.info
                                    : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          _Chip(
                            label: tournament.type.displayName,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stats row
                      Row(
                        children: [
                          _StatBox(
                            icon: Icons.groups,
                            label: 'Teams',
                            value: tournament.maxTeams.toString(),
                          ),
                          const SizedBox(width: 12),
                          _StatBox(
                            icon: Icons.sports_soccer,
                            label: 'Matches',
                            value: tournament.totalMatches.toString(),
                          ),
                          const SizedBox(width: 12),
                          _StatBox(
                            icon: Icons.check_circle,
                            label: 'Done',
                            value: tournament.completedMatches.toString(),
                          ),
                        ],
                      ),

                      if (tournament.description != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'About',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tournament.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],

                      const SizedBox(height: 20),
                      Text(
                        'Matches',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Matches
              matchesAsync.when(
                loading: () =>
                    const SliverToBoxAdapter(child: ShimmerList(count: 3)),
                error: (e, _) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (matches) => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingM,
                        vertical: 4,
                      ),
                      child: _MatchCard(match: matches[i]),
                    ),
                    childCount: matches.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('${AppRoutes.registrations}?tournamentId=$id'),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.group_add),
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatBox(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reuse match card from matches screen
class _MatchCard extends StatelessWidget {
  final MatchModel match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              match.homeTeamName,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              match.isFinished || match.isLive
                  ? '${match.homeScore} - ${match.awayScore}'
                  : 'vs',
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              match.awayTeamName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
