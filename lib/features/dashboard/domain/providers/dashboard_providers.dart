import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../matches/domain/models/match_model.dart';
import '../../../tournaments/domain/models/tournament_model.dart';
import '../../../teams/domain/models/team_model.dart';
import '../../../players/domain/models/player_model.dart';
import '../../../../core/services/firestore_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REALTIME STREAM PROVIDERS — thay thế hoàn toàn FutureProvider cũ
// Mỗi provider lắng nghe Firestore realtime, tự động cập nhật UI
// ─────────────────────────────────────────────────────────────────────────────

/// Stream tất cả tournaments, sắp xếp mới nhất trước
final allTournamentsStreamProvider =
    StreamProvider.autoDispose<List<TournamentModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.collectionStream(
    FirestoreCollections.tournaments,
    orderBy: [const QueryOrder('createdAt', descending: true)],
  ).map((snap) =>
      snap.docs.map((d) => TournamentModel.fromJson(d.data(), d.id)).toList());
});

/// Stream chỉ tournaments đang diễn ra (ongoing)
final activeTournamentsStreamProvider =
    StreamProvider.autoDispose<List<TournamentModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.collectionStream(
    FirestoreCollections.tournaments,
    filters: [QueryFilter.equalTo('status', 'ongoing')],
  ).map((snap) {
    final list = snap.docs.map((d) => TournamentModel.fromJson(d.data(), d.id)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

/// Stream tournaments upcoming
final upcomingTournamentsStreamProvider =
    StreamProvider.autoDispose<List<TournamentModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.collectionStream(
    FirestoreCollections.tournaments,
    filters: [QueryFilter.equalTo('status', 'upcoming')],
  ).map((snap) {
    final list = snap.docs.map((d) => TournamentModel.fromJson(d.data(), d.id)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

/// Stream tournaments finished
final finishedTournamentsStreamProvider =
    StreamProvider.autoDispose<List<TournamentModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.collectionStream(
    FirestoreCollections.tournaments,
    filters: [QueryFilter.equalTo('status', 'finished')],
  ).map((snap) {
    final list = snap.docs.map((d) => TournamentModel.fromJson(d.data(), d.id)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

/// Stream tất cả teams
final allTeamsStreamProvider =
    StreamProvider.autoDispose<List<TeamModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.collectionStream(
    FirestoreCollections.teams,
    orderBy: [const QueryOrder('name')],
  ).map((snap) =>
      snap.docs.map((d) => TeamModel.fromJson(d.data(), d.id)).toList());
});

/// Stream tất cả players
final allPlayersStreamProvider =
    StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.collectionStream(
    FirestoreCollections.players,
    orderBy: [const QueryOrder('name')],
  ).map((snap) =>
      snap.docs.map((d) => PlayerModel.fromJson(d.data(), d.id)).toList());
});

/// Stream chỉ live matches — realtime, dùng cho dashboard live section
final liveMatchesStreamProvider =
    StreamProvider.autoDispose<List<MatchModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.collectionStream(
    FirestoreCollections.matches,
    filters: [QueryFilter.equalTo('status', 'live')],
  ).map((snap) {
    final list = snap.docs.map((d) => MatchModel.fromJson(d.data(), d.id)).toList();
    list.sort((a, b) {
      if (a.scheduledAt == null && b.scheduledAt == null) return 0;
      if (a.scheduledAt == null) return 1;
      if (b.scheduledAt == null) return -1;
      return b.scheduledAt!.compareTo(a.scheduledAt!);
    });
    return list;
  });
});

/// Stream recent matches (10 trận gần nhất)
final recentMatchesStreamProvider =
    StreamProvider.autoDispose<List<MatchModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore
      .collectionStream(
        FirestoreCollections.matches,
        orderBy: [const QueryOrder('scheduledAt', descending: true)],
        limit: 10,
      )
      .map((snap) =>
          snap.docs.map((d) => MatchModel.fromJson(d.data(), d.id)).toList());
});

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD STATS — tổng hợp từ các stream riêng lẻ
// Dùng select() để tránh rebuild không cần thiết
// ─────────────────────────────────────────────────────────────────────────────

class DashboardStats {
  final int totalTournaments;
  final int activeTournaments;
  final int upcomingTournaments;
  final int finishedTournaments;
  final int totalTeams;
  final int totalPlayers;
  final int liveMatches;
  final int todayMatches;
  final List<MatchModel> recentMatches;
  final List<MatchModel> liveMatchList;
  final List<TournamentModel> activeTournamentList;

  const DashboardStats({
    this.totalTournaments = 0,
    this.activeTournaments = 0,
    this.upcomingTournaments = 0,
    this.finishedTournaments = 0,
    this.totalTeams = 0,
    this.totalPlayers = 0,
    this.liveMatches = 0,
    this.todayMatches = 0,
    this.recentMatches = const [],
    this.liveMatchList = const [],
    this.activeTournamentList = const [],
  });

  /// Tổng số matches từ recentMatches (không phải tổng DB)
  int get totalMatchesDisplayed => recentMatches.length;
}

/// Provider tổng hợp dashboard stats từ các stream
/// Dùng StreamProvider để toàn bộ dashboard reactive
final dashboardStatsProvider =
    Provider.autoDispose<AsyncValue<DashboardStats>>((ref) {
  // Combine streams bằng cách watch từng provider
  final tournamentsAsync = ref.watch(allTournamentsStreamProvider);
  final teamsAsync = ref.watch(allTeamsStreamProvider);
  final playersAsync = ref.watch(allPlayersStreamProvider);
  final liveAsync = ref.watch(liveMatchesStreamProvider);
  final recentAsync = ref.watch(recentMatchesStreamProvider);

  // Chỉ loading khi tất cả dữ liệu chính đang loading và chưa có data
  if (tournamentsAsync.isLoading && tournamentsAsync.valueOrNull == null) {
    return const AsyncValue.loading();
  }

  final tournaments = tournamentsAsync.valueOrNull ?? [];
  final teams = teamsAsync.valueOrNull ?? [];
  final players = playersAsync.valueOrNull ?? [];
  final liveMatches = liveAsync.valueOrNull ?? [];
  final recentMatches = recentAsync.valueOrNull ?? [];

  final active =
      tournaments.where((t) => t.status == TournamentStatus.ongoing).toList();
  final upcoming =
      tournaments.where((t) => t.status == TournamentStatus.upcoming).toList();
  final finished =
      tournaments.where((t) => t.status == TournamentStatus.finished).toList();

  final now = DateTime.now();
  final todayMatches = recentMatches.where((m) {
    if (m.scheduledAt == null) return false;
    final d = m.scheduledAt!;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }).length;

  return AsyncValue.data(DashboardStats(
    totalTournaments: tournaments.length,
    activeTournaments: active.length,
    upcomingTournaments: upcoming.length,
    finishedTournaments: finished.length,
    totalTeams: teams.length,
    totalPlayers: players.length,
    liveMatches: liveMatches.length,
    todayMatches: todayMatches,
    recentMatches: recentMatches,
    liveMatchList: liveMatches,
    activeTournamentList: active.take(5).toList(),
  ));
});

// ─────────────────────────────────────────────────────────────────────────────
// INDIVIDUAL COUNT PROVIDERS — dùng select() để tránh rebuild toàn bộ
// ─────────────────────────────────────────────────────────────────────────────

/// Chỉ lấy số lượng tournaments — không rebuild khi data thay đổi nhưng count giữ nguyên
final tournamentCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(allTournamentsStreamProvider).valueOrNull?.length ?? 0;
});

final teamCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(allTeamsStreamProvider).valueOrNull?.length ?? 0;
});

final playerCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(allPlayersStreamProvider).valueOrNull?.length ?? 0;
});

final liveMatchCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(liveMatchesStreamProvider).valueOrNull?.length ?? 0;
});

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH & FILTER PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

/// Search query state provider
final dashboardSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Filtered teams based on search query
final filteredTeamsProvider = Provider.autoDispose<List<TeamModel>>((ref) {
  final teams = ref.watch(allTeamsStreamProvider).valueOrNull ?? [];
  final query = ref.watch(dashboardSearchQueryProvider).toLowerCase();

  if (query.isEmpty) return teams;

  return teams.where((team) {
    return team.name.toLowerCase().contains(query) ||
        (team.shortName?.toLowerCase().contains(query) ?? false) ||
        (team.city?.toLowerCase().contains(query) ?? false);
  }).toList();
});

/// Filtered players based on search query
final filteredPlayersProvider = Provider.autoDispose<List<PlayerModel>>((ref) {
  final players = ref.watch(allPlayersStreamProvider).valueOrNull ?? [];
  final query = ref.watch(dashboardSearchQueryProvider).toLowerCase();

  if (query.isEmpty) return players;

  return players.where((player) {
    return player.name.toLowerCase().contains(query) ||
        (player.teamName?.toLowerCase().contains(query) ?? false) ||
        player.position.displayName.toLowerCase().contains(query);
  }).toList();
});

/// Top scorers from recent matches
final topScorersProvider = Provider.autoDispose<List<PlayerModel>>((ref) {
  final players = ref.watch(allPlayersStreamProvider).valueOrNull ?? [];

  final sorted = List<PlayerModel>.from(players)
    ..sort((a, b) => b.goals.compareTo(a.goals));

  return sorted.take(5).toList();
});

/// Top assists provider
final topAssistsProvider = Provider.autoDispose<List<PlayerModel>>((ref) {
  final players = ref.watch(allPlayersStreamProvider).valueOrNull ?? [];

  final sorted = List<PlayerModel>.from(players)
    ..sort((a, b) => b.assists.compareTo(a.assists));

  return sorted.take(5).toList();
});
