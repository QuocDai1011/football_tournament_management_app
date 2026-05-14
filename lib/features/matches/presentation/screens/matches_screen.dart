import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../data/repositories/match_repository.dart';
import '../../domain/models/match_model.dart';
import '../../../../shared/widgets/loading_states.dart';
import '../../../../shared/widgets/app_image.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen>
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
    final matchesAsync = ref.watch(allMatchesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go(AppRoutes.matchCreate),
            tooltip: 'Create Match',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scheduled'),
            Tab(text: 'Live'),
            Tab(text: 'Finished'),
          ],
        ),
      ),
      body: matchesAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (matches) => TabBarView(
          controller: _tabController,
          children: [
            _MatchList(
              matches: matches
                  .where((m) => m.status == MatchStatus.scheduled)
                  .toList(),
            ),
            _MatchList(
              matches: matches.where((m) => m.isLive).toList(),
              showLiveBadge: true,
            ),
            _MatchList(
              matches: matches.where((m) => m.isFinished).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  final List<MatchModel> matches;
  final bool showLiveBadge;

  const _MatchList({required this.matches, this.showLiveBadge = false});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return EmptyState(
        title: showLiveBadge ? 'No live matches' : 'No matches',
        icon: Icons.sports_soccer_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _MatchCard(
        match: matches[i],
        showLiveBadge: showLiveBadge,
      ).animate(delay: (i * 40).ms).fade().slideY(begin: 0.05),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchModel match;
  final bool showLiveBadge;

  const _MatchCard({required this.match, this.showLiveBadge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/matches/${match.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color: match.isLive
                ? AppColors.live.withOpacity(0.4)
                : AppColors.glassBorder,
          ),
        ),
        child: Column(
          children: [
            // Match meta info
            Row(
              children: [
                if (match.group != null)
                  Text(
                    'Group ${match.group}',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                const Spacer(),
                if (match.isLive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.live,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${match.minute ?? ''}' LIVE",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else if (match.scheduledAt != null)
                  Text(
                    DateFormat('MMM d • HH:mm').format(match.scheduledAt!),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Teams & Score
            Row(
              children: [
                // Home Team
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          match.homeTeamName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TeamLogoAvatar(
                        logoUrl: match.homeTeamLogoUrl,
                        teamName: match.homeTeamName,
                        size: 32,
                      ),
                    ],
                  ),
                ),
                // Score
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: match.isFinished || match.isLive
                      ? Text(
                          '${match.homeScore}  -  ${match.awayScore}',
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : const Text(
                          'vs',
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 20,
                            color: AppColors.textTertiary,
                          ),
                        ),
                ),
                // Away Team
                Expanded(
                  child: Row(
                    children: [
                      TeamLogoAvatar(
                        logoUrl: match.awayTeamLogoUrl,
                        teamName: match.awayTeamName,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          match.awayTeamName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (match.venue != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    match.venue!,
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
    );
  }
}
