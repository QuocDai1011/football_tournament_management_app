import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/models/team_model.dart';
import '../../data/repositories/team_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_container.dart';

class TeamFormScreen extends ConsumerStatefulWidget {
  final String? teamId;
  const TeamFormScreen({super.key, this.teamId});

  @override
  ConsumerState<TeamFormScreen> createState() => _TeamFormScreenState();
}

class _TeamFormScreenState extends ConsumerState<TeamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _coachController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  TeamModel? _existing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.teamId != null;
    if (_isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final result = await ref.read(teamRepositoryProvider).getTeam(widget.teamId!);
    result.fold(
      (f) {},
      (t) {
        if (!mounted) return;
        setState(() {
          _existing = t;
          _nameController.text = t.name;
          _shortNameController.text = t.shortName ?? '';
          _cityController.text = t.city ?? '';
          _coachController.text = t.coach ?? '';
        });
      },
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final notifier = ref.read(teamNotifierProvider.notifier);
    final now = DateTime.now();

    final team = TeamModel(
      id: _existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      shortName: _shortNameController.text.trim().isEmpty ? null : _shortNameController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      coach: _coachController.text.trim().isEmpty ? null : _coachController.text.trim(),
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
    );

    final result = _isEditing
        ? await notifier.update(team)
        : await notifier.create(team);

    setState(() => _isLoading = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.error)),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Team updated!' : 'Team created!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.teams);
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _cityController.dispose();
    _coachController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_isEditing ? 'Edit Team' : 'New Team')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                children: [
                  AppTextField(
                    controller: _nameController,
                    label: 'Team Name',
                    prefixIcon: Icons.groups_outlined,
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _shortNameController,
                    label: 'Short Name (e.g. MUN)',
                    prefixIcon: Icons.short_text,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _cityController,
                    label: 'City',
                    prefixIcon: Icons.location_city_outlined,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _coachController,
                    label: 'Coach',
                    prefixIcon: Icons.sports_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _isEditing ? 'Update Team' : 'Create Team',
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
