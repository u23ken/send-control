# Send Control Manual

## 概要

Send Control は、`Return` と `Shift+Return` を入れ替える macOS メニューバーアプリです。

- `Return` を押すと `Shift+Return` を送信
- `Shift+Return` を押すと `Return` を送信
- `Command` / `Control` / `Option` を含む入力はそのまま通します
- `Return` キーとテンキーの `Enter` キーの両方を対象にします

現在の版では、前面アプリが `Send Control` 自身でない限り、この入れ替えが有効です。

## 動作条件

- macOS 13 以降
- `Accessibility`
- `Input Monitoring`

## インストール

1. `Send Control.app` を `/Applications` に置きます
2. `Send Control.app` を起動します
3. メニューバーに Send Control のアイコンが出ることを確認します

`Send Control` は `/Applications/Send Control.app` を正規の配置先として扱います。別の場所から起動した場合、`/Applications` 側の app があればそちらを開いて終了します。

## 使い方

1. メニューバーの `Send Control` アイコンをクリックします
2. 先頭のスイッチを `ON` にします
3. macOS から権限を求められたら許可します

権限が不足している状態で `ON` にすると、必要な設定画面が開きます。

- `Accessibility`
  - System Settings > Privacy & Security > Accessibility
- `Input Monitoring`
  - System Settings > Privacy & Security > Input Monitoring

両方で `Send Control` を有効にしてください。

## メニュー

- 先頭スイッチ: 保護の `ON` / `OFF`
- `About Send Control`
- `Quit`

`OFF` のときはメニューバーアイコンが薄く表示されます。

## 注意

- Dock には常駐しません。メニューバーだけに表示されます
- 同じ bundle ID の `Send Control` は 1 つだけ実行されます
- 権限が外れた場合は保護が `OFF` になります
- 現在の版には対象アプリを絞る設定 UI はありません

## うまく動かないとき

1. `/Applications/Send Control.app` だけを残し、古い copy を消します
2. `Accessibility` と `Input Monitoring` の両方で `Send Control` が有効か確認します
3. メニューバーのスイッチが `ON` になっているか確認します
4. 直らない場合は `Quit` してから再起動します
