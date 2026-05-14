import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/models/player_model.dart';
import '../../data/repositories/player_repository.dart';
import '../../../teams/data/repositories/team_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_container.dart';

class PlayerFormScreen extends ConsumerStatefulWidget {
  final String? playerId;
  final String? initialTeamId;
  const PlayerFormScreen({super.key, this.playerId, this.initialTeamId});

  @override
  ConsumerState<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends ConsumerState<PlayerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shirtController = TextEditingController(text: '10');
  PlayerPosition _position = PlayerPosition.fw;
  bool _isCaptain = false;
  String? _selectedTeamId;
  bool _isLoading = false;
  bool _isEditing = false;
  PlayerModel? _existing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.playerId != null;
    _selectedTeamId = widget.initialTeamId;
    if (_isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final result = await ref.read(playerRepositoryProvider).getPlayer(widget.playerId!);
    result.fold(
      (f) {},
      (p) {
        if (!mounted) return;
        setState(() {
          _existing = p;
          _nameController.text = p.name;
          _shirtController.text = p.shirtNumber.toString();
          _position = p.position;
          _isCaptain = p.isCaptain;
          _selectedTeamId = p.teamId;
        });
      },
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a team'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    final notifier = ref.read(playerNotifierProvider.notifier);
    final now = DateTime.now();

    final player = _existing?.copyWith(
      name: _nameController.text.trim(),
      teamId: _selectedTeamId!,
      position: _position,
      shirtNumber: int.tryParse(_shirtController.text) ?? 10,
      isCaptain: _isCaptain,
      updatedAt: now,
    ) ?? PlayerModel(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      teamId: _selectedTeamId!,
      position: _position,
      shirtNumber: int.tryParse(_shirtController.text) ?? 10,
      isCaptain: _isCaptain,
      createdAt: now,
      updatedAt: now,
    );

    final result = _isEditing
        ? await notifier.update(player)
        : await notifier.create(player);

    setState(() => _isLoading = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.error)),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Player updated!' : 'Player added!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.players);
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shirtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_isEditing ? 'Edit Player' : 'Add Player')),
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
                  AppTextField(
                    controller: _nameController,
                    label: 'Player Name',
                    prefixIcon: Icons.person_outlined,
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _shirtController,
                    label: 'Shirt Number',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.tag,
                  ),
                  const SizedBox(height: 16),

                  // Team selector
                  const Text('Team', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  teamsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error loading teams'),
                    data: (teams) => DropdownButtonFormField<String>(
                      value: _selectedTeamId,
                      hint: const Text('Select team'),
                      dropdownColor: AppColors.surfaceVariant,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      items: teams
                          .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedTeamId = v),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Position', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: PlayerPosition.values.map((pos) {
                      final selected = _position == pos;
                      return ChoiceChip(
                        label: Text(pos.abbreviation),
                        selected: selected,
                        onSelected: (_) => setState(() => _position = pos),
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        side: BorderSide(color: selected ? AppColors.primary : AppColors.glassBorder),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Switch(value: _isCaptain, onChanged: (v) => setState(() => _isCaptain = v)),
                      const SizedBox(width: 8),
                      const Text('Captain', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _isEditing ? 'Update Player' : 'Add Player',
              onPressed: _save,
              isLoading: _isLoading,
              icon: _isEditing ? Icons.save : Icons.person_add,
            ),
          ],
        ),
      ),
    );
  }
}
