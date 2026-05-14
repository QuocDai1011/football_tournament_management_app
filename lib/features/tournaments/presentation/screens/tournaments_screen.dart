import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../data/repositories/tournament_repository.dart';
import '../../domain/models/tournament_model.dart';
import '../../../../shared/widgets/loading_states.dart';
import '../../../../shared/widgets/app_image.dart';

class TournamentsScreen extends ConsumerStatefulWidget {
  const TournamentsScreen({super.key});

  @override
  ConsumerState<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends ConsumerState<TournamentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(tournamentsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: AppColors.surface,
            floating: true,
            pinned: true,
            title: const Text('Tournaments'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => context.go(AppRoutes.tournamentCreate),
                tooltip: 'Create Tournament',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search tournaments...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Ongoing'),
                      Tab(text: 'Finished'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        body: tournamentsAsync.when(
          loading: () => const ShimmerList(),
          error: (e, _) => ErrorState(message: e.toString()),
          data: (tournaments) {
            final filtered = _filterTournaments(tournaments);
            return TabBarView(
              controller: _tabController,
              children: [
                _TournamentList(tournaments: filtered),
                _TournamentList(
                  tournaments: filtered
                      .where((t) => t.status == TournamentStatus.ongoing)
                      .toList(),
                ),
                _TournamentList(
                  tournaments: filtered
                      .where((t) => t.status == TournamentStatus.finished)
                      .toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<TournamentModel> _filterTournaments(List<TournamentModel> all) {
    if (_searchQuery.isEmpty) return all;
    return all
        .where((t) =>
            t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }
}

class _TournamentList extends StatelessWidget {
  final List<TournamentModel> tournaments;
  const _TournamentList({required this.tournaments});

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) {
      return const EmptyState(
        title: 'No tournaments found',
        subtitle: 'Create your first tournament to get started',
        icon: Icons.emoji_events_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: tournaments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _TournamentCard(
        tournament: tournaments[i],
      ).animate(delay: (i * 50).ms).fade().slideX(begin: 0.1),
    );
  }
}

class _TournamentCard extends ConsumerWidget {
  final TournamentModel tournament;
  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(tournament.status);

    return GestureDetector(
      onTap: () => context.go('/tournaments/${tournament.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.glassBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            if (tournament.bannerUrl != null)
              AppNetworkImage(
                imageUrl: tournament.bannerUrl,
                height: 100,
                borderRadius: 0,
                fallback: _bannerPlaceholder(),
              )
            else
              _bannerPlaceholder(),

            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tournament.name,
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      _StatusChip(
                        status: tournament.status,
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.category,
                        label: tournament.type.displayName,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.groups,
                        label: '${tournament.maxTeams} teams',
                      ),
                    ],
                  ),
                  if (tournament.totalMatches > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: tournament.progressPercent,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation(statusColor),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${tournament.completedMatches}/${tournament.totalMatches}',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.ongoing:
        return AppColors.success;
      case TournamentStatus.upcoming:
        return AppColors.info;
      case TournamentStatus.finished:
        return AppColors.textTertiary;
    }
  }

  Widget _bannerPlaceholder() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: const Center(
        child: Icon(Icons.emoji_events, size: 40, color: Colors.black54),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TournamentStatus status;
  final Color color;

  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
