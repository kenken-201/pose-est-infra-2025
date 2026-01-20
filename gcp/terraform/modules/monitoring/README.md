# Monitoring Module

Cloud Monitoring のアラートと通知チャンネルを管理する Terraform モジュール。

## 機能

- Email 通知チャンネルの作成
- Cloud Run エラー率アラート
- Cloud Run レイテンシアラート
- アラート発生時の対応手順 (documentation) 埋め込み

## 使用方法

```hcl
module "monitoring" {
  source = "../../modules/monitoring"

  project_id             = "your-project-id"
  environment            = "dev"
  service_name           = "your-cloud-run-service"
  gcp_notification_email = "alerts@example.com"

  # オプション: 閾値のカスタマイズ
  error_rate_threshold = 0.05  # 5% (デフォルト)
  latency_threshold_ms = 5000  # 5秒 (デフォルト)
}
```

## 入力変数

| 変数名                   | 型     | 必須 | デフォルト | 説明                            |
| ------------------------ | ------ | ---- | ---------- | ------------------------------- |
| `project_id`             | string | ✅   | -          | GCP プロジェクト ID             |
| `environment`            | string | ✅   | -          | 環境名 (dev, prod)              |
| `service_name`           | string | ✅   | -          | 監視対象の Cloud Run サービス名 |
| `gcp_notification_email` | string | ✅   | -          | アラート通知先メールアドレス    |
| `error_rate_threshold`   | number | -    | 0.05       | エラー率閾値 (0.0〜1.0)         |
| `latency_threshold_ms`   | number | -    | 5000       | レイテンシ閾値 (ミリ秒)         |

## 出力

| 出力名                    | 説明                                   |
| ------------------------- | -------------------------------------- |
| `notification_channel_id` | 作成された通知チャンネル ID            |
| `alert_policy_ids`        | 作成されたアラートポリシー ID のリスト |

## 関連ドキュメント

- [監視アーキテクチャ概要](../../docs/monitoring-overview.md)
- [アラート対応プレイブック](../../docs/alert-playbook.md)
