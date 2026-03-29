<p align="center">
  <img src="SendControl/assets/sendcontrol-icon-macos-1024.png" width="128" height="128" alt="Send Control アイコン">
</p>

<h1 align="center">Send Control</h1>

<p align="center">
  Return キーと Shift+Return をシステムレベルで入れ替える macOS メニューバーユーティリティ。
  <br>
  <a href="README.md">English</a>
</p>

<p align="center">
  <a href="https://github.com/u23ken/send-control/releases"><img src="https://img.shields.io/github/v/release/u23ken/send-control" alt="Release"></a>
  <a href="https://github.com/u23ken/send-control/releases"><img src="https://img.shields.io/github/downloads/u23ken/send-control/total" alt="Downloads"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/u23ken/send-control" alt="License"></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-blue" alt="macOS 13+">
  <img src="https://img.shields.io/badge/署名-Developer%20ID-green" alt="署名済み">
  <img src="https://img.shields.io/badge/公証-Apple-green" alt="公証済み">
</p>

<p align="center"><img src="docs/screenshot.png" width="360" alt="Send Control メニュー"></p>

## 機能

Send Control は CGEvent tap を使って Return キーのイベントを入れ替えます。

- **Return** → Shift+Return（チャットアプリで改行せずに送信）
- **Shift+Return** → Return（改行を挿入）

システム全体で動作します。アプリごとの除外設定はメニューバーから変更できます。

## ダウンロード

<a href="https://github.com/u23ken/send-control/releases/latest">
  <strong>⬇ 最新版をダウンロード</strong>
</a>

Developer ID で署名済み、Apple による公証済みのため、Gatekeeper 警告なしで起動できます。

## インストール

1. [Releases](https://github.com/u23ken/send-control/releases) から `Send-Control-v*.zip` をダウンロード
2. 展開して `Send Control.app` を `/Applications/` に移動
3. 起動して 2 つの権限を付与:
   - **アクセシビリティ**（`システム設定 > プライバシーとセキュリティ > アクセシビリティ`）
   - **入力監視**（`システム設定 > プライバシーとセキュリティ > 入力監視`）

詳しい手順は [INSTALL.ja.md](INSTALL.ja.md) を参照してください。

## 特徴

- CGEvent tap レイヤーで Return ↔ Shift+Return を入れ替え
- アプリごとの除外リスト（メニューバーから設定可能）
- modifyOtherKeys / kitty protocol 対応のターミナル安全モード
- 初回セットアップ用の権限ガイドUI
- 自動復旧付きヘルスチェック
- 二重起動防止
- 約1400行、純粋な AppKit、外部依存なし

## 動作要件

- macOS 13（Ventura）以降
- アクセシビリティおよび入力監視の権限
- Mac App Store では配布不可（CGEvent tap は App Sandbox と非互換）

## ドキュメント

| | English | 日本語 |
|---|---|---|
| インストール | [INSTALL.md](INSTALL.md) | [INSTALL.ja.md](INSTALL.ja.md) |
| プライバシー | [PRIVACY.md](PRIVACY.md) | [PRIVACY.ja.md](PRIVACY.ja.md) |
| 既知の問題 | [KNOWN_ISSUES.md](KNOWN_ISSUES.md) | [KNOWN_ISSUES.ja.md](KNOWN_ISSUES.ja.md) |
| クイックスタート | — | [QUICKSTART_BEGINNER.ja.md](QUICKSTART_BEGINNER.ja.md) |

## ライセンス

[Apache-2.0](LICENSE)
