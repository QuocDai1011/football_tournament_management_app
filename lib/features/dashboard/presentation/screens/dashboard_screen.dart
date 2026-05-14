import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/dashboard_providers.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/tournament_section.dart';
import '../widgets/teams_section.dart';
import '../widgets/players_section.dart';
import '../widgets/live_matches_section.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {
      _currentTabIndex = _tabController.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and sync indicator
                _buildHeader(context),
                SizedBox(height: isMobile ? 24 : 32),

                // Dashboard Statistics Cards
                _buildStatisticsSection(context),
                SizedBox(height: isMobile ? 28 : 40),

                // Main sections with tabs
                _buildMainSections(context, isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Football Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Realtime tournament & match updates',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            // Sync indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.success, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Live',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    return ref.watch(dashboardStatsProvider).when(
          data: (stats) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Stats',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      DashboardStatCard(
                        icon: Icons.sports_soccer,
                        title: 'Tournaments',
                        value: stats.totalTournaments,
                        subtitle: '${stats.activeTournaments} active',
                        color: const Color(0xFF00D4AA),
                      ),
                      const SizedBox(width: 12),
                      DashboardStatCard(
                        icon: Icons.groups,
                        title: 'Teams',
                        value: stats.totalTeams,
                        subtitle: 'Total teams',
                        color: const Color(0xFFFF6B35),
                      ),
                      const SizedBox(width: 12),
                      DashboardStatCard(
                        icon: Icons.person,
                        title: 'Players',
                        value: stats.totalPlayers,
                        subtitle: 'All players',
                        color: const Color(0xFFFFD700),
                      ),
                      const SizedBox(width: 12),
                      DashboardStatCard(
                        icon: Icons.local_fire_department,
                        title: 'Live Matches',
                        value: stats.liveMatches,
                        subtitle: 'In progress',
                        color: const Color(0xFFFF1744),
                        isHighlight: stats.liveMatches > 0,
                      ),
                      const SizedBox(width: 12),
                      DashboardStatCard(
                        icon: Icons.calendar_today,
                        title: "Today's Matches",
                        value: stats.todayMatches,
                        subtitle: 'Scheduled',
                        color: const Color(0xFF2979FF),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Stats',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    5,
                    (index) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildStatCardSkeleton(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          error: (error, st) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(color: AppColors.error),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to load dashboard stats',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildStatCardSkeleton() {
    return Container(
      width: 140,
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 80,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainSections(BuildContext context, bool isMobile) {
    return Column(
      children: [
        // Tab navigation
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Tournaments'),
              Tab(text: 'Teams'),
              Tab(text: 'Players'),
              Tab(text: 'Live Matches'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Tab content
        SizedBox(
          height: _getTabContentHeight(context, isMobile),
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tournaments Section
              const TournamentSection(),

              // Teams Section
              const TeamsSection(),

              // Players Section
              const PlayersSection(),

              // Live Matches Section
              const LiveMatchesSection(),
            ],
          ),
        ),
      ],
    );
  }

  double _getTabContentHeight(BuildContext context, bool isMobile) {
    if (isMobile) {
      return MediaQuery.of(context).size.height * 0.6;
    }
    return 600;
  }
}
