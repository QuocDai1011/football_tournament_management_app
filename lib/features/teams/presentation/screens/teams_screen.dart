import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../data/repositories/team_repository.dart';
import '../../domain/models/team_model.dart';
import '../../../../shared/widgets/loading_states.dart';
import '../../../../shared/widgets/app_image.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go(AppRoutes.teamCreate),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search teams...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: teamsAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (teams) {
          final filtered = _searchQuery.isEmpty
              ? teams
              : teams
                  .where((t) =>
                      t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();

          if (filtered.isEmpty) {
            return const EmptyState(
              title: 'No teams found',
              subtitle: 'Create your first team',
              icon: Icons.groups_outlined,
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, i) => _TeamCard(team: filtered[i])
                .animate(delay: (i * 40).ms)
                .fade()
                .scale(begin: const Offset(0.9, 0.9)),
          );
        },
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final TeamModel team;
  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/teams/${team.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.glassBorder),
        ),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TeamLogoAvatar(
              logoUrl: team.logoUrl,
              teamName: team.name,
              size: 60,
            ),
            const SizedBox(height: 12),
            Text(
              team.name,
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (team.city != null) ...[
              const SizedBox(height: 4),
              Text(
                team.city!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Stat(label: 'P', value: team.totalPlayers.toString()),
                _Stat(label: 'W', value: team.wins.toString()),
                _Stat(label: 'GF', value: team.goalsFor.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
