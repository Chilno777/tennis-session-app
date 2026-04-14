# Bug Log

## 2026/2/17
問題：onPressed追加後にUI崩壊
原因：BuildContextの扱いミス
修正：Navigatorの配置修正

学び：
UIとロジックを分離する重要性を理解

## 2026/2/20
問題：session分離後に呼び出しエラー
原因：①_selectedMemberIndexes() が存在しない
     ②556行目付近の CheckboxListTile が「returnされてない」
修正：addMatch()を修正
final members = _selectedMemberIndexes();
→final members = List<int>.from(widget.session.participantIndexes);

学び：
①return忘れなど、根本的なミス一戸から総崩れ
②コピペしたら、関数、変数の依存関係を確認
③builderは必ずwidgetをリターンする
ないと、式を実行しただけでUIが壊れる

コピペ後は静的解析でエラー０になるまで進まないようにしよう

UIをヘルパー関数に分割

状態管理を _selected → session.participantIndexes に統一

build構造を整理

未使用コードを削除

2026/04/14
問題：セッションが消える
原因：SessionListPage の State 内に final List<Session> _sessions = []; を持っていて、PlayerRegisterPage から SessionListPage を開くたびに新しい画面インスタンスが作られるので、セッション一覧が初期化されてしまう。
修正：SessionListPage で持っていた _sessions
を
PlayerRegisterPage 側へ持ち上げて
SessionListPage に参照で渡す

形にする。