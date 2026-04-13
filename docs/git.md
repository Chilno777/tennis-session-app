gitの使い方について

git add .
git commit -m ""
git push


〇機能追加の流れ
①状態確認
git status
git log --oneline -5

②実装前ログ
# docs/decisions.md に追記（なぜ/何を/仕様）してからコミット
git add docs/architecture.md
git add docs/code.md
git add docs/decisions.md
git add docs/matich_logic.md
git commit -m "docs: "

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