import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/match_repository.dart';
import '../../domain/models/match_model.dart';
import '../../../../shared/widgets/loading_states.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';

class MatchDetailScreen extends ConsumerWidget {
  final String id;
  const MatchDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider(id));
    final eventsAsync = ref.watch(matchEventsProvider(id));

    return matchAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: ErrorState(message: e.toString())),
      data: (match) {
        if (match == null)
          return const Scaffold(body: EmptyState(title: 'Match not found'));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // Score header
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.surface,
                flexibleSpace: FlexibleSpaceBar(
                  background: _ScoreHeader(match: match),
                ),
                actions: [
                  if (!match.isFinished)
                    TextButton(
                      onPressed: (!match.isLive && match.scheduledAt != null && DateTime.now().isBefore(match.scheduledAt!))
                          ? null
                          : () => _handleMatchControl(context, ref, match),
                      child: Text(
                        match.isLive ? 'End Match' : 'Start',
                        style: TextStyle(
                            color: (!match.isLive && match.scheduledAt != null && DateTime.now().isBefore(match.scheduledAt!))
                                ? AppColors.textTertiary
                                : AppColors.primary,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _showDeleteDialog(context, ref, match),
                  ),
                ],
              ),

              // Events timeline
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Match Events',
                              style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          const Spacer(),
                          if (match.isLive)
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _showAddEventDialog(context, ref, match),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Event'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              eventsAsync.when(
                loading: () =>
                    const SliverToBoxAdapter(child: ShimmerList(count: 3)),
                error: (e, _) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (events) {
                  if (events.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: EmptyState(
                        title: 'No events yet',
                        subtitle: 'Events will appear as the match progresses',
                        icon: Icons.sports_soccer_outlined,
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _EventRow(event: events[i], match: match),
                      childCount: events.length,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleMatchControl(
      BuildContext context, WidgetRef ref, MatchModel match) async {
    final repo = ref.read(matchRepositoryProvider);
    if (match.isLive) {
      await repo.finishMatch(match.id, match.homeScore, match.awayScore);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Match finished!')));
    } else {
      await repo.startMatch(match.id);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Match started!')));
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, MatchModel match) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDeleteDialog(
        itemName: '${match.homeTeamName} vs ${match.awayTeamName}',
        itemType: 'match',
        onConfirm: () async {
          final result = await ref.read(matchRepositoryProvider).deleteMatch(match.id);
          result.fold(
            (l) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${l.message}')),
            ),
            (r) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Match deleted successfully')),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddEventDialog(
      BuildContext context, WidgetRef ref, MatchModel match) {
    showDialog(
      context: context,
      builder: (_) => _AddEventDialog(match: match, ref: ref),
    );
  }
}

class _ScoreHeader extends StatefulWidget {
  final MatchModel match;
  const _ScoreHeader({required this.match});

  @override
  State<_ScoreHeader> createState() => _ScoreHeaderState();
}

class _ScoreHeaderState extends State<_ScoreHeader> {
  Timer? _timer;
  int _currentMinute = 0;

  @override
  void initState() {
    super.initState();
    _updateMinute();
    if (widget.match.isLive) {
      _timer = Timer.periodic(const Duration(seconds: 10), (_) => _updateMinute());
    }
  }

  @override
  void didUpdateWidget(_ScoreHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMinute();
    if (widget.match.isLive && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 10), (_) => _updateMinute());
    } else if (!widget.match.isLive) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _updateMinute() {
    if (!mounted) return;
    if (widget.match.isLive && widget.match.startedAt != null) {
      final diff = DateTime.now().difference(widget.match.startedAt!).inMinutes;
      setState(() {
        _currentMinute = diff;
      });
    } else {
      if (mounted) {
        setState(() {
          _currentMinute = widget.match.minute ?? 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.darkGradient),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: match.isLive
                  ? AppColors.live.withOpacity(0.2)
                  : AppColors.textTertiary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              border: Border.all(
                color: match.isLive
                    ? AppColors.live.withOpacity(0.5)
                    : AppColors.glassBorder,
              ),
            ),
            child: Text(
              match.isLive
                  ? "$_currentMinute' LIVE"
                  : match.status.displayName.toUpperCase(),
              style: TextStyle(
                color: match.isLive ? AppColors.live : AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  children: [
                    TeamLogoAvatar(
                        logoUrl: match.homeTeamLogoUrl,
                        teamName: match.homeTeamName,
                        size: 48),
                    const SizedBox(height: 8),
                    Text(match.homeTeamName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              Text(
                match.isFinished || match.isLive
                    ? '${match.homeScore}  :  ${match.awayScore}'
                    : 'VS',
                style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              Expanded(
                child: Column(
                  children: [
                    TeamLogoAvatar(
                        logoUrl: match.awayTeamLogoUrl,
                        teamName: match.awayTeamName,
                        size: 48),
                    const SizedBox(height: 8),
                    Text(match.awayTeamName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (match.scheduledAt != null)
            Text(
              DateFormat('EEE, MMM d • HH:mm').format(match.scheduledAt!),
              style:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final MatchEvent event;
  final MatchModel match;
  const _EventRow({required this.event, required this.match});

  @override
  Widget build(BuildContext context) {
    final isHome = event.isHomeTeam;
    final icon = _eventIcon(event.type);
    final color = _eventColor(event.type);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM, vertical: 4),
      child: Row(
        children: [
          // Home side
          Expanded(
            child: isHome
                ? Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(event.playerName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    if (event.assistPlayerName != null)
                      Text('Assist: ${event.assistPlayerName}',
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 11)),
                  ])
                : const SizedBox.shrink(),
          ),
          // Center: minute & icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${event.minute}'",
                    style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontFamily: 'Rajdhani')),
                const SizedBox(width: 6),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
          ),
          // Away side
          Expanded(
            child: !isHome
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(event.playerName,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        if (event.assistPlayerName != null)
                          Text('Assist: ${event.assistPlayerName}',
                              style: const TextStyle(
                                  color: AppColors.textTertiary, fontSize: 11)),
                      ])
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  IconData _eventIcon(MatchEventType type) {
    switch (type) {
      case MatchEventType.goal:
        return Icons.sports_soccer;
      case MatchEventType.ownGoal:
        return Icons.sports_soccer;
      case MatchEventType.penalty:
        return Icons.sports_soccer;
      case MatchEventType.yellowCard:
        return Icons.square;
      case MatchEventType.redCard:
        return Icons.square;
      case MatchEventType.substitution:
        return Icons.swap_horiz;
    }
  }

  Color _eventColor(MatchEventType type) {
    switch (type) {
      case MatchEventType.goal:
        return AppColors.goal;
      case MatchEventType.ownGoal:
        return AppColors.error;
      case MatchEventType.penalty:
        return AppColors.success;
      case MatchEventType.yellowCard:
        return AppColors.yellowCard;
      case MatchEventType.redCard:
        return AppColors.redCard;
      case MatchEventType.substitution:
        return AppColors.info;
    }
  }
}

class _AddEventDialog extends StatefulWidget {
  final MatchModel match;
  final WidgetRef ref;
  const _AddEventDialog({required this.match, required this.ref});

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  MatchEventType _type = MatchEventType.goal;
  final _playerController = TextEditingController();
  final _minuteController = TextEditingController(text: '1');
  bool _isHome = true;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceVariant,
      title: const Text('Add Match Event',
          style:
              TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<MatchEventType>(
            value: _type,
            dropdownColor: AppColors.surfaceVariant,
            decoration: const InputDecoration(labelText: 'Event Type'),
            items: MatchEventType.values
                .map((t) =>
                    DropdownMenuItem(value: t, child: Text(t.displayName)))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _playerController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Player Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _minuteController,
            style: const TextStyle(color: AppColors.textPrimary),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Minute'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Team: ',
                  style: TextStyle(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () => setState(() => _isHome = true),
                child: Text(
                  widget.match.homeTeamName,
                  style: TextStyle(
                      color:
                          _isHome ? AppColors.primary : AppColors.textTertiary,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const Text(' / '),
              TextButton(
                onPressed: () => setState(() => _isHome = false),
                child: Text(
                  widget.match.awayTeamName,
                  style: TextStyle(
                      color:
                          !_isHome ? AppColors.primary : AppColors.textTertiary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_playerController.text.isEmpty) return;
    setState(() => _isSaving = true);

    final event = MatchEvent(
      id: '',
      matchId: widget.match.id,
      type: _type,
      minute: int.tryParse(_minuteController.text) ?? 1,
      teamId: _isHome ? widget.match.homeTeamId : widget.match.awayTeamId,
      playerId: 'unknown',
      playerName: _playerController.text.trim(),
      isHomeTeam: _isHome,
      createdAt: DateTime.now(),
    );

    await widget.ref.read(matchRepositoryProvider).addMatchEvent(event);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _playerController.dispose();
    _minuteController.dispose();
    super.dispose();
  }
}
