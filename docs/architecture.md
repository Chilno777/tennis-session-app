# Architecture

## 全体構造

UI
↓
Session
↓
Match
↓
Score

## 責務分離

- UI：表示のみ
- Session：練習単位のデータ管理
- Match：1試合の情報
- Score：スコア状態

### 2026/2/21 参加者状態の管理
参加者の選択状態はUIではなくSessionが保持する。
UIはSessionを参照・更新するだけの役割。
