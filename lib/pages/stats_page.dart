import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/player_stats.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({
    super.key,
    required this.players,
    required this.stats,
    required this.displayName,
  });

  final List<Player> players;
  final List<PlayerStats> stats;
  final String Function(int index) displayName;

  @override
  Widget build(BuildContext context) {
    final order = List<PlayerStats>.from(stats)
      ..sort((a, b) => b.gamesFor.compareTo(a.gamesFor));

    return Scaffold(
      appBar: AppBar(title: const Text('個人成績')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: order.length,
        itemBuilder: (context, i) {
          final s = order[i];
          final rank = i + 1;

          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('$rank')),
              title: Text(displayName(s.playerIndex)),
              subtitle: Text(
                '試合 ${s.matches}  勝 ${s.wins}  負 ${s.losses}  分 ${s.draws}\n'
                '獲得 ${s.gamesFor}  失 ${s.gamesAgainst}  '
                '獲得率 ${(s.gameWinRate * 100).toStringAsFixed(1)}%',
              ),
            ),
          );
        },
      ),
    );
  }
}