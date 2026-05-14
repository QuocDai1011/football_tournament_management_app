import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/match_model.dart';
import '../../data/repositories/match_repository.dart';
import '../../../teams/data/repositories/team_repository.dart';
import '../../../teams/domain/models/team_model.dart';
import '../../../tournaments/data/repositories/tournament_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_image.dart';

class MatchFormScreen extends ConsumerStatefulWidget {
  final String? matchId;
  final String? tournamentId;

  const MatchFormScreen({super.key, this.matchId, this.tournamentId});

  @override
  ConsumerState<MatchFormScreen> createState() => _MatchFormScreenState();
}

class _MatchFormScreenState extends ConsumerState<MatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _venueController = TextEditingController();
  final _groupController = TextEditingController();

  String? _homeTeamId;
  String? _awayTeamId;
  TeamModel? _homeTeam;
  TeamModel? _awayTeam;
  String? _selectedTournamentId;
  MatchType _type = MatchType.groupStage;
  MatchStatus _status = MatchStatus.scheduled;
  DateTime? _scheduledAt;
  int? _round;
  bool _isLoading = false;
  bool _isEditing = false;
  MatchModel? _existing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.matchId != null;
    _selectedTournamentId = widget.tournamentId;
    if (_isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final result =
        await ref.read(matchRepositoryProvider).getMatch(widget.matchId!);
    result.fold(
      (f) {},
      (m) {
        if (!mounted) return;
        setState(() {
          _existing = m;
          _homeTeamId = m.homeTeamId;
          _awayTeamId = m.awayTeamId;
          _selectedTournamentId = m.tournamentId;
          _type = m.type;
          _status = m.status;
          _scheduledAt = m.scheduledAt;
          _venueController.text = m.venue ?? '';
          _groupController.text = m.group ?? '';
          _round = m.round;
        });
      },
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _scheduledAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_homeTeamId == null || _awayTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both teams'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_homeTeamId == _awayTeamId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Home and away teams must be different'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_selectedTournamentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a tournament'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final now = DateTime.now();

    final match = MatchModel(
      id: _existing?.id ?? const Uuid().v4(),
      tournamentId: _selectedTournamentId!,
      homeTeamId: _homeTeamId!,
      homeTeamName: _homeTeam?.name ?? _existing?.homeTeamName ?? '',
      homeTeamLogoUrl: _homeTeam?.logoUrl ?? _existing?.homeTeamLogoUrl,
      awayTeamId: _awayTeamId!,
      awayTeamName: _awayTeam?.name ?? _existing?.awayTeamName ?? '',
      awayTeamLogoUrl: _awayTeam?.logoUrl ?? _existing?.awayTeamLogoUrl,
      homeScore: _existing?.homeScore ?? 0,
      awayScore: _existing?.awayScore ?? 0,
      status: _status,
      type: _type,
      group: _groupController.text.trim().isEmpty
          ? null
          : _groupController.text.trim().toUpperCase(),
      round: _round,
      scheduledAt: _scheduledAt,
      venue: _venueController.text.trim().isEmpty
          ? null
          : _venueController.text.trim(),
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
    );

    final repo = ref.read(matchRepositoryProvider);
    final result = _isEditing
        ? await repo.updateMatch(match)
        : await repo.createMatch(match);

    setState(() => _isLoading = false);

    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message), backgroundColor: AppColors.error),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Match updated!' : 'Match created!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      },
    );
  }

  @override
  void dispose() {
    _venueController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsStreamProvider);
    final tournamentsAsync = ref.watch(tournamentsStreamProvider);
    final fmt = DateFormat('EEE, MMM d • HH:mm');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Match' : 'New Match'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          children: [
            // Tournament selector
            if (widget.tournamentId == null)
              GlassContainer(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tournament',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    tournamentsAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                      data: (tournaments) => DropdownButtonFormField<String>(
                        value: _selectedTournamentId,
                        hint: const Text('Select tournament'),
                        dropdownColor: AppColors.surfaceVariant,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.emoji_events_outlined),
                        ),
                        items: tournaments
                            .map((t) => DropdownMenuItem(
                                value: t.id, child: Text(t.name)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedTournamentId = v),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.tournamentId == null) const SizedBox(height: 16),

            // Teams
            GlassContainer(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Teams',
                      style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  teamsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                    data: (teams) => Column(
                      children: [
                        _TeamDropdown(
                          label: 'Home Team',
                          value: _homeTeamId,
                          teams: teams,
                          onChanged: (id, team) => setState(() {
                            _homeTeamId = id;
                            _homeTeam = team;
                          }),
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'VS',
                            style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _TeamDropdown(
                          label: 'Away Team',
                          value: _awayTeamId,
                          teams: teams,
                          onChanged: (id, team) => setState(() {
                            _awayTeamId = id;
                            _awayTeam = team;
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Match details
            GlassContainer(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Match Details',
                      style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 16),

                  // Match type
                  const Text('Match Type',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MatchType.values.map((t) {
                      final selected = _type == t;
                      return ChoiceChip(
                        label: Text(t.displayName,
                            style: const TextStyle(fontSize: 12)),
                        selected: selected,
                        onSelected: (_) => setState(() => _type = t),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : AppColors.glassBorder,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Group & Round
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _groupController,
                          label: 'Group (optional)',
                          hint: 'A, B, C...',
                          prefixIcon: Icons.grid_view_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Round',
                          hint: '1',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.repeat,
                          initialValue: _round?.toString(),
                          onChanged: (v) =>
                              setState(() => _round = int.tryParse(v)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  AppTextField(
                    controller: _venueController,
                    label: 'Venue (optional)',
                    hint: 'Stadium name',
                    prefixIcon: Icons.stadium_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Date & Time
                  GestureDetector(
                    onTap: () => _pickDateTime(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 20, color: AppColors.textTertiary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Scheduled Date & Time',
                                    style: TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 11)),
                                Text(
                                  _scheduledAt != null
                                      ? fmt.format(_scheduledAt!)
                                      : 'Tap to set',
                                  style: TextStyle(
                                    color: _scheduledAt != null
                                        ? AppColors.textPrimary
                                        : AppColors.textTertiary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textTertiary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            AppButton(
              label: _isEditing ? 'Update Match' : 'Create Match',
              onPressed: _save,
              isLoading: _isLoading,
              icon: _isEditing ? Icons.save : Icons.add,
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<TeamModel> teams;
  final void Function(String id, TeamModel team) onChanged;

  const _TeamDropdown({
    required this.label,
    required this.value,
    required this.teams,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text('Select $label'),
      dropdownColor: AppColors.surfaceVariant,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.groups_outlined),
      ),
      items: teams
          .map((t) => DropdownMenuItem(
                value: t.id,
                child: Row(
                  children: [
                    TeamLogoAvatar(
                        logoUrl: t.logoUrl, teamName: t.name, size: 24),
                    const SizedBox(width: 8),
                    Text(t.name),
                  ],
                ),
              ))
          .toList(),
      onChanged: (id) {
        if (id != null) {
          final team = teams.firstWhere((t) => t.id == id);
          onChanged(id, team);
        }
      },
    );
  }
}
