## English

Send Control v1.1 is a GitHub technical preview / beta package for advanced macOS users and testers. It is not intended for general users.

### Status

- Technical preview / beta
- Not notarized
- No Developer ID distribution
- Requires macOS 13 or later

### Before First Launch

1. Download `Send Control.app.zip` and `SHA256SUMS.txt`.
2. Unzip `Send Control.app.zip`.
3. Move `Send Control.app` to `/Applications` before the first launch.
4. Open the app with Finder `Open` / `Open Anyway` if macOS blocks it.

### Permissions Required

Send Control requires both:

- Accessibility
- Input Monitoring

Without both permissions, the event tap stays OFF and Return remapping will not work.

### Attached Assets

- `Send Control.app.zip`
- `SHA256SUMS.txt`

### Related Documents

- `README.md` / `README.ja.md`
- `INSTALL.md` / `INSTALL.ja.md`
- `PRIVACY.md` / `PRIVACY.ja.md`
- `KNOWN_ISSUES.md` / `KNOWN_ISSUES.ja.md`
- `RELEASE_NOTES_v1.1_beta.md` / `RELEASE_NOTES_v1.1_beta.ja.md`

### Notes

- This preview is for advanced macOS users who can work through Gatekeeper warnings, manual permission setup, and troubleshooting.
- If `/Applications/Send Control.app` already exists, a preview copy launched from another folder can redirect to the installed app.
- GitHub-generated source code archives are source snapshots only. They are not the built app and are not a substitute for `Send Control.app.zip`.

### Feedback

Feedback is welcome through GitHub Discussions and GitHub Issues, especially for:

- first-launch behavior on a clean Mac,
- Gatekeeper and `Open Anyway` flow,
- Accessibility / Input Monitoring setup,
- Return remapping behavior in target apps,
- regression reports with macOS version, target app name, and exact reproduction steps.

---

## 日本語

Send Control v1.1 は、advanced macOS users とテスター向けの GitHub technical preview / beta package です。一般ユーザー向けではありません。

### ステータス

- Technical preview / beta
- Not notarized
- Developer ID 配布ではない
- macOS 13 以降が必要

### 最初の起動前に行うこと

1. `Send Control.app.zip` と `SHA256SUMS.txt` を取得します。
2. `Send Control.app.zip` を展開します。
3. 最初に起動する前に、`Send Control.app` を `/Applications` に移動します。
4. macOS にブロックされた場合は、Finder の `開く` または `このまま開く` を使って起動します。

### 必要な権限

Send Control には次の両方が必要です。

- Accessibility
- Input Monitoring

両方そろっていないと event tap は OFF のままで、Return のリマップは動作しません。

### 添付 asset

- `Send Control.app.zip`
- `SHA256SUMS.txt`

### 関連文書

- `README.md` / `README.ja.md`
- `INSTALL.md` / `INSTALL.ja.md`
- `PRIVACY.md` / `PRIVACY.ja.md`
- `KNOWN_ISSUES.md` / `KNOWN_ISSUES.ja.md`
- `RELEASE_NOTES_v1.1_beta.md` / `RELEASE_NOTES_v1.1_beta.ja.md`

### 補足

- この preview は、Gatekeeper 警告、手動の権限設定、トラブルシュートに対応できる advanced macOS users 向けです。
- すでに `/Applications/Send Control.app` がある場合、別フォルダから起動した preview copy がインストール済み app にリダイレクトされることがあります。
- GitHub が自動生成する source code archive は source snapshot であり、アプリ本体ではありません。`Send Control.app.zip` の代わりにはなりません。

### フィードバック

GitHub Discussions / Issues でのフィードバックを歓迎します。特に次の内容が有用です。

- clean な Mac での first-launch behavior
- Gatekeeper と `このまま開く` の挙動
- Accessibility / Input Monitoring の設定体験
- Return remapping が必要な target app での挙動
- macOS version、target app 名、正確な再現手順を含む regression report
