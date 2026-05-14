import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tournaments/domain/models/tournament_model.dart';

class TournamentCard extends StatelessWidget {
  final TournamentModel tournament;

  const TournamentCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return GestureDetector(
      onTap: () {
        // Navigate to tournament detail
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('View ${tournament.name} details')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.card,
              AppColors.cardElevated,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color: AppColors.glassBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusL),
                topRight: Radius.circular(AppDimensions.radiusL),
              ),
              child: Container(
                height: isMobile ? 100 : 120,
                color: AppColors.surfaceVariant,
                child: tournament.bannerUrl?.isNotEmpty == true
                    ? Image.network(
                        tournament.bannerUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildBannerPlaceholder(),
                      )
                    : _buildBannerPlaceholder(),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tournament name
                  Text(
                    tournament.name.isNotEmpty
                        ? tournament.name
                        : 'Unknown Tournament',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Type and status badges
                  Row(
                    children: [
                      _buildBadge(
                        tournament.type.displayName,
                        const Color(0xFF2979FF),
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                        tournament.status.displayName,
                        _getStatusColor(tournament.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Stats row
                  Row(
                    children: [
                      // Teams info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Teams',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                            ),
                            Text(
                              '${(tournament.totalMatches)} / ${tournament.maxTeams}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      // Matches info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Matches',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                            ),
                            Text(
                              '${tournament.completedMatches} / ${tournament.totalMatches}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Progress indicator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: tournament.progressPercent,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(tournament.progressPercent),
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Dates
                  Text(
                    _formatDateRange(tournament.startDate, tournament.endDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.secondary.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_soccer,
          size: 48,
          color: AppColors.primary.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.upcoming:
        return AppColors.info;
      case TournamentStatus.ongoing:
        return AppColors.warning;
      case TournamentStatus.finished:
        return AppColors.finished;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.33) return const Color(0xFF00C853);
    if (progress < 0.66) return const Color(0xFFFFAB00);
    return const Color(0xFF2979FF);
  }

  String _formatDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null) return 'No date set';

    final formatter = DateFormat('MMM d');
    final start = formatter.format(startDate);

    if (endDate == null) {
      return 'Starting $start';
    }

    final end = formatter.format(endDate);
    return '$start - $end';
  }
}
