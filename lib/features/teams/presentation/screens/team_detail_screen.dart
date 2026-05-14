// Team detail screen stub - full implementation
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../data/repositories/team_repository.dart';
import '../../domain/models/team_model.dart';
import '../../../players/data/repositories/player_repository.dart';
import '../../../players/domain/models/player_model.dart';
import '../../../../shared/widgets/loading_states.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';

class TeamDetailScreen extends ConsumerWidget {
  final String id;
  const TeamDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailProvider(id));
    final playersAsync = ref.watch(playersByTeamProvider(id));

    return teamAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: ErrorState(message: e.toString())),
      data: (team) {
        if (team == null)
          return const Scaffold(body: EmptyState(title: 'Team not found'));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: AppColors.surface,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(team.name,
                      style: const TextStyle(
                          fontFamily: 'Rajdhani', fontWeight: FontWeight.w700)),
                  background: Container(
                    decoration: BoxDecoration(
                      color: team.homeColor != null
                          ? Color(int.parse(
                              'FF${team.homeColor!.replaceAll('#', '')}',
                              radix: 16))
                          : null,
                      gradient: team.homeColor == null
                          ? AppColors.primaryGradient
                          : null,
                    ),
                    child: Center(
                      child: TeamLogoAvatar(
                          logoUrl: team.logoUrl, teamName: team.name, size: 72),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => context.go('/teams/$id/edit')),
                  IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => _showDeleteDialog(context, ref, team)),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats
                      Row(
                        children: [
                          _StatBox('W', team.wins.toString()),
                          const SizedBox(width: 8),
                          _StatBox('D', team.draws.toString()),
                          const SizedBox(width: 8),
                          _StatBox('L', team.losses.toString()),
                          const SizedBox(width: 8),
                          _StatBox('GF', team.goalsFor.toString()),
                          const SizedBox(width: 8),
                          _StatBox('GA', team.goalsAgainst.toString()),
                        ],
                      ),
                      if (team.coach != null) ...[
                        const SizedBox(height: 16),
                        _InfoRow(
                            icon: Icons.sports,
                            label: 'Coach',
                            value: team.coach!),
                      ],
                      if (team.city != null)
                        _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'City',
                            value: team.city!),
                      const SizedBox(height: 20),
                      const Text('Squad',
                          style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              // Players
              playersAsync.when(
                loading: () =>
                    const SliverToBoxAdapter(child: ShimmerList(count: 5)),
                error: (e, _) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (players) => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = players[i];
                      return ListTile(
                        leading: PlayerAvatar(
                            avatarUrl: p.avatarUrl,
                            playerName: p.name,
                            size: 40),
                        title: Text(p.name,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(p.position.displayName,
                            style: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 12)),
                        trailing: Text('#${p.shirtNumber}',
                            style: const TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 18,
                                color: AppColors.textSecondary)),
                        onTap: () => context.go('/players/${p.id}'),
                      );
                    },
                    childCount: players.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('${AppRoutes.playerCreate}?teamId=$id'),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.person_add),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, TeamModel team) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDeleteDialog(
        itemName: team.name,
        itemType: 'team',
        onConfirm: () async {
          final result = await ref.read(teamRepositoryProvider).deleteTeam(team.id);
          result.fold(
            (l) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${l.message}')),
            ),
            (r) {
              context.go(AppRoutes.teams);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Team deleted successfully')),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox(this.label, this.value);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 10)),
            ],
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Text('$label: ',
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
