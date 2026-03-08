# Send Control GitHub Technical Preview 日本語版

English README: [README.md](README.md)

Send Control は、event tap レイヤーで Return と Shift+Return を入れ替える macOS のメニューバー常駐ユーティリティです。このパッケージは technical preview / beta であり、macOS のセキュリティ警告、手動の権限設定、トラブルシュートに対応できるテスター向けです。一般ユーザー向けではありません。

## ステータス

- Technical preview / beta
- `release/send-control-1.1` から作成した Release build
- Not notarized
- Developer ID 配布ではない
- macOS 13 以降が必要
- Accessibility と Input Monitoring の両方が必要

## ダウンロードするもの

- `Send Control.app.zip`
- `SHA256SUMS.txt`

## 起動前に確認すること

- まず [INSTALL.md](INSTALL.md) を読んでください。
- 権限を付与する前に [PRIVACY.md](PRIVACY.md) を読んでください。
- 現在わかっている制限は [KNOWN_ISSUES.md](KNOWN_ISSUES.md) を確認してください。
- `Send Control.app.zip` を展開したら、最初に起動する前に `Send Control.app` を `/Applications` へ移動してください。
- すでに `/Applications/Send Control.app` がある場合は、この technical preview を試す前に既存コピーを移動するか削除してください。この build はインストール済みコピーへリダイレクトする場合があります。

## 未検証アプリを開く方法

この build は notarized ではないため、最初の起動時に macOS がブロックすることがあります。

1. `Send Control.app.zip` を展開します。
2. `Send Control.app` を `/Applications` へ移動します。
3. Finder で `Send Control.app` を Control-クリックし、`開く` を選びます。
4. それでも macOS にブロックされる場合は、`システム設定 > プライバシーとセキュリティ` を開き、Send Control に関するメッセージの `このまま開く` を選びます。
5. もう一度アプリを起動し、`開く` を確認します。

## 必要な権限

Send Control には、次の macOS 権限が両方とも必要です。

- Accessibility
- Input Monitoring

どちらか一方でも不足していると、event tap は OFF のままになり、Return のリマップは動作しません。

## 対象ユーザー

この preview は、次のような対応ができる macOS に慣れたテスター向けです。

- Gatekeeper の警告に対応できる
- システム設定で権限状態を確認できる
- アプリごとの差異を比較できる
- 再現手順を具体的に報告できる

このパッケージの背景は [RELEASE_NOTES_v1.1_beta.md](RELEASE_NOTES_v1.1_beta.md) を参照してください。
