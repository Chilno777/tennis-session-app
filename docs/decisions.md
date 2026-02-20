〇機能追加の流れ
①状態確認
git status
git log --oneline -5

②実装前ログ
# docs/decisions.md に追記（なぜ/何を/仕様）してからコミット
git add docs/decisions.md
git commit -m "docs: ○○機能の設計を記録"

③実装：コード変更
# 変更内容確認
git diff

④動作確認：仕様のチェックを行う

⑤機能コミット
git add .
git commit -m "feat: ○○を追加" -m "要点1" -m "要点2"


feat: 新機能
fix: バグ修正
refactor: リファクタリング（挙動は同じで整理）
docs: ドキュメント変更
style: UIやフォーマット変更

〇実装ログ確認
git log --oneline


〇戻す操作
・安全に過去を見る
git log --oneline
git switch --detach <コミットID>
# 戻る
git switch master

・完全に戻す（消える）
git reset --hard <コミットID>

〇再開
①エミュレーターを起動
vutual device manager(Android studio) で　pixel5を起動

②ターミナルで
flutter run

③状態確認
git status
1.今どのブランチ？(*がついている)
 開発ライン
 master → 安定版

feature/session → セッション機能開発用

fix/score-bug → バグ修正用

2.何が変更された？
前回コミットした状態と、今のファイルの差

3.ステージ済みか？
gitの構造
① 作業ディレクトリ（編集中）
② ステージ（コミット予定）
③ リポジトリ（保存済み）
Changes not staged	編集したけど add してない
Changes to be committed	add 済み
nothing to commit	変更なし

４．git diff
何を編集したのかが分かる



# 意思決定ログ (Decisions)

## 2026-02-16 履歴管理を開始
- 背景/課題: コードを一新すると壊れるのが怖い。変更を安全に積み重ねたい。
- 決定: Gitで変更履歴を管理する。
- 期待する効果: いつでも過去の状態に戻せる／変更理由を説明できる。

## 2026-02-16 個人成績ページ（①）を追加
- 背景/課題: 試合結果（gameA/gameB）は入力しているが、個人の成績が見えない
- 決定: MatchPickの gameA/gameB をそのまま利用し、未入力試合は集計対象外にする
- ランキング: 総獲得ゲーム数（gamesFor）降順（暫定）
- 影響: 集計関数をMatchListPageのStateに追加し、StatsPageへ遷移導線を追加

## 2026/02/17 練習ごとにスコアを保持できるように
背景：スコアを練習会ごとに保持したい
決定：新class Sessionを追加、試合、成績をセッション下に持たせる
仕様：セッション切り替えでmatchs/statsが混ざらない
影響：MatchListPageがSessionを受け取れるようにする
　　　表示/集計は session.matches から行う
未決: セッションの作成/選択UI（どこに置くか）

## 2026/02/18 セッションごとに履歴を永続化
背景：セッションごとに状態を独立され、履歴として残す
決定：永続化の単位を「アプリ全体」→「Session」へ移行
仕様：「アプリ再起動後もセッション一覧と内容が復元される」
影響: 保存/読込の入口が SessionRepository（仮）に集約される（UIはRepository経由）
    　（実装前コミット済み）次回ここから！！