# Send Control プライバシーノート

English PRIVACY: [PRIVACY.md](PRIVACY.md)

## Send Control が監視するもの

Send Control は、権限付与後に macOS の session event tap をインストールします。監視する情報:

- グローバルな `keyDown` と `keyUp` のキーボードイベント
- リマップ対象候補としての Return (`keyCode 36`) と keypad Enter (`keyCode 76`) のみ
- Command、Control、Option の動作を保ちつつ Shift+Return を判別するために必要な modifier flags
- キーイベントをリマップするか判断するために必要な、前面アプリの bundle identifier

## Send Control が保存しないもの

Send Control は次の情報を保存しません。

- 入力したテキスト
- メッセージ本文
- キーストローク履歴
- クリップボード内容
- スクリーンショット
- 使用したアプリの一覧
- ネットワーク分析データやクラウドデータ

ローカルに保存するのは、protection の ON/OFF 状態と、ユーザーが設定したアプリ除外リストの 2 つだけです。macOS 自体は permission records や unified logs を保持する場合があります。Send Control は独自の telemetry や sync service を追加していません。

## Send Control が送信するもの

Send Control にはネットワーク送信ロジックはありません。サーバーへの接続は行いません。

## 権限を外す方法

Send Control の権限を外すには:

1. アプリを終了します。
2. `システム設定 > プライバシーとセキュリティ > アクセシビリティ` を開きます。
3. Send Control の項目を OFF にするか削除します。
4. `システム設定 > プライバシーとセキュリティ > 入力監視` を開きます。
5. Send Control の項目を OFF にするか削除します。
6. 不要であればアプリを削除します。

## この文書の範囲

この文書は Send Control の現在のバージョンについて記述しています。法的なプライバシーポリシーではありません。
