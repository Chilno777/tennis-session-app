class PlayerStats {
  PlayerStats({required this.playerIndex});

  final int playerIndex;

  int matches = 0;
  int wins = 0;
  int losses = 0;
  int draws = 0;

  int gamesFor = 0;
  int gamesAgainst = 0;

  double get gameWinRate {
    final total = gamesFor + gamesAgainst;
    if (total == 0) return 0.0;
    return gamesFor / total;
  }
}