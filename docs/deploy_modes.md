# Send Control 配布運用（再発防止）

## 目的
- 通常更新では権限を保持して手間を減らす
- 不具合時のみ権限を初期化してクリーン再セットアップする

## 通常更新（推奨）
- 既存の Accessibility / Input Monitoring の許可を保持する
- コマンド:

```bash
"/Users/ken/Documents/Trush/Codex/Customize Return Key/tools/deploy_send_control.sh"
```

## トラブル復旧（初回インストール相当）
- 権限をリセットして、再許可の手順を最初からやり直す
- コマンド:

```bash
"/Users/ken/Documents/Trush/Codex/Customize Return Key/tools/deploy_send_control.sh" --fresh-permissions
```

## 補足
- スクリプトは毎回、古い `Send Control.app` / `IMEFix.app` のコピーを削除してから再配置する
- `--fresh-permissions` のときだけ TCC（Accessibility / ListenEvent）をリセットする
