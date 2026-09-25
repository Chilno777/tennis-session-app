import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/match_pick.dart';
/// =============================================================
/// ④ スコア入力ページ
/// -------------------------------------------------------------
/// ④-1 Widget定義
/// ④-2 State / controller
/// ④-3 保存処理
/// ④-4 build
/// =============================================================

class ScoreInputPage extends StatefulWidget {
  const ScoreInputPage({
    super.key,
    required this.players,
    required this.match,
    required this.displayName,
  });

  final List<Player> players;
  final MatchPick match;
  final String Function(int index) displayName;

  @override
  State<ScoreInputPage> createState() => _ScoreInputPageState();
}

class _ScoreInputPageState extends State<ScoreInputPage> {
  /// ④-2 controller
  late final TextEditingController _teamAScoreController;
  late final TextEditingController _teamBScoreController;

  String _name(int i) => widget.displayName(i);

  @override
  void initState() {
    super.initState();
    _teamAScoreController = TextEditingController(
      text: widget.match.gameA?.toString() ?? '',
    );
    _teamBScoreController = TextEditingController(
      text: widget.match.gameB?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _teamAScoreController.dispose();
    _teamBScoreController.dispose();
    super.dispose();
  }

  /// ④-3 保存処理
  void _save() {
    final ga = int.tryParse(_teamAScoreController.text.trim());
    final gb = int.tryParse(_teamBScoreController.text.trim());

    setState(() {
      widget.match.gameA = ga;
      widget.match.gameB = gb;
    });

    Navigator.pop(context);
  }

  /// ④-4 UI
  @override
  Widget build(BuildContext context) {
    final m = widget.match;

    return Scaffold(
      appBar: AppBar(title: const Text('スコア入力')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_name(m.a1)} & ${_name(m.a2)}  vs  ${_name(m.b1)} & ${_name(m.b2)}',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _teamAScoreController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'チームA ゲーム数',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _teamBScoreController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'チームB ゲーム数',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('保存'),
              ),
            ),
            const SizedBox(height: 8),
            const Text('※ 空欄のまま保存すると「未入力」扱いになります'),
          ],
        ),
      ),
    );
  }
}