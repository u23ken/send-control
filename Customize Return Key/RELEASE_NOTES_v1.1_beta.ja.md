# Send Control v1.1 Beta Release Notes 日本語版

English RELEASE_NOTES: [RELEASE_NOTES_v1.1_beta.md](RELEASE_NOTES_v1.1_beta.md)

Date: 2026-03-08

## 概要

この package は、`release/send-control-1.1` をベースにした Send Control 初の GitHub technical preview / beta pack です。今回の主目的は public-release packaging であり、機能拡張ではありません。この package ではアプリ本体の機能変更は行っていません。

## この pack に含まれるもの

- `Send Control.app` の Release build
- `Send Control.app.zip`
- `SHA256SUMS.txt`
- `README.md`
- `INSTALL.md`
- `PRIVACY.md`
- `KNOWN_ISSUES.md`

## v1.1 の現在位置

- App version metadata: `1.1`
- Bundle identifier: `com.sendcontrol.app`
- Minimum macOS target: `13.0`
- Distribution status: technical preview / beta
- Notarization status: not notarized

## できること

- メニューバー app として動作する
- Accessibility と Input Monitoring の権限を使う
- CGEvent tap を使って Return と Shift+Return をリマップする
- protection 状態を復元するために必要なローカル ON/OFF 設定だけを保存する

## まだ制限があること

- Developer ID signing はこの pack の対象外です
- notarization はこの pack の対象外です
- installer package creation はこの pack の対象外です
- app feature changes はこの pack の対象外です

## GitHub で歓迎するフィードバック

- clean な Mac での first-launch experience
- Gatekeeper と `Open Anyway` の挙動
- Accessibility と Input Monitoring の設定体験
- Return remapping が重要な target app での挙動
- macOS version、target app 名、正確な再現手順を含む regression report
