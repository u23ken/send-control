# Send Control 配布運用（再発防止）

## 目的
- 通常更新では権限を保持して手間を減らす
- 不具合時のみ権限を初期化してクリーン再セットアップする

## 通常更新（推奨）
- 既存の Accessibility / Input Monitoring の許可を保持する
- コマンド:

```bash
"./tools/deploy_send_control.sh"
```

## トラブル復旧（初回インストール相当）
- 権限をリセットして、再許可の手順を最初からやり直す
- コマンド:

```bash
"./tools/deploy_send_control.sh" --fresh-permissions
```

## 補足
- スクリプトは毎回、古い `Send Control.app` / `IMEFix.app` のコピーを削除してから再配置する
- `--fresh-permissions` のときだけ TCC（Accessibility / ListenEvent）をリセットする

## GitHub 公開用 zip の作り方
- 公開用 asset は次で作る:

```bash
"./tools/package_release_zip.sh"
```

- この script は次をまとめて行う:
  - 通常の Release build
  - app bundle の署名整合性確認
  - zip 化
  - 展開後の再確認

- `CODE_SIGNING_ALLOWED=NO` で作った build から zip を作らない
