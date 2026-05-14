import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

/// Network image with shimmer placeholder and fallback
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final Widget? fallback;
  final Color? backgroundColor;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = AppDimensions.radiusM,
    this.fit = BoxFit.cover,
    this.fallback,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              width: width,
              height: height,
              fit: fit,
              placeholder: (_, __) => _shimmerPlaceholder(),
              errorWidget: (_, __, ___) => _fallbackWidget(),
            )
          : _fallbackWidget(),
    );
  }

  Widget _shimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.cardElevated,
      child: Container(
        width: width,
        height: height,
        color: AppColors.surfaceVariant,
      ),
    );
  }

  Widget _fallbackWidget() {
    if (fallback != null) return fallback!;
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? AppColors.surfaceVariant,
      child: const Icon(
        Icons.sports_soccer,
        color: AppColors.textTertiary,
      ),
    );
  }
}

/// Team logo avatar
class TeamLogoAvatar extends StatelessWidget {
  final String? logoUrl;
  final String teamName;
  final double size;

  const TeamLogoAvatar({
    super.key,
    this.logoUrl,
    required this.teamName,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.25),
      child: logoUrl != null && logoUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: logoUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(),
              errorWidget: (_, __, ___) => _initials(),
            )
          : _initials(),
    );
  }

  Widget _placeholder() => Container(
        width: size,
        height: size,
        color: AppColors.surfaceVariant,
      );

  Widget _initials() => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(size * 0.25),
        ),
        child: Center(
          child: Text(
            teamName.isNotEmpty ? teamName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.black,
              fontSize: size * 0.4,
              fontWeight: FontWeight.w700,
              fontFamily: 'Rajdhani',
            ),
          ),
        ),
      );
}

/// Player avatar
class PlayerAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String playerName;
  final double size;

  const PlayerAvatar({
    super.key,
    this.avatarUrl,
    required this.playerName,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.surfaceVariant,
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
                errorWidget: (_, __, ___) => _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() => Container(
        width: size,
        height: size,
        color: AppColors.primaryDark,
        child: Center(
          child: Text(
            playerName.isNotEmpty ? playerName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}
