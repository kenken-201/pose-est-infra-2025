# =============================================================================
# Monitoring Module - Cloud Run 監視設定
# =============================================================================
# 本モジュールは Cloud Run サービスの健全性を監視するためのアラートポリシーを提供します。
#
# 設計思想:
# - SRE ベストプラクティス: SLO/SLI に基づいたアラート設計
# - 低ノイズ: 誤検知を最小化する閾値とトリガー設定
# - 運用効率: 自動解決とドキュメント付きアラート
# - コスト最適化: 必要最小限のアラートで無料枠を活用

# 通知チャンネル (Email)
# -----------------------------------------------------------------------------
resource "google_monitoring_notification_channel" "email" {
  display_name = "[${upper(var.environment)}] Cloud Monitoring - Email"
  description  = "Cloud Run アラート通知チャンネル (${var.environment} 環境)"
  type         = "email"
  labels = {
    email_address = var.gcp_notification_email
  }

  # 通知チャンネルのメタデータ (フィルタリング等に活用)
  user_labels = {
    environment = var.environment
    managed_by  = "terraform"
    team        = "platform"
  }

  project = var.project_id
}

# アラートポリシー: Cloud Run エラー率上昇
# -----------------------------------------------------------------------------
# SLI: リクエストエラー率 (5xx / total)
# SLO: 99.9% 成功率 (= 0.1% エラー率以下)
resource "google_monitoring_alert_policy" "cloud_run_error_rate" {
  display_name = "[${upper(var.environment)}] Cloud Run: エラー率上昇 (>${var.error_rate_threshold * 100}%)"
  combiner     = "OR"
  enabled      = var.enable_alerts

  conditions {
    display_name = "5xx エラー率が閾値を超過"
    condition_threshold {
      # フィルタ: 指定サービスの 5xx エラー
      filter = <<-EOT
        resource.type = "cloud_run_revision"
        AND resource.labels.service_name = "${var.service_name}"
        AND metric.type = "run.googleapis.com/request_count"
        AND metric.labels.response_code_class = "5xx"
      EOT

      # 集計: 5分間のエラー率
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.labels.service_name"]
      }

      comparison      = "COMPARISON_GT"
      threshold_value = var.error_rate_threshold
      duration        = "60s"

      trigger {
        count = 1
      }
    }
  }

  # アラート自動解決設定 (SRE ベストプラクティス)
  alert_strategy {
    auto_close = "1800s" # 30分間正常なら自動解決
  }

  documentation {
    content   = <<-EOT
# 🚨 Cloud Run エラー率アラート

**環境**: ${var.environment}
**サービス**: ${var.service_name}
**閾値**: ${var.error_rate_threshold * 100}%

## 対応手順

1. **ログ確認**: Cloud Run のエラーログを確認し、根本原因を特定
   ```
   gcloud logging read 'resource.type="cloud_run_revision" AND severity>=ERROR' --limit=50
   ```

2. **直近デプロイ確認**: 最近のデプロイが原因であればロールバックを検討

3. **依存サービス確認**: R2 ストレージ、外部 API の障害有無を確認

4. **リソース確認**: CPU/メモリ使用率、インスタンス数を確認

## エスカレーション

30分以上継続する場合は開発チームにエスカレーションしてください。
EOT
    mime_type = "text/markdown"
  }

  # アラートのメタデータ
  user_labels = {
    severity    = "critical"
    category    = "availability"
    environment = var.environment
    managed_by  = "terraform"
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
  project               = var.project_id
}

# アラートポリシー: Cloud Run レスポンス遅延
# -----------------------------------------------------------------------------
# SLI: レスポンスレイテンシ (p95)
# SLO: 95% of requests complete within threshold
resource "google_monitoring_alert_policy" "cloud_run_latency" {
  display_name = "[${upper(var.environment)}] Cloud Run: レイテンシ上昇 (p95>${var.latency_threshold_ms}ms)"
  combiner     = "OR"
  enabled      = var.enable_alerts

  conditions {
    display_name = "レスポンス時間 (p95) が閾値を超過"
    condition_threshold {
      filter = <<-EOT
        resource.type = "cloud_run_revision"
        AND resource.labels.service_name = "${var.service_name}"
        AND metric.type = "run.googleapis.com/request_latencies"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_PERCENTILE_95"
        cross_series_reducer = "REDUCE_MAX"
        group_by_fields      = ["resource.labels.service_name"]
      }

      comparison      = "COMPARISON_GT"
      threshold_value = var.latency_threshold_ms
      duration        = "60s"

      trigger {
        count = 1
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = <<-EOT
# ⏱️ Cloud Run レイテンシアラート

**環境**: ${var.environment}
**サービス**: ${var.service_name}
**閾値**: ${var.latency_threshold_ms}ms (p95)

## 対応手順

1. **Cloud Trace 確認**: ボトルネックとなっている処理を特定
   - GCP Console > Trace を確認

2. **リソース使用率確認**: CPU/メモリ不足の可能性を調査
   - インスタンス数が上限に達していないか確認

3. **依存サービス確認**: R2 ストレージ等の外部依存のレイテンシを確認

4. **コールドスタート確認**: min_instances=0 の場合、コールドスタートが原因の可能性

## パフォーマンス改善策

- `min_instances` を 1 以上に設定してコールドスタートを回避
- `startup_cpu_boost` を有効化
- メモリ/CPU リソースを増加
EOT
    mime_type = "text/markdown"
  }

  user_labels = {
    severity    = "warning"
    category    = "performance"
    environment = var.environment
    managed_by  = "terraform"
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
  project               = var.project_id
}

# アラートポリシー: Cloud Run メモリ使用率
# -----------------------------------------------------------------------------
# コンテナ OOM Kill 防止のためのプロアクティブ監視
resource "google_monitoring_alert_policy" "cloud_run_memory" {
  count        = var.enable_resource_alerts ? 1 : 0
  display_name = "[${upper(var.environment)}] Cloud Run: メモリ使用率上昇 (>${var.memory_threshold_percent}%)"
  combiner     = "OR"
  enabled      = var.enable_alerts

  conditions {
    display_name = "メモリ使用率が閾値を超過"
    condition_threshold {
      filter = <<-EOT
        resource.type = "cloud_run_revision"
        AND resource.labels.service_name = "${var.service_name}"
        AND metric.type = "run.googleapis.com/container/memory/utilizations"
      EOT

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_PERCENTILE_99"
        cross_series_reducer = "REDUCE_MAX"
        group_by_fields      = ["resource.labels.service_name"]
      }

      comparison      = "COMPARISON_GT"
      threshold_value = var.memory_threshold_percent / 100
      duration        = "120s"

      trigger {
        count = 1
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = <<-EOT
# 💾 Cloud Run メモリ使用率アラート

**環境**: ${var.environment}
**閾値**: ${var.memory_threshold_percent}%

## 対応手順

1. **メモリリーク調査**: アプリケーションのメモリリークを確認
2. **リソース増強**: memory_limit の引き上げを検討
3. **処理最適化**: 大きなファイル処理等をストリーミング化

## 注意事項

OOM Kill が発生するとリクエストが失敗します。早めの対処を推奨します。
EOT
    mime_type = "text/markdown"
  }

  user_labels = {
    severity    = "warning"
    category    = "resources"
    environment = var.environment
    managed_by  = "terraform"
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
  project               = var.project_id
}
