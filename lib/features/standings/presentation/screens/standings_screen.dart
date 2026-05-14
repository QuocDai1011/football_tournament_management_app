import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../matches/data/repositories/match_repository.dart';
import '../../../tournaments/data/repositories/tournament_repository.dart';
import '../../../tournaments/domain/models/tournament_model.dart';
import '../../domain/models/standing_model.dart';
import '../../../../core/algorithms/standings_engine.dart';
import '../../../../shared/widgets/loading_states.dart';
import '../../../../shared/widgets/app_image.dart';

class StandingsScreen extends ConsumerStatefulWidget {
  const StandingsScreen({super.key});

  @override
  ConsumerState<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends ConsumerState<StandingsScreen> {
  String? _selectedTournamentId;

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(tournamentsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Standings')),
      body: tournamentsAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (tournaments) {
          if (tournaments.isEmpty) {
            return const EmptyState(
              title: 'No tournaments',
              subtitle: 'Create a tournament to see standings',
              icon: Icons.format_list_numbered_outlined,
            );
          }

          _selectedTournamentId ??= tournaments.first.id;
          final selected = tournaments.firstWhere(
            (t) => t.id == _selectedTournamentId,
            orElse: () => tournaments.first,
          );

          return Column(
            children: [
              // Tournament selector
              _TournamentSelector(
                tournaments: tournaments,
                selected: _selectedTournamentId!,
                onChanged: (id) =>
                    setState(() => _selectedTournamentId = id),
              ),
              Expanded(
                child: _StandingsTable(
                  tournamentId: _selectedTournamentId!,
                  scoring: selected.scoringSystem,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TournamentSelector extends StatelessWidget {
  final List<TournamentModel> tournaments;
  final String selected;
  final ValueChanged<String> onChanged;

  const _TournamentSelector({
    required this.tournaments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: tournaments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final t = tournaments[i];
          final isSelected = t.id == selected;
          return FilterChip(
            label: Text(t.name),
            selected: isSelected,
            onSelected: (_) => onChanged(t.id),
            selectedColor: AppColors.primary.withOpacity(0.2),
            checkmarkColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.glassBorder,
            ),
          );
        },
      ),
    );
  }
}

class _StandingsTable extends ConsumerWidget {
  final String tournamentId;
  final ScoringSystem scoring;

  const _StandingsTable({
    required this.tournamentId,
    required this.scoring,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesStreamProvider(tournamentId));

    return matchesAsync.when(
      loading: () => const ShimmerList(),
      error: (e, _) => ErrorState(message: e.toString()),
      data: (matches) {
        final standings = StandingsEngine.calculate(
          tournamentId: tournamentId,
          matches: matches,
          scoring: scoring,
        );

        if (standings.isEmpty) {
          return const EmptyState(
            title: 'No standings yet',
            subtitle: 'Standings will appear after matches are played',
            icon: Icons.format_list_numbered_outlined,
          );
        }

        return Column(
          children: [
            // Header row
            _TableHeader(),
            // Standing rows
            Expanded(
              child: ListView.builder(
                itemCount: standings.length,
                itemBuilder: (context, i) =>
                    _StandingRow(standing: standings[i])
                        .animate(delay: (i * 40).ms)
                        .fade()
                        .slideX(begin: 0.05),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: 8,
      ),
      color: AppColors.surface,
      child: const Row(
        children: [
          SizedBox(width: 32, child: Text('#', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))),
          Expanded(child: Text('Team', style: TextStyle(color: AppColors.textTertiary, fontSize: 11))),
          _HeaderCell('P'),
          _HeaderCell('W'),
          _HeaderCell('D'),
          _HeaderCell('L'),
          _HeaderCell('GF'),
          _HeaderCell('GA'),
          _HeaderCell('GD'),
          _HeaderCell('Pts'),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final StandingModel standing;
  const _StandingRow({required this.standing});

  @override
  Widget build(BuildContext context) {
    final isTop3 = standing.position <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isTop3 ? AppColors.primary.withOpacity(0.04) : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              standing.position.toString(),
              style: TextStyle(
                color: standing.position == 1
                    ? AppColors.accent
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontFamily: 'Rajdhani',
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                TeamLogoAvatar(
                  logoUrl: standing.teamLogoUrl,
                  teamName: standing.teamName,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    standing.teamName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _DataCell(standing.played.toString()),
          _DataCell(standing.won.toString()),
          _DataCell(standing.drawn.toString()),
          _DataCell(standing.lost.toString()),
          _DataCell(standing.goalsFor.toString()),
          _DataCell(standing.goalsAgainst.toString()),
          _DataCell(
            '${standing.goalDifference >= 0 ? '+' : ''}${standing.goalDifference}',
            color: standing.goalDifference >= 0
                ? AppColors.success
                : AppColors.error,
          ),
          _DataCell(
            standing.points.toString(),
            color: AppColors.primary,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final Color? color;
  final bool bold;

  const _DataCell(this.text, {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        text,
        style: TextStyle(
          color: color ?? AppColors.textSecondary,
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          fontFamily: bold ? 'Rajdhani' : null,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
