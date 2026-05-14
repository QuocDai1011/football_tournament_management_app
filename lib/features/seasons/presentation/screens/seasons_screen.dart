import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/season_repository.dart';
import '../../domain/models/season_model.dart';
import '../../../../shared/widgets/loading_states.dart';
import '../../../../shared/widgets/glass_container.dart';
import 'season_form_screen.dart';

class SeasonsScreen extends ConsumerWidget {
  final String? tournamentId;
  const SeasonsScreen({super.key, this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonsAsync = ref.watch(seasonsStreamProvider(tournamentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seasons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showSeasonForm(context, ref),
            tooltip: 'Add Season',
          ),
        ],
      ),
      body: seasonsAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (seasons) {
          if (seasons.isEmpty) {
            return EmptyState(
              title: 'No seasons yet',
              subtitle: 'Create a season to start managing your tournament',
              icon: Icons.calendar_today_outlined,
              onAction: () => _showSeasonForm(context, ref),
              actionLabel: 'Create Season',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: seasons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _SeasonCard(
              season: seasons[i],
              onEdit: () => _showSeasonForm(context, ref, season: seasons[i]),
              onDelete: () => _confirmDelete(context, ref, seasons[i]),
            ).animate(delay: (i * 50).ms).fade().slideY(begin: 0.1),
          );
        },
      ),
    );
  }

  void _showSeasonForm(BuildContext context, WidgetRef ref,
      {SeasonModel? season}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SeasonFormSheet(
        tournamentId: tournamentId ?? '',
        existing: season,
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, SeasonModel season) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: const Text('Delete Season'),
        content: Text('Delete "${season.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(seasonNotifierProvider.notifier).delete(season.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SeasonCard extends StatelessWidget {
  final SeasonModel season;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SeasonCard({
    required this.season,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(season.status);
    final fmt = DateFormat('MMM d, yyyy');

    return GlassContainer(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  season.name,
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusRound),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  season.status.displayName,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                color: AppColors.surfaceVariant,
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textTertiary, size: 20),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                '${fmt.format(season.startDate)} – ${fmt.format(season.endDate)}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          if (season.registrationDeadline != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: season.isRegistrationOpen
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: 6),
                Text(
                  'Registration: ${fmt.format(season.registrationDeadline!)}',
                  style: TextStyle(
                    color: season.isRegistrationOpen
                        ? AppColors.success
                        : AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.groups, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                '${season.registeredTeams}/${season.maxTeams} teams',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: season.maxTeams > 0
                      ? season.registeredTeams / season.maxTeams
                      : 0,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(SeasonStatus status) {
    switch (status) {
      case SeasonStatus.upcoming:
        return AppColors.info;
      case SeasonStatus.active:
        return AppColors.success;
      case SeasonStatus.finished:
        return AppColors.textTertiary;
    }
  }
}
