# Known Issues 日本語版

English KNOWN_ISSUES: [KNOWN_ISSUES.md](KNOWN_ISSUES.md)

## この文書について

これは GitHub technical preview 向けの既知の制限事項メモです。一般ユーザー向けではなく、現時点で確認できている technical preview 特有の注意点をまとめています。

## Packaging と起動に関する既知の制限事項

- この technical preview は notarized ではありません。初回起動時は Gatekeeper の手動承認が必要です。
- すでに `/Applications/Send Control.app` が存在する場合、別フォルダに置いた preview copy を起動しても、インストール済み app 側へリダイレクトされることがあります。
- 同じ bundle identifier のインスタンスは 1 つしか動作できません。2 つ目を起動すると終了します。

## 想定される失敗例

- 初回起動時に「開発元を確認できない app」として macOS にブロックされる
- preview copy を起動したつもりでも、実際には `/Applications` 側の既存 app が開く
- すでに同一 bundle identifier の Send Control が起動中だと、あとから起動した copy が終了する

## ユーザーが回避できること

- 初回起動でブロックされた場合は、Gatekeeper の手動承認を行ってください。
- `/Applications/Send Control.app` がある場合は、preview を試す前に既存 copy を移動または削除してください。
- 二重起動を避け、起動中の Send Control がある場合はいったん終了してから試してください。

## 権限に関する既知の制限事項

- Accessibility と Input Monitoring は両方とも必要です。どちらかが欠けると event tap は OFF のままです。
- 権限設定を変更した直後は、protection がすぐに有効化されず、アプリの終了と再起動が必要になる場合があります。

## 権限まわりの想定される失敗例

- Accessibility または Input Monitoring のどちらか片方だけ付与して、protection が ON にならない
- 権限を付与した直後でも反映されず、event tap が OFF のまま見える

## 権限まわりで回避できること

- 2 種類の権限が両方付与されているか確認してください。
- 権限変更後に protection が有効にならない場合は、アプリを終了して再起動してください。

## 現時点で未対応のこと

- installer はありません。
- updater はありません。
- notarized distribution flow はありません。

## サポート上の前提

- この package はテスター向けであり、一般ユーザー向けではありません。
- macOS のバージョンや対象アプリごとの差異がある場合は、正確な再現手順がないと評価できません。
