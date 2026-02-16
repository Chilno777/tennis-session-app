import 'package:flutter/material.dart';

/// =============================================================
/// Tennis Doubles App (MVP)
/// -------------------------------------------------------------
/// 画面:
///  1) PlayerRegisterPage  : プレイヤー登録（追加/編集/削除）
///  2) MatchListPage       : 参加者選択・番号シャッフル・試合生成・試合一覧
///  3) ScoreInputPage      : スコア入力（MatchPickに保存）
///
/// 重要な変更ポイント:
///  - 試合生成ロジック: _addMatch()   ★ここを差し替える
///  - 番号シャッフル表示: _displayNo と _name() ★ここを触る
/// =============================================================

/// =============================================================
/// Models
/// =============================================================

/// プレイヤー（現状は名前だけ）
///
/// 番号は index + 1 を表示に使う方針（削除すると自動で詰まる）
class Player {
  Player({required this.name});
  String name;
}

/// 1試合ぶんの対戦カード（内部はプレイヤーの index で管理）
///
/// a1,a2 vs b1,b2
/// スコアは gameA / gameB に保存（未入力は null）
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

/// =============================================================
/// App Entry
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
/// Page: プレイヤー登録
/// =============================================================
/// - 追加/編集/削除
/// - 4人以上で「対戦表へ」遷移
class PlayerRegisterPage extends StatefulWidget {
  const PlayerRegisterPage({super.key});

  @override
  State<PlayerRegisterPage> createState() => _PlayerRegisterPageState();
}

class _PlayerRegisterPageState extends State<PlayerRegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final List<Player> _players = [];

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _players.add(Player(name: name));
      _nameController.clear();
    });
  }

  Future<void> _editPlayerName(int index) async {
    final player = _players[index];
    final editController = TextEditingController(text: player.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('名前を編集'),
        content: TextField(controller: editController, autofocus: true),
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

  void _deletePlayer(int index) {
    setState(() => _players.removeAt(index));
  }

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
        builder: (_) => MatchListPage(players: List.of(_players)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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
            /// 追加フォーム
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

            /// 一覧
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

/// =============================================================
/// Page: 対戦表
/// =============================================================
/// - 参加者チェック
/// - 番号シャッフル（表示だけ）
/// — - コート面数（1〜4）
/// - 試合追加（生成）
/// - 試合カードタップでスコア入力
class MatchListPage extends StatefulWidget {
  const MatchListPage({super.key, required this.players});
  final List<Player> players;

  @override
  State<MatchListPage> createState() => _MatchListPageState();
}

class _MatchListPageState extends State<MatchListPage> {
  // --- State: participants / matches ---
  final List<bool> _selected = [];      // 参加者チェック（playersと同じ長さ）
  final List<MatchPick> _matches = [];  // 生成された試合一覧
  final Map<int, int> _playCount = {};  // 出場回数（現状は生成補助に使う）

  // --- State: UI options ---
  int _courts = 1; // コート面数（1〜4）

  // --- State: display numbers (shuffle) ---
  // 元index -> 表示番号（1..N）
  // ※内部ロジックは index のまま。表示だけ番号を変える。
  final Map<int, int> _displayNo = {};
  List<int> _order = []; // 表示番号(1..N)の順に並べた参加者index
  int _cursor = 0;       // 次に使う開始位置（4人ずつ進む）


  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.players.length; i++) {
      _selected.add(true); // デフォルト全員参加
      _playCount[i] = 0;
    }
  }

  /// 参加者（チェック済み）の index 一覧
  List<int> _selectedMemberIndexes() {
    final members = <int>[];
    for (int i = 0; i < _selected.length; i++) {
      if (_selected[i]) members.add(i);
    }
    return members;
  }

  /// 表示用「番号:名前」
  /// ★番号シャッフルの影響はここに集約
  String _name(int index) {
    final no = _displayNo[index] ?? (index + 1);
    return '$no:${widget.players[index].name}';
  }

  /// 番号シャッフル（表示のみ）
  void _shuffleNumbers() {
  final members = _selectedMemberIndexes();
  if (members.isEmpty) return;

  // 1..N をシャッフルして割り当て
  final nums = List<int>.generate(members.length, (i) => i + 1)..shuffle();

  setState(() {
    _displayNo.clear();
    for (int k = 0; k < members.length; k++) {
      _displayNo[members[k]] = nums[k];
    }

    // ★ ここが重要：表示番号の小さい順（1,2,3...）に並べた順番を作る
    _order = List<int>.from(members);
    _order.sort((a, b) => _displayNo[a]!.compareTo(_displayNo[b]!));

    _cursor = 0; // シャッフルしたら先頭から
  });
}


  /// =============================================================
  /// ★ 試合追加（生成）ロジック
  /// -------------------------------------------------------------
  /// ここを差し替えると、生成方式を自由に変えられます。
  /// 今は「出場回数が少ない順に4人を取る」を、
  /// コート面数ぶん繰り返しています。
  /// =============================================================
  void _addMatch() {
  final members = _selectedMemberIndexes();

  if (members.length < 4) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('参加者は4人以上必要です')),
    );
    return;
  }

  // シャッフル（= _order 作成）をまだしてない場合は、自動で作る
  if (_order.isEmpty) {
    // displayNo が空なら「表示番号=順番」で仮割当
    if (_displayNo.isEmpty) {
      for (int k = 0; k < members.length; k++) {
        _displayNo[members[k]] = k + 1;
      }
    }

    _order = List<int>.from(members);
    _order.sort((a, b) => (_displayNo[a] ?? 999999).compareTo(_displayNo[b] ?? 999999));
    _cursor = 0;
  }

  setState(() {
    for (int c = 0; c < _courts; c++) {
      if (_order.length < 4) return;

      // 4人を順番通りに取る（末尾まで行ったら先頭に戻る）
      int pick(int offset) => _order[(_cursor + offset) % _order.length];

      final a1 = pick(0); // 1番目
      final a2 = pick(1); // 2番目
      final b1 = pick(2); // 3番目
      final b2 = pick(3); // 4番目

      _matches.add(MatchPick(a1: a1, a2: a2, b1: b1, b2: b2));

      // 次の4人へ
      _cursor = (_cursor + 4) % _order.length;
    }
  });
}

  /// =============================================================
  /// UI
  /// =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('対戦表')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('参加メンバー', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // 参加者チェック
            Expanded(flex: 2, child: _buildParticipantChecklist()),

            const SizedBox(height: 8),

            // 操作パネル（コート面数/シャッフル/試合追加）
            _buildControls(),

            const SizedBox(height: 16),
            const Text('対戦表', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // 試合一覧
            Expanded(flex: 3, child: _buildMatchList()),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantChecklist() {
    return ListView.builder(
      itemCount: widget.players.length,
      itemBuilder: (context, i) {
        return CheckboxListTile(
          value: _selected[i],
          title: Text(_name(i)),
          onChanged: (v) => setState(() => _selected[i] = v ?? false),
        );
      },
    );
  }

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
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _courts = v);
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

  Widget _buildMatchCard(int index, MatchPick match) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScoreInputPage(
              players: widget.players,
              match: match,
            ),
          ),
        );
        setState(() {}); // 入力後に表示更新
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('試合${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('${_name(match.a1)} & ${_name(match.a2)}  vs  ${_name(match.b1)} & ${_name(match.b2)}'),
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
/// Page: スコア入力
/// =============================================================
/// - gameA / gameB を入力して MatchPick に保存
class ScoreInputPage extends StatefulWidget {
  const ScoreInputPage({
    super.key,
    required this.players,
    required this.match,
  });

  final List<Player> players;
  final MatchPick match;

  @override
  State<ScoreInputPage> createState() => _ScoreInputPageState();
}

class _ScoreInputPageState extends State<ScoreInputPage> {
  late final TextEditingController _teamAScoreController;
  late final TextEditingController _teamBScoreController;

  // NOTE:
  // ここでは「表示番号シャッフル」は反映していません。
  // 反映したい場合は displayNo を渡す設計にします（後でOK）。
  String _name(int i) => '${i + 1}:${widget.players[i].name}';

  @override
  void initState() {
    super.initState();
    _teamAScoreController = TextEditingController(text: widget.match.gameA?.toString() ?? '');
    _teamBScoreController = TextEditingController(text: widget.match.gameB?.toString() ?? '');
  }

  @override
  void dispose() {
    _teamAScoreController.dispose();
    _teamBScoreController.dispose();
    super.dispose();
  }

  void _save() {
    final ga = int.tryParse(_teamAScoreController.text.trim());
    final gb = int.tryParse(_teamBScoreController.text.trim());

    setState(() {
      widget.match.gameA = ga;
      widget.match.gameB = gb;
    });

    Navigator.pop(context);
  }

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
            Text('${_name(m.a1)} & ${_name(m.a2)}  vs  ${_name(m.b1)} & ${_name(m.b2)}'),
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
