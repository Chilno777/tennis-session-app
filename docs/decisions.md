〇機能追加の流れ
①状態確認
git status
git log --oneline -5

②実装前ログ
# docs/decisions.md に追記（なぜ/何を/仕様）してからコミット
git add.
git commit -m "feat: 何をしたか" -m "理由" -m "詳細"

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

## 2026/2/17 会ごとにスコアを保持できるように
背景：スコアを練習会ごとに保持できるようにしたい
決定：新class Sessionを追加
影響：MatchListPageがSessionを受け取れるようにする

## 2026/2/18 セッションごとに履歴を保存
背景：接しオンごとに状態を独立させたい
決定：DBをsessionに移行していく
影響：sessionの保存→DBの保存になる
    　（実装前コミット済み）