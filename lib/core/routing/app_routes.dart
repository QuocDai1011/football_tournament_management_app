/// Route path constants — tách riêng để tránh circular import
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String tournaments = '/tournaments';
  static const String tournamentDetail = '/tournaments/:id';
  static const String tournamentCreate = '/tournaments/create';
  static const String tournamentEdit = '/tournaments/:id/edit';
  static const String teams = '/teams';
  static const String teamDetail = '/teams/:id';
  static const String teamCreate = '/teams/create';
  static const String teamEdit = '/teams/:id/edit';
  static const String players = '/players';
  static const String playerDetail = '/players/:id';
  static const String playerCreate = '/players/create';
  static const String playerEdit = '/players/:id/edit';
  static const String matches = '/matches';
  static const String matchDetail = '/matches/:id';
  static const String matchCreate = '/matches/create';
  static const String matchEdit = '/matches/:id/edit';
  static const String standings = '/standings';
  static const String awards = '/awards';
  static const String seasons = '/seasons';
  static const String registrations = '/registrations';
}
