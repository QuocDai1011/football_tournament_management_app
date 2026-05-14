import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/player_repository.dart';
import '../../domain/models/player_model.dart';
import '../../../../shared/widgets/loading_states.dart';
import '../../../../shared/widgets/app_image.dart';

class PlayerDetailScreen extends ConsumerWidget {
  final String id;
  const PlayerDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerDetailProvider(id));

    return playerAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: ErrorState(message: e.toString())),
      data: (player) {
        if (player == null)
          return const Scaffold(body: EmptyState(title: 'Player not found'));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.surface,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(player.name,
                      style: const TextStyle(
                          fontFamily: 'Rajdhani', fontWeight: FontWeight.w700)),
                  background: Container(
                    decoration:
                        const BoxDecoration(gradient: AppColors.darkGradient),
                    child: Center(
                      child: PlayerAvatar(
                          avatarUrl: player.avatarUrl,
                          playerName: player.name,
                          size: 90),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => context.go('/players/$id/edit')),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Position & Number
                      Row(
                        children: [
                          _PositionBadge(player.position),
                          const SizedBox(width: 12),
                          if (player.isCaptain)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusRound),
                                border: Border.all(
                                    color: AppColors.accent.withOpacity(0.4)),
                              ),
                              child: const Text('Captain',
                                  style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          const Spacer(),
                          Text('#${player.shirtNumber}',
                              style: const TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (player.teamName != null)
                        Text(player.teamName!,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      const SizedBox(height: 20),

                      // Stats grid
                      const Text('Statistics',
                          style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.4,
                        children: [
                          _StatCard('Apps', player.appearances.toString(),
                              Icons.sports_soccer),
                          _StatCard('Goals', player.goals.toString(),
                              Icons.sports_soccer_outlined),
                          _StatCard('Assists', player.assists.toString(),
                              Icons.handshake_outlined),
                          _StatCard('Yellow', player.yellowCards.toString(),
                              Icons.square,
                              color: AppColors.yellowCard),
                          _StatCard(
                              'Red', player.redCards.toString(), Icons.square,
                              color: AppColors.redCard),
                          if (player.position == PlayerPosition.gk)
                            _StatCard('Clean', player.cleanSheets.toString(),
                                Icons.shield_outlined),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Personal info
                      const Text('Info',
                          style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      if (player.age != null)
                        _InfoRow('Age', '${player.age} years'),
                      if (player.nationality != null)
                        _InfoRow('Nationality', player.nationality!),
                      if (player.height != null)
                        _InfoRow('Height', '${player.height} cm'),
                      if (player.weight != null)
                        _InfoRow('Weight', '${player.weight} kg'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final PlayerPosition pos;
  const _PositionBadge(this.pos);

  Color get color {
    switch (pos) {
      case PlayerPosition.gk:
        return AppColors.warning;
      case PlayerPosition.df:
        return AppColors.info;
      case PlayerPosition.mf:
        return AppColors.success;
      case PlayerPosition.fw:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          pos.displayName,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const _StatCard(this.label, this.value, this.icon, {this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color ?? AppColors.textTertiary),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color ?? AppColors.primary)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 10)),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text('$label: ',
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 14)),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
