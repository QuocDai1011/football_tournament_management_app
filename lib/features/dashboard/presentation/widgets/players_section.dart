import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/dashboard_providers.dart';
import '../../../players/domain/models/player_model.dart';
import 'player_card.dart';

class PlayersSection extends ConsumerStatefulWidget {
  const PlayersSection({super.key});

  @override
  ConsumerState<PlayersSection> createState() => _PlayersSectionState();
}

class _PlayersSectionState extends ConsumerState<PlayersSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search players...',
              hintStyle: TextStyle(color: AppColors.textTertiary),
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
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

        // Players list
        Expanded(
          child: ref.watch(allPlayersStreamProvider).when(
                data: (players) {
                  final filteredPlayers = _filterPlayers(players);

                  if (filteredPlayers.isEmpty) {
                    return _buildEmptyState(context, _searchQuery.isNotEmpty);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filteredPlayers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return PlayerCard(player: filteredPlayers[index]);
                    },
                  );
                },
                loading: () => ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, __) => _buildPlayerCardSkeleton(),
                ),
                error: (error, st) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Flexible(
                        child: Text(
                          'Failed to load players',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ],
    );
  }

  List<PlayerModel> _filterPlayers(List<PlayerModel> players) {
    if (_searchQuery.isEmpty) {
      return players;
    }

    return players
        .where((player) =>
            player.name.toLowerCase().contains(_searchQuery) ||
            (player.teamName?.toLowerCase().contains(_searchQuery) ?? false) ||
            player.position.displayName.toLowerCase().contains(_searchQuery))
        .toList();
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.person,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No players found' : 'No players registered',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          // Avatar skeleton
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(width: 12),
          // Info skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
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
          ),
          // Stats skeleton
          Container(
            width: 40,
            height: 12,
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
