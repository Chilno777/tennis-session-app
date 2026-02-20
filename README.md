# Tennis Match Manager App

## 概要
テニスの練習活動を効率化するために開発した、
ダブルス対戦表生成＆スコア管理アプリ。

## 開発背景
・毎回の練習で対戦表作成に時間がかかっていた  
・スコアが記録されず個人成績が残らなかった  
・練習会ごとにデータを独立管理したかった  

## 設計思想
本アプリでは「セッション単位で状態を管理」する設計を採用。

- Sessionクラスを導入
- 練習会ごとにMatchとScoreを保持
- 将来的なDB保存を見据えた構造

##　技術構成
- Flutter
- Dart
- StatefulWidgetベースの状態管理
- Gitによるバージョン管理

## 設計ドキュメント
詳細設計は docs フォルダを参照：

- architecture.md
- session_design.md
- match_logic.md
- state_management.md

##  今後の実装予定
- SQLite保存機能
- 個人成績ページの強化
- 勝率・ペア相性分析機能
- Firebase連携
