# Send Control Privacy Notes 日本語版

English PRIVACY: [PRIVACY.md](PRIVACY.md)

## この文書について

これは 2026-03-08 時点の GitHub technical preview 向け packaging note です。法的な privacy policy ではなく、将来の build すべてを対象にするものでもありません。

## Send Control が監視するもの

Send Control は、権限付与後に macOS の session event tap をインストールします。現在の source tree では、次の情報を監視します。

- グローバルな `keyDown` と `keyUp` のキーボードイベント
- リマップ対象候補としての Return (`keyCode 36`) と keypad Enter (`keyCode 76`) のみ
- Command、Control、Option の動作を保ちつつ Shift+Return を判別するために必要な modifier flags
- そのキーイベントをリマップするか判断するために必要な、前面アプリの bundle identifier

## Input Monitoring が必要な理由

現在の実装では、Return と Shift+Return を判定するためにグローバルな `keyDown` / `keyUp` イベントを監視します。そのため、Input Monitoring がないと対象キーイベントを受け取れず、リマップ処理を開始できません。

## Accessibility が必要な理由

現在の実装では、event tap を開始する前に Accessibility の trusted 状態を確認します。source tree 内のログ文言でも、`CGEvent.tapCreate` 失敗時に Accessibility permission と app trust の確認を促しています。Accessibility がないと event tap の開始または維持に失敗し、Return のリマップを有効化できません。

## Send Control が保存しないもの

現在の source tree に基づくと、Send Control は次の情報を保存しません。

- 入力したテキスト
- メッセージ本文
- キーストローク履歴
- クリップボード内容
- スクリーンショット
- 使用したアプリの一覧
- ネットワーク分析データやクラウドデータ

現在の source tree がローカルに保存するのは、protection を最後に ON のままにしたか OFF のままにしたか、という 1 つの設定だけです。macOS 自体は permission records や unified logs を保持する場合があります。この package 自体は独自の telemetry や sync service を追加していません。

## Send Control が送信するもの

今回の packaging pass で確認した current source tree には、ネットワーク送信ロジックは見つかりませんでした。

## OFF にする方法

Send Control を一時的に OFF にするには:

1. メニューバーの Send Control アイコンを開きます。
2. protection を OFF に切り替えます。

現在の source tree では、この ON/OFF 状態はローカル設定として保存され、次回起動時にも参照されます。

## 権限を外す方法

Send Control の権限を外すには:

1. アプリを終了します。
2. `システム設定 > プライバシーとセキュリティ > アクセシビリティ` を開きます。
3. Send Control の項目を OFF にするか削除します。
4. `システム設定 > プライバシーとセキュリティ > 入力監視` を開きます。
5. Send Control の項目を OFF にするか削除します。
6. もう不要であればアプリを削除します。
