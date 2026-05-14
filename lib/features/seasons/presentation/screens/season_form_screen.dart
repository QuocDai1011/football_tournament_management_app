import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/season_model.dart';
import '../../data/repositories/season_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

class SeasonFormSheet extends ConsumerStatefulWidget {
  final String tournamentId;
  final SeasonModel? existing;

  const SeasonFormSheet({
    super.key,
    required this.tournamentId,
    this.existing,
  });

  @override
  ConsumerState<SeasonFormSheet> createState() => _SeasonFormSheetState();
}

class _SeasonFormSheetState extends ConsumerState<SeasonFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 90));
  DateTime? _regDeadline;
  SeasonStatus _status = SeasonStatus.upcoming;
  int _maxTeams = 16;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final s = widget.existing!;
      _nameController.text = s.name;
      _descController.text = s.description ?? '';
      _startDate = s.startDate;
      _endDate = s.endDate;
      _regDeadline = s.registrationDeadline;
      _status = s.status;
      _maxTeams = s.maxTeams;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickRegDeadline(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _regDeadline ?? _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _regDeadline = picked);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final notifier = ref.read(seasonNotifierProvider.notifier);
    final now = DateTime.now();

    final season = SeasonModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      tournamentId: widget.tournamentId,
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      status: _status,
      startDate: _startDate,
      endDate: _endDate,
      registrationDeadline: _regDeadline,
      maxTeams: _maxTeams,
      registeredTeams: widget.existing?.registeredTeams ?? 0,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    final result = widget.existing != null
        ? await notifier.update(season)
        : await notifier.create(season);

    setState(() => _isLoading = false);

    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message), backgroundColor: AppColors.error),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing != null
                ? 'Season updated!'
                : 'Season created!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.existing != null ? 'Edit Season' : 'New Season',
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              AppTextField(
                controller: _nameController,
                label: 'Season Name',
                hint: 'Season 2025',
                prefixIcon: Icons.calendar_month_outlined,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _descController,
                label: 'Description (optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Date pickers
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Start Date',
                      value: fmt.format(_startDate),
                      onTap: () => _pickDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'End Date',
                      value: fmt.format(_endDate),
                      onTap: () => _pickDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DateField(
                label: 'Registration Deadline (optional)',
                value: _regDeadline != null
                    ? fmt.format(_regDeadline!)
                    : 'Not set',
                onTap: () => _pickRegDeadline(context),
                icon: Icons.timer_outlined,
              ),
              const SizedBox(height: 16),

              // Max teams
              Row(
                children: [
                  const Text('Max Teams:',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                  const Spacer(),
                  IconButton(
                    onPressed: _maxTeams > 2
                        ? () => setState(() => _maxTeams--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.primary,
                  ),
                  Text(
                    _maxTeams.toString(),
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _maxTeams++),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status
              const Text('Status',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: SeasonStatus.values.map((s) {
                  final selected = _status == s;
                  return ChoiceChip(
                    label: Text(s.displayName),
                    selected: selected,
                    onSelected: (_) => setState(() => _status = s),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color:
                          selected ? AppColors.primary : AppColors.glassBorder,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              AppButton(
                label:
                    widget.existing != null ? 'Update Season' : 'Create Season',
                onPressed: _save,
                isLoading: _isLoading,
                icon: widget.existing != null ? Icons.save : Icons.add,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData icon;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.icon = Icons.calendar_today_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 11)),
                  Text(value,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
