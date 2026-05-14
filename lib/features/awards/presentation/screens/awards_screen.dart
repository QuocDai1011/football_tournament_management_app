import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../standings/domain/models/standing_model.dart';
import '../../../../shared/widgets/loading_states.dart';
import '../../../../core/services/firestore_service.dart';

final awardsProvider = FutureProvider<List<AwardModel>>((ref) async {
  final firestore = ref.read(firestoreServiceProvider);
  final snap = await firestore.getCollection(
    FirestoreCollections.awards,
    orderBy: [const QueryOrder('createdAt', descending: true)],
  );
  return snap.docs.map((d) => AwardModel.fromJson(d.data(), d.id)).toList();
});

class AwardsScreen extends ConsumerWidget {
  const AwardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awardsAsync = ref.watch(awardsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Awards')),
      body: awardsAsync.when(
        loading: () => const ShimmerList(count: 3),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (awards) {
          if (awards.isEmpty) {
            return const EmptyState(
              title: 'No awards yet',
              subtitle:
                  'Awards are calculated automatically when a tournament finishes',
              icon: Icons.workspace_premium_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: awards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _AwardCard(award: awards[i])
                .animate(delay: (i * 60).ms)
                .fade()
                .slideY(begin: 0.1),
          );
        },
      ),
    );
  }
}

class _AwardCard extends StatelessWidget {
  final AwardModel award;
  const _AwardCard({required this.award});

  @override
  Widget build(BuildContext context) {
    final config = _awardConfig(award.type);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.color.withOpacity(0.08),
            AppColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(config.icon, color: config.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  award.type.displayName,
                  style: TextStyle(
                    color: config.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  award.playerName ?? award.teamName ?? 'Unknown',
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (award.statValue != null)
                  Text(
                    _statLabel(award.type, award.statValue!),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (award.type == AwardType.champion)
            const Icon(Icons.emoji_events, color: AppColors.accent, size: 36),
        ],
      ),
    );
  }

  String _statLabel(AwardType type, int value) {
    switch (type) {
      case AwardType.topScorer:
        return '$value goals';
      case AwardType.bestGoalkeeper:
        return '$value clean sheets';
      default:
        return '';
    }
  }

  _AwardConfig _awardConfig(AwardType type) {
    switch (type) {
      case AwardType.champion:
        return _AwardConfig(AppColors.accent, Icons.emoji_events);
      case AwardType.runnerUp:
        return _AwardConfig(AppColors.textSecondary, Icons.military_tech);
      case AwardType.topScorer:
        return _AwardConfig(AppColors.secondary, Icons.sports_soccer);
      case AwardType.bestGoalkeeper:
        return _AwardConfig(AppColors.info, Icons.sports_handball);
      case AwardType.fairPlay:
        return _AwardConfig(AppColors.success, Icons.handshake);
    }
  }
}

class _AwardConfig {
  final Color color;
  final IconData icon;
  const _AwardConfig(this.color, this.icon);
}
