import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/registration_repository.dart';
import '../../domain/models/registration_model.dart';
import '../../../teams/data/repositories/team_repository.dart';
import '../../../teams/domain/models/team_model.dart';
import '../../../../shared/widgets/loading_states.dart';
import '../../../../shared/widgets/app_image.dart';

class RegistrationsScreen extends ConsumerWidget {
  final String tournamentId;
  final String? seasonId;

  const RegistrationsScreen({
    super.key,
    required this.tournamentId,
    this.seasonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regsAsync = ref.watch(
      registrationsStreamProvider(
          (tournamentId: tournamentId, seasonId: seasonId)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registrations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showRegisterDialog(context, ref),
            tooltip: 'Register Team',
          ),
        ],
      ),
      body: regsAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (regs) {
          if (regs.isEmpty) {
            return EmptyState(
              title: 'No registrations',
              subtitle: 'Register teams to participate in this tournament',
              icon: Icons.how_to_reg_outlined,
              onAction: () => _showRegisterDialog(context, ref),
              actionLabel: 'Register Team',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: regs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _RegistrationCard(
              registration: regs[i],
              onApprove: () => _approveDialog(context, ref, regs[i]),
              onReject: () => _rejectDialog(context, ref, regs[i]),
              onDelete: () => _confirmDelete(context, ref, regs[i]),
            ).animate(delay: (i * 40).ms).fade().slideX(begin: 0.05),
          );
        },
      ),
    );
  }

  void _showRegisterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _RegisterTeamDialog(
        tournamentId: tournamentId,
        seasonId: seasonId,
      ),
    );
  }

  void _approveDialog(
      BuildContext context, WidgetRef ref, RegistrationModel reg) {
    final groupController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: const Text('Approve Registration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Approve ${reg.teamName}?'),
            const SizedBox(height: 12),
            TextField(
              controller: groupController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Assign Group (optional)',
                hintText: 'A, B, C...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(registrationNotifierProvider.notifier).approve(
                    reg.id,
                    groupController.text.trim().isEmpty
                        ? null
                        : groupController.text.trim().toUpperCase(),
                  );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectDialog(
      BuildContext context, WidgetRef ref, RegistrationModel reg) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: const Text('Reject Registration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ${reg.teamName}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(registrationNotifierProvider.notifier).reject(
                    reg.id,
                    reasonController.text.trim(),
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, RegistrationModel reg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: const Text('Remove Registration'),
        content: Text('Remove ${reg.teamName} from this tournament?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(registrationNotifierProvider.notifier)
                  .delete(reg.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  final RegistrationModel registration;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const _RegistrationCard({
    required this.registration,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(registration.status);
    final fmt = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          TeamLogoAvatar(
            logoUrl: registration.teamLogoUrl,
            teamName: registration.teamName,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  registration.teamName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (registration.group != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Group ${registration.group}',
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      fmt.format(registration.registeredAt),
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusRound),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  registration.status.displayName,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              PopupMenuButton<String>(
                color: AppColors.surfaceVariant,
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textTertiary, size: 18),
                onSelected: (v) {
                  if (v == 'approve') onApprove();
                  if (v == 'reject') onReject();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  if (registration.status != RegistrationStatus.approved)
                    const PopupMenuItem(
                        value: 'approve', child: Text('Approve')),
                  if (registration.status != RegistrationStatus.rejected)
                    const PopupMenuItem(
                        value: 'reject',
                        child: Text('Reject',
                            style: TextStyle(color: AppColors.warning))),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Remove',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.pending:
        return AppColors.warning;
      case RegistrationStatus.approved:
        return AppColors.success;
      case RegistrationStatus.rejected:
        return AppColors.error;
    }
  }
}

class _RegisterTeamDialog extends ConsumerStatefulWidget {
  final String tournamentId;
  final String? seasonId;

  const _RegisterTeamDialog({
    required this.tournamentId,
    this.seasonId,
  });

  @override
  ConsumerState<_RegisterTeamDialog> createState() =>
      _RegisterTeamDialogState();
}

class _RegisterTeamDialogState extends ConsumerState<_RegisterTeamDialog> {
  String? _selectedTeamId;
  TeamModel? _selectedTeam;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsStreamProvider);

    return AlertDialog(
      backgroundColor: AppColors.surfaceVariant,
      title: const Text('Register Team',
          style:
              TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700)),
      content: teamsAsync.when(
        loading: () => const CircularProgressIndicator(),
        error: (e, _) => Text('Error: $e'),
        data: (teams) => DropdownButtonFormField<String>(
          value: _selectedTeamId,
          hint: const Text('Select team'),
          dropdownColor: AppColors.surfaceVariant,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.groups_outlined),
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
          onChanged: (v) {
            setState(() {
              _selectedTeamId = v;
              _selectedTeam = teams.firstWhere((t) => t.id == v);
            });
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving || _selectedTeamId == null ? null : _register,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Register'),
        ),
      ],
    );
  }

  Future<void> _register() async {
    if (_selectedTeamId == null || _selectedTeam == null) return;
    setState(() => _isSaving = true);

    final registration = RegistrationModel(
      id: const Uuid().v4(),
      tournamentId: widget.tournamentId,
      seasonId: widget.seasonId,
      teamId: _selectedTeamId!,
      teamName: _selectedTeam!.name,
      teamLogoUrl: _selectedTeam!.logoUrl,
      status: RegistrationStatus.pending,
      registeredAt: DateTime.now(),
    );

    final result = await ref
        .read(registrationNotifierProvider.notifier)
        .create(registration);

    setState(() => _isSaving = false);

    result.fold(
      (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.error),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team registered successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      },
    );
  }
}
