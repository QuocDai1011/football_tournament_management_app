import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/models/tournament_model.dart';
import '../../data/repositories/tournament_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_container.dart';

class TournamentFormScreen extends ConsumerStatefulWidget {
  final String? tournamentId;
  const TournamentFormScreen({super.key, this.tournamentId});

  @override
  ConsumerState<TournamentFormScreen> createState() =>
      _TournamentFormScreenState();
}

class _TournamentFormScreenState extends ConsumerState<TournamentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();
  final _maxTeamsController = TextEditingController(text: '16');

  TournamentType _type = TournamentType.league;
  TournamentStatus _status = TournamentStatus.upcoming;
  int _pointsWin = 3;
  int _pointsDraw = 1;
  int _pointsLoss = 0;
  bool _isLoading = false;
  bool _isEditing = false;
  TournamentModel? _existing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.tournamentId != null;
    if (_isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final result = await ref
        .read(tournamentRepositoryProvider)
        .getTournament(widget.tournamentId!);
    result.fold(
      (f) => _showError(f.message),
      (t) {
        if (!mounted) return;
        setState(() {
          _existing = t;
          _nameController.text = t.name;
          _descriptionController.text = t.description ?? '';
          _rulesController.text = t.rules ?? '';
          _maxTeamsController.text = t.maxTeams.toString();
          _type = t.type;
          _status = t.status;
          _pointsWin = t.scoringSystem.win;
          _pointsDraw = t.scoringSystem.draw;
          _pointsLoss = t.scoringSystem.loss;
        });
      },
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final notifier = ref.read(tournamentNotifierProvider.notifier);
    final now = DateTime.now();

    final tournament = TournamentModel(
      id: _existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      rules: _rulesController.text.trim().isEmpty
          ? null
          : _rulesController.text.trim(),
      type: _type,
      status: _status,
      maxTeams: int.tryParse(_maxTeamsController.text) ?? 16,
      scoringSystem: ScoringSystem(
        win: _pointsWin,
        draw: _pointsDraw,
        loss: _pointsLoss,
      ),
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
    );

    final Either result = _isEditing
        ? await notifier.update(tournament)
        : await notifier.create(tournament);

    setState(() => _isLoading = false);

    result.fold(
      (f) => _showError(f.message),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditing ? 'Tournament updated!' : 'Tournament created!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.tournaments);
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    _maxTeamsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Tournament' : 'New Tournament'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Basic Info',
                      style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _nameController,
                    label: 'Tournament Name',
                    hint: 'Premier League 2025',
                    prefixIcon: Icons.emoji_events_outlined,
                    validator: (v) =>
                        v?.isEmpty == true ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _descriptionController,
                    label: 'Description (optional)',
                    hint: 'Tournament description...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _maxTeamsController,
                    label: 'Max Teams',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.groups_outlined,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 2) return 'Enter at least 2';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Type & Status
            GlassContainer(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Format',
                      style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  const Text('Tournament Type',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: TournamentType.values.map((t) {
                      final selected = _type == t;
                      return ChoiceChip(
                        label: Text(t.displayName),
                        selected: selected,
                        onSelected: (_) => setState(() => _type = t),
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
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
                  const Text('Status',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: TournamentStatus.values.map((s) {
                      final selected = _status == s;
                      return ChoiceChip(
                        label: Text(s.displayName),
                        selected: selected,
                        onSelected: (_) => setState(() => _status = s),
                        selectedColor: AppColors.primary.withOpacity(0.2),
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scoring
            GlassContainer(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scoring System',
                      style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _PointsInput(
                        label: 'Win',
                        value: _pointsWin,
                        onChanged: (v) => setState(() => _pointsWin = v),
                      ),
                      const SizedBox(width: 12),
                      _PointsInput(
                        label: 'Draw',
                        value: _pointsDraw,
                        onChanged: (v) => setState(() => _pointsDraw = v),
                      ),
                      const SizedBox(width: 12),
                      _PointsInput(
                        label: 'Loss',
                        value: _pointsLoss,
                        onChanged: (v) => setState(() => _pointsLoss = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            AppButton(
              label: _isEditing ? 'Update Tournament' : 'Create Tournament',
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

class _PointsInput extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _PointsInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove, size: 18),
                visualDensity: VisualDensity.compact,
              ),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                onPressed: () => onChanged(value + 1),
                icon: const Icon(Icons.add, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
