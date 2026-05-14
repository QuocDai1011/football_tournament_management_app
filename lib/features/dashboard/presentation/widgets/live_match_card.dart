import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../matches/domain/models/match_model.dart';

class LiveMatchCard extends StatefulWidget {
  final MatchModel match;

  const LiveMatchCard({super.key, required this.match});

  @override
  State<LiveMatchCard> createState() => _LiveMatchCardState();
}

class _LiveMatchCardState extends State<LiveMatchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'View match details: ${widget.match.homeTeamName} vs ${widget.match.awayTeamName}')),
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
            color: AppColors.live.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.live.withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header with LIVE badge and time
              _buildHeader(context),
              const SizedBox(height: 16),

              // Main match content
              if (isMobile)
                _buildMobileLayout(context)
              else
                _buildDesktopLayout(context),

              const SizedBox(height: 12),

              // Tournament and venue info
              _buildMatchInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Match type and round
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.match.type.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (widget.match.group?.isNotEmpty == true)
              Text(
                'Group: ${widget.match.group}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              ),
          ],
        ),

        // LIVE badge with pulse
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.live
                    .withOpacity(0.2 + (_pulseAnimation.value * 0.3)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.live
                      .withOpacity(0.6 + (_pulseAnimation.value * 0.4)),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        AppColors.live.withOpacity(0.5 * _pulseAnimation.value),
                    blurRadius: 8 * _pulseAnimation.value,
                    spreadRadius: 2 * _pulseAnimation.value,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.live,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.live.withOpacity(0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.live,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${widget.match.minute ?? 0}'",
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.live,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Home team
            Expanded(
              child: _buildTeamSection(
                context,
                widget.match.homeTeamLogoUrl,
                widget.match.homeTeamName,
                widget.match.homeScore,
                true,
              ),
            ),

            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Column(
                children: [
                  Text(
                    widget.match.scoreDisplay,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),

            // Away team
            Expanded(
              child: _buildTeamSection(
                context,
                widget.match.awayTeamLogoUrl,
                widget.match.awayTeamName,
                widget.match.awayScore,
                false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Home team
        Expanded(
          child: _buildTeamSection(
            context,
            widget.match.homeTeamLogoUrl,
            widget.match.homeTeamName,
            widget.match.homeScore,
            true,
          ),
        ),

        // Score and vs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Text(
                  widget.match.scoreDisplay,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'vs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              ),
            ],
          ),
        ),

        // Away team
        Expanded(
          child: _buildTeamSection(
            context,
            widget.match.awayTeamLogoUrl,
            widget.match.awayTeamName,
            widget.match.awayScore,
            false,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection(
    BuildContext context,
    String? logoUrl,
    String teamName,
    int score,
    bool isHome,
  ) {
    return Column(
      crossAxisAlignment:
          isHome ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        // Logo
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: logoUrl?.isNotEmpty == true
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
                  ),
                )
              : _buildLogoPlaceholder(),
        ),
        const SizedBox(height: 8),

        // Team name
        SizedBox(
          width: 100,
          child: Text(
            teamName.isNotEmpty ? teamName : 'Unknown',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: isHome ? TextAlign.left : TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoPlaceholder() {
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
          Icons.groups,
          size: 28,
          color: AppColors.primary.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildMatchInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Venue
          if (widget.match.venue?.isNotEmpty == true) ...[
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.match.venue!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Time
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(
                widget.match.scheduledAt != null
                    ? DateFormat('HH:mm, MMM dd')
                        .format(widget.match.scheduledAt!)
                    : 'Time TBA',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
