# Send Control Technical Preview のインストール

English INSTALL: [INSTALL.md](INSTALL.md)

## 対象範囲

この手順は、2026-03-08 時点の GitHub technical preview package 向けです。この build は notarized ではありません。

## 1. ダウンロードと検証

1. `Send Control.app.zip` と `SHA256SUMS.txt` をダウンロードします。
2. 次のコマンドで ZIP の checksum を確認します。

```bash
shasum -a 256 "Send Control.app.zip"
```

3. 出力結果を `SHA256SUMS.txt` 内の `Send Control.app.zip` の値と比較します。

## 2. Mac の準備

1. すでに `/Applications/Send Control.app` がある場合は、この preview を試す前にいったん移動してください。
2. `Send Control.app.zip` を展開します。
3. `Send Control.app` をホームフォルダ配下の任意の場所に置きます。たとえば `~/Applications/` または `~/Desktop/Send Control Preview/` です。

## 3. アプリを開く

1. Finder で `Send Control.app` を Control-クリックします。
2. `開く` を選びます。
3. 開発元未確認 app の警告が表示された場合は、`開く` を確認します。
4. Finder からまだ開けない場合は、`システム設定 > プライバシーとセキュリティ` で `このまま開く` を選び、再度試します。

テスター向けの任意の高度な回避策:

```bash
xattr -dr com.apple.quarantine "Send Control.app"
```

このコマンドは、セキュリティ上のトレードオフを理解している場合にだけ使ってください。

## 4. 必要な権限を付与する

Send Control には、次の両方の権限が必要です。

1. `システム設定 > プライバシーとセキュリティ > アクセシビリティ`
2. `システム設定 > プライバシーとセキュリティ > 入力監視`

権限付与後に protection が自動で ON にならない場合は、アプリを再起動してください。

## 5. 動作確認

1. Send Control のメニューバーアイコンが表示されていることを確認します。
2. メニューバー項目を開き、protection が ON であることを確認します。
3. 対象アプリで Return と Shift+Return を試します。

## 6. Preview を削除する

1. メニューバーから Send Control を終了します。
2. `Send Control.app` を削除します。
3. もう使わない場合は、Accessibility と Input Monitoring の権限エントリも削除します。詳しくは [PRIVACY.md](PRIVACY.md) を参照してください。
