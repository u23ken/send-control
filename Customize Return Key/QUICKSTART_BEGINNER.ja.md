# Send Control 超初心者向けクイックスタート

この文書は、GitHub technical preview / beta を試すテスター向けの簡易手順です。説明はできるだけやさしくしていますが、この配布物自体は一般ユーザー向けではありません。

## 先に知っておくこと

- この build は notarized ではありません。
- 初回起動時に macOS が止めることがあります。
- `Accessibility` と `Input Monitoring` の両方が必要です。
- 最初に起動する前に、`Send Control.app` を `/Applications` に移動してください。

## いちばん短い手順

1. GitHub Release から `Send Control.app.zip` をダウンロードします。
2. `Send Control.app.zip` をダブルクリックして展開します。
3. 出てきた `Send Control.app` を `/Applications` フォルダへドラッグします。
4. `/Applications` の中の `Send Control.app` を Control-クリックして、`開く` を選びます。右クリックできる場合は右クリックでもかまいません。
5. 警告が出たら、必要に応じて `システム設定 > プライバシーとセキュリティ` で `このまま開く` を選びます。
6. 起動したら、画面の案内に従って `システム設定` を開き、`アクセシビリティ` と `入力監視` の両方で Send Control を ON にします。
7. 権限を変更したあと、反映されない場合はいったんアプリを終了して、もう一度開きます。
8. 画面上部のメニューバーに Send Control のアイコンが出て、protection が `ON` になっているか確認します。

## 迷いやすいところ

### 1. ZIP を開いただけでは終わりではありません

ZIP を展開したあと、すぐに開くのではなく、先に `Send Control.app` を `/Applications` に移動してください。

### 2. 「開発元を確認できません」と出ることがあります

これは今回の technical preview では想定内です。notarized ではないためです。

対処:

1. Finder で `Send Control.app` を Control-クリックします。
2. `開く` を選びます。
3. まだ止められる場合は、`システム設定 > プライバシーとセキュリティ` を開きます。
4. Send Control についての表示があれば、`このまま開く` を選びます。

### 3. 権限を許可しないと動きません

Send Control は次の 2 つの権限が必要です。

- `アクセシビリティ`
- `入力監視`

どちらか一方だけでは足りません。両方必要です。

権限を ON にする手順:

1. Send Control を開いたあと、`システム設定` を開きます。
2. `プライバシーとセキュリティ > アクセシビリティ` を開きます。
3. 一覧に Send Control があればスイッチを ON にします。なければ `+` で `Send Control.app` を追加して ON にします。
4. 次に `プライバシーとセキュリティ > 入力監視` を開きます。
5. 一覧に Send Control があればスイッチを ON にします。なければ `+` で `Send Control.app` を追加して ON にします。
6. macOS から終了や再起動を求められた場合は、その案内に従います。

### 4. 権限を許可したのに動かないことがあります

権限変更の直後は反映が遅れることがあります。

対処:

1. Send Control をいったん終了します。
2. もう一度 `Send Control.app` を開きます。
3. 画面上部のメニューバーで protection が `ON` になっているか確認します。

## 動いているか確認する方法

- 画面上部のメニューバーに Send Control のアイコンが見える
- そのアイコンをクリックすると protection が `ON` になっている
- 対象アプリで Return / Shift+Return の動作を試せる

## うまくいかないとき

- `README.ja.md` を確認する
- `INSTALL.ja.md` を確認する
- `PRIVACY.ja.md` を確認する
- `KNOWN_ISSUES.ja.md` を確認する
- GitHub Discussions / Issues に、macOS のバージョン、使ったアプリ名、起きたことを具体的に書いて報告する

## やめたいとき

1. メニューバーから Send Control を終了します。
2. `/Applications/Send Control.app` を削除します。
3. 必要なら `アクセシビリティ` と `入力監視` の権限も外します。
