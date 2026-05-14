import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../data/repositories/player_repository.dart';
import '../../domain/models/player_model.dart';
import '../../../../shared/widgets/loading_states.dart';
import '../../../../shared/widgets/app_image.dart';

class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({super.key});

  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends ConsumerState<PlayersScreen> {
  String _searchQuery = '';
  PlayerPosition? _positionFilter;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Players'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go(AppRoutes.playerCreate),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(106),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search players...',
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Position filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _positionFilter == null,
                      onSelected: (_) =>
                          setState(() => _positionFilter = null),
                    ),
                    const SizedBox(width: 8),
                    ...PlayerPosition.values.map(
                      (pos) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: pos.abbreviation,
                          selected: _positionFilter == pos,
                          onSelected: (_) =>
                              setState(() => _positionFilter = pos),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: playersAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (players) {
          var filtered = players;
          if (_searchQuery.isNotEmpty) {
            filtered = filtered
                .where((p) =>
                    p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();
          }
          if (_positionFilter != null) {
            filtered = filtered
                .where((p) => p.position == _positionFilter)
                .toList();
          }

          if (filtered.isEmpty) {
            return const EmptyState(
              title: 'No players found',
              subtitle: 'Add players to your teams',
              icon: Icons.person_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _PlayerRow(player: filtered[i])
                .animate(delay: (i * 30).ms)
                .fade()
                .slideX(begin: 0.05),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 12,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.glassBorder,
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final PlayerModel player;
  const _PlayerRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/players/${player.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            PlayerAvatar(
              avatarUrl: player.avatarUrl,
              playerName: player.name,
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (player.isCaptain)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'C',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    player.teamName ?? 'No Team',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Position badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _positionColor(player.position).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _positionColor(player.position).withOpacity(0.4),
                ),
              ),
              child: Center(
                child: Text(
                  player.position.abbreviation,
                  style: TextStyle(
                    color: _positionColor(player.position),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Shirt number
            Text(
              '#${player.shirtNumber}',
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _positionColor(PlayerPosition pos) {
    switch (pos) {
      case PlayerPosition.gk: return AppColors.warning;
      case PlayerPosition.df: return AppColors.info;
      case PlayerPosition.mf: return AppColors.success;
      case PlayerPosition.fw: return AppColors.secondary;
    }
  }
}
