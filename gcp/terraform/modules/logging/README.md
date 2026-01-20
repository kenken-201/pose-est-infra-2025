# Logging Module

Cloud Logging のログ除外フィルターを管理する Terraform モジュール。

## 機能

- ヘルスチェック成功ログの除外（ノイズ削減）
- DEBUG レベルログの除外（本番環境のみ）
- 障害調査時の一時無効化機能

## 使用方法

```hcl
module "logging" {
  source = "../../modules/logging"

  project_id  = "your-project-id"
  environment = "dev"

  # オプション: フィルター制御
  exclude_health_check_logs      = true   # デフォルト
  exclude_debug_logs_in_prod     = true   # デフォルト
  disable_health_check_exclusion = false  # 障害調査時に true
  disable_debug_log_exclusion    = false  # 障害調査時に true
}
```

## 入力変数

| 変数名                           | 型     | 必須 | デフォルト | 説明                               |
| -------------------------------- | ------ | ---- | ---------- | ---------------------------------- |
| `project_id`                     | string | ✅   | -          | GCP プロジェクト ID                |
| `environment`                    | string | ✅   | -          | 環境名 (dev, prod)                 |
| `exclude_health_check_logs`      | bool   | -    | true       | ヘルスチェックログを除外するか     |
| `exclude_debug_logs_in_prod`     | bool   | -    | true       | DEBUG ログを除外するか (prod のみ) |
| `disable_health_check_exclusion` | bool   | -    | false      | ヘルスチェック除外を一時無効化     |
| `disable_debug_log_exclusion`    | bool   | -    | false      | DEBUG 除外を一時無効化             |

## 出力

| 出力名             | 説明                                 |
| ------------------ | ------------------------------------ |
| `exclusion_names`  | 作成された除外フィルター名のリスト   |
| `exclusion_ids`    | 作成された除外フィルター ID のリスト |
| `exclusion_status` | 各フィルターの有効/無効状態          |

## 障害調査時の一時無効化

ログ除外フィルターを一時的に無効化して、除外されていたログを確認できます。

```hcl
# terraform.tfvars または環境変数で設定
disable_health_check_exclusion = true
disable_debug_log_exclusion    = true
```

調査完了後は `false` に戻してください。

## 関連ドキュメント

- [監視アーキテクチャ概要](../../docs/monitoring-overview.md)
