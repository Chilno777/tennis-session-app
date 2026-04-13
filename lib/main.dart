import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

/// =============================================================
/// ① アプリ全体の概要
/// -------------------------------------------------------------
/// このファイルは以下の役割で構成する
///
/// ①-1 アプリ起動
/// ②   モデル定義
/// ③   対戦表まわり（メイン機能）
/// ④   スコア入力
/// ⑤   個人成績
/// ⑥   セッション一覧
/// ⑦   プレイヤー登録
///
/// 今後は「③-5を変更」など、番号ベースで修正指示を出す
/// =============================================================

/// =============================================================
/// ①-1 アプリ起動
/// =============================================================

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PlayerRegisterPage(),
    );
  }
}

/// =============================================================
/// ② モデル定義
/// -------------------------------------------------------------
/// ②-1 Player
/// ②-2 MatchPick
/// ②-3 Session
/// ②-4 PlayerStats
/// =============================================================

/// ②-1 プレイヤー
class Player {
  Player({required this.name});
  String name;
}

/// ②-2 1試合ぶんの対戦カード
/// a1,a2 vs b1,b2 を player index で保持
class MatchPick {
  MatchPick({
    required this.a1,
    required this.a2,
    required this.b1,
    required this.b2,
    this.gameA,
    this.gameB,
  });

  final int a1;
  final int a2;
  final int b1;
  final int b2;

  int? gameA;
  int? gameB;

  String get scoreText {
    if (gameA == null || gameB == null) return '未入力';
    return '$gameA - $gameB';
  }

  String get resultText {
    if (gameA == null || gameB == null) return '未入力';
    if (gameA! > gameB!) return 'A勝ち';
    if (gameA! < gameB!) return 'B勝ち';
    return '引き分け';
  }
}

/// ②-3 セッション
/// 1回の練習日 / 大会日 / イベント単位の状態を持つ
class Session {
  Session({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.participantIndexes,
    this.courts = 1,
  });

  final String id;
  String title;
  final DateTime createdAt;

  /// この回に参加するプレイヤーの index
  List<int> participantIndexes;

  /// コート面数
  int courts;

  /// 元playerIndex -> 表示番号（1..N）
  Map<int, int> displayNo = {};

  /// シャッフル後の順番
  List<int> order = [];

  /// 次回試合生成の開始位置
  int cursor = 0;

  /// この回で作られた試合一覧
  final List<MatchPick> matches = [];
}

/// ②-4 個人成績
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

/// =============================================================
/// ③ 対戦表ページ
/// -------------------------------------------------------------
/// ③-1 Widget定義
/// ③-2 session参照getter
/// ③-3 初期化
/// ③-4 表示名 / シャッフル
/// ③-5 試合生成
/// ③-6 成績集計
/// ③-7 build
/// ③-8 参加者チェックリスト
/// ③-9 操作ボタン群
/// ③-10 試合一覧
/// ③-11 試合カード
/// =============================================================

class MatchListPage extends StatefulWidget {
  const MatchListPage({
    super.key,
    required this.players,
    required this.session,
  });

  final List<Player> players;
  final Session session;

  @override
  State<MatchListPage> createState() => _MatchListPageState();
}

class _MatchListPageState extends State<MatchListPage> {
  /// ③-2 session参照getter
  Map<int, int> get _displayNo => widget.session.displayNo;

  List<int> get _order => widget.session.order;
  set _order(List<int> v) => widget.session.order = v;

  int get _cursor => widget.session.cursor;
  set _cursor(int v) => widget.session.cursor = v;

  List<MatchPick> get _matches => widget.session.matches;

  int get _courts => widget.session.courts;
  set _courts(int v) => widget.session.courts = v;

  /// 生成補助用
  final Map<int, int> _playCount = {};

  /// ③-3 初期化
  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.players.length; i++) {
      _playCount[i] = 0;
    }
  }

  /// ③-4-1 表示用「番号:名前」
  String _name(int index) {
    final no = _displayNo[index] ?? (index + 1);
    return '$no:${widget.players[index].name}';
  }

  /// ③-4-2 番号シャッフル
  void _shuffleNumbers() {
    final members = widget.session.participantIndexes;
    if (members.isEmpty) return;

    final nums = List<int>.generate(members.length, (i) => i + 1)..shuffle();

    setState(() {
      _displayNo.clear();

      for (int k = 0; k < members.length; k++) {
        _displayNo[members[k]] = nums[k];
      }

      _order = List<int>.from(members);
      _order.sort((a, b) => _displayNo[a]!.compareTo(_displayNo[b]!));

      _cursor = 0;
    });
  }

  /// ③-5 試合生成
  /// シャッフル順に沿って循環スライドで試合を作る
  void _addMatch() {
    final members = List<int>.from(widget.session.participantIndexes);

    if (members.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('参加者は4人以上必要です')),
      );
      return;
    }

    bool isOrderValid() {
      if (_order.length != members.length) return false;
      final set = members.toSet();
      return _order.every(set.contains);
    }

    void rebuildOrderFromMembers() {
      _order = List<int>.from(members);

      final canSortByDisplayNo =
          _displayNo.isNotEmpty && _order.every((i) => _displayNo.containsKey(i));

      if (canSortByDisplayNo) {
        _order.sort((a, b) => _displayNo[a]!.compareTo(_displayNo[b]!));
      }

      _cursor = 0;
    }

    setState(() {
      if (!isOrderValid()) {
        rebuildOrderFromMembers();
      }

      final n = _order.length;

      for (int c = 0; c < _courts; c++) {
        final start = _cursor % n;
        int pick(int offset) => _order[(start + offset) % n];

        final a1 = pick(0);
        final a2 = pick(1);
        final b1 = pick(2);
        final b2 = pick(3);

        _matches.add(
          MatchPick(
            a1: a1,
            a2: a2,
            b1: b1,
            b2: b2,
          ),
        );

        _cursor = (start - 1 + n) % n;
      }
    });
  }

  /// ③-6 個人成績集計
  List<PlayerStats> _computeStats() {
    final List<PlayerStats> stats = List.generate(
      widget.players.length,
      (i) => PlayerStats(playerIndex: i),
    );

    for (final m in _matches) {
      if (m.gameA == null || m.gameB == null) continue;

      final aTeam = [m.a1, m.a2];
      final bTeam = [m.b1, m.b2];
      final ga = m.gameA!;
      final gb = m.gameB!;

      for (final p in [...aTeam, ...bTeam]) {
        stats[p].matches += 1;
      }

      for (final p in aTeam) {
        stats[p].gamesFor += ga;
        stats[p].gamesAgainst += gb;
      }

      for (final p in bTeam) {
        stats[p].gamesFor += gb;
        stats[p].gamesAgainst += ga;
      }

      if (ga > gb) {
        for (final p in aTeam) {
          stats[p].wins += 1;
        }
        for (final p in bTeam) {
          stats[p].losses += 1;
        }
      } else if (ga < gb) {
        for (final p in aTeam) {
          stats[p].losses += 1;
        }
        for (final p in bTeam) {
          stats[p].wins += 1;
        }
      } else {
        for (final p in [...aTeam, ...bTeam]) {
          stats[p].draws += 1;
        }
      }
    }

    return stats;
  }

  /// ③-7 メインUI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('対戦表'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: '個人成績',
            onPressed: () {
              final stats = _computeStats();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatsPage(
                    players: widget.players,
                    stats: stats,
                    displayName: _name,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('selected: ${widget.session.participantIndexes.length}'),
            const SizedBox(height: 8),

            Expanded(
              flex: 2,
              child: _buildParticipantChecklist(),
            ),

            const SizedBox(height: 8),
            _buildControls(),

            const SizedBox(height: 12),
            const Text(
              '対戦表',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            Expanded(
              flex: 3,
              child: _buildMatchList(),
            ),
          ],
        ),
      ),
    );
  }

  /// ③-8 参加者チェックリスト
  Widget _buildParticipantChecklist() {
    return ListView.builder(
      itemCount: widget.players.length,
      itemBuilder: (context, i) {
        final isSelected = widget.session.participantIndexes.contains(i);

        return CheckboxListTile(
          value: isSelected,
          title: Text(_name(i)),
          onChanged: (v) {
            setState(() {
              if (v == true) {
                if (!widget.session.participantIndexes.contains(i)) {
                  widget.session.participantIndexes.add(i);
                }
              } else {
                widget.session.participantIndexes.remove(i);
              }

              widget.session.order.clear();
              widget.session.displayNo.clear();
              widget.session.cursor = 0;
              widget.session.matches.clear();
            });
          },
        );
      },
    );
  }

  /// ③-9 操作ボタン群
  Widget _buildControls() {
    return Column(
      children: [
        Row(
          children: [
            const Text('コート面数'),
            const SizedBox(width: 12),
            DropdownButton<int>(
              value: _courts,
              items: const [1, 2, 3, 4]
                  .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text('$v'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _courts = v);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _shuffleNumbers,
              icon: const Icon(Icons.shuffle),
              label: const Text('番号シャッフル'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addMatch,
                icon: const Icon(Icons.add),
                label: const Text('試合追加（生成）'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '※ 参加者は4人以上必要です',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// ③-10 試合一覧
  Widget _buildMatchList() {
    if (_matches.isEmpty) {
      return const Center(child: Text('まだ試合がありません'));
    }

    return ListView.builder(
      itemCount: _matches.length,
      itemBuilder: (context, i) {
        final match = _matches[i];
        return _buildMatchCard(i, match);
      },
    );
  }

  /// ③-11 試合カード
  Widget _buildMatchCard(int index, MatchPick match) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScoreInputPage(
              players: widget.players,
              match: match,
              displayName: _name,
            ),
          ),
        );
        setState(() {});
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '試合${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '${_name(match.a1)} & ${_name(match.a2)}  vs  ${_name(match.b1)} & ${_name(match.b2)}',
              ),
              const SizedBox(height: 6),
              Text('スコア: ${match.scoreText}'),
              Text('結果: ${match.resultText}'),
            ],
          ),
        ),
      ),
    );
  }
}

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

/// =============================================================
/// ⑤ 個人成績ページ
/// -------------------------------------------------------------
/// ⑤-1 Widget定義
/// ⑤-2 build
/// =============================================================

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

/// =============================================================
/// ⑥ セッション一覧ページ
/// -------------------------------------------------------------
/// ⑥-1 Widget定義
/// ⑥-2 セッション作成
/// ⑥-3 セッションを開く
/// ⑥-4 build
/// =============================================================

class SessionListPage extends StatefulWidget {
  const SessionListPage({
    super.key,
    required this.players,
  });

  final List<Player> players;

  @override
  State<SessionListPage> createState() => _SessionListPageState();
}

class _SessionListPageState extends State<SessionListPage> {
  final List<Session> _sessions = [];

  /// ⑥-2 セッション作成
  void _createSession() async {
    if (widget.players.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先にプレイヤーを4人以上登録してください')),
      );
      return;
    }

    final controller = TextEditingController(
      text: '${DateTime.now().month}/${DateTime.now().day} 練習',
    );

    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新規セッション'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'セッション名'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('作成'),
          ),
        ],
      ),
    );

    if (title == null || title.isEmpty) return;

    final now = DateTime.now();
    final s = Session(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      createdAt: now,
      participantIndexes: List<int>.generate(widget.players.length, (i) => i),
      courts: 1,
    );

    setState(() => _sessions.insert(0, s));
  }

  /// ⑥-3 セッションを開く
  void _open(Session s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchListPage(
          players: widget.players,
          session: s,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  /// ⑥-4 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('セッション一覧')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createSession,
        child: const Icon(Icons.add),
      ),
      body: _sessions.isEmpty
          ? const Center(child: Text('右下の＋からセッションを作成'))
          : ListView.separated(
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = _sessions[i];
                return ListTile(
                  title: Text(s.title),
                  subtitle: Text(
                    '参加者 ${s.participantIndexes.length}人 / 試合 ${s.matches.length}件',
                  ),
                  onTap: () => _open(s),
                );
              },
            ),
    );
  }
}

/// =============================================================
/// ⑦ プレイヤー登録ページ
/// -------------------------------------------------------------
/// ⑦-1 Widget定義
/// ⑦-2 プレイヤー追加
/// ⑦-3 プレイヤー編集
/// ⑦-4 プレイヤー削除
/// ⑦-5 セッション一覧へ移動
/// ⑦-6 build
/// =============================================================

class PlayerRegisterPage extends StatefulWidget {
  const PlayerRegisterPage({super.key});

  @override
  State<PlayerRegisterPage> createState() => _PlayerRegisterPageState();
}

class _PlayerRegisterPageState extends State<PlayerRegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final List<Player> _players = [];

  /// ⑦-2 プレイヤー追加
  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _players.add(Player(name: name));
      _nameController.clear();
    });
  }

  /// ⑦-3 プレイヤー編集
  Future<void> _editPlayerName(int index) async {
    final player = _players[index];
    final editController = TextEditingController(text: player.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('名前を編集'),
        content: TextField(
          controller: editController,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, editController.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => player.name = result);
    }
  }

  /// ⑦-4 プレイヤー削除
  void _deletePlayer(int index) {
    setState(() => _players.removeAt(index));
  }

  /// ⑦-5 セッション一覧へ移動
  void _goToMatches() {
    if (_players.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最低4人登録してください')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionListPage(
          players: List<Player>.from(_players),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// ⑦-6 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プレイヤー登録'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: '対戦表へ',
            onPressed: _goToMatches,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名前を入力',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addPlayer(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addPlayer,
                child: const Text('追加'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _players.length,
                itemBuilder: (context, index) {
                  final player = _players[index];
                  return ListTile(
                    leading: Text('${index + 1}'),
                    title: Text(player.name),
                    onTap: () => _editPlayerName(index),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deletePlayer(index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}