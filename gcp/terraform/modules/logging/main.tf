# -----------------------------------------------------------------------------
# Logging Module - ログ除外フィルター設定
# -----------------------------------------------------------------------------
# GCP 無料枠を最大限活用するため、不要なログを除外します。
# - ヘルスチェック成功ログ: ノイズが多いため除外
# - DEBUG レベルログ: 本番環境では不要なため除外（オプション）
#
# 運用 Tips:
# - 障害調査時はフィルターを一時的に無効化 (disabled = true) することで
#   除外されていたログも確認できます。
# - フィルターの有効/無効は Terraform 変数で制御可能です。

# 除外フィルター: Cloud Run ヘルスチェック成功ログ
# -----------------------------------------------------------------------------
# ヘルスチェックは高頻度で実行されるため、成功ログは除外してコストを削減します。
# 失敗ログ (status != 200) は除外されないため、障害検知には影響しません。
resource "google_logging_project_exclusion" "exclude_health_check_success" {
  count = var.exclude_health_check_logs ? 1 : 0

  name        = "exclude-health-check-success-${var.environment}"
  description = "Cloud Run ヘルスチェック成功ログを除外（ノイズ削減、コスト最適化）"

  # フィルタ条件:
  # - Cloud Run リビジョンのログ
  # - /health エンドポイントへのリクエスト
  # - HTTP ステータスコード 200 (成功)
  filter = <<-EOT
    resource.type="cloud_run_revision"
    AND httpRequest.requestUrl:"/health"
    AND httpRequest.status=200
  EOT

  # 障害調査時に一時的に無効化可能
  disabled = var.disable_health_check_exclusion

  project = var.project_id
}

# 除外フィルター: DEBUG レベルログ (本番環境のみ)
# -----------------------------------------------------------------------------
# 本番環境では DEBUG レベルのログは通常不要です。
# 開発環境では DEBUG ログを保持してデバッグに活用します。
resource "google_logging_project_exclusion" "exclude_debug_logs" {
  count = var.environment == "prod" && var.exclude_debug_logs_in_prod ? 1 : 0

  name        = "exclude-debug-logs-${var.environment}"
  description = "DEBUG レベルのアプリケーションログを除外（本番環境のみ）"

  filter   = "severity=\"DEBUG\""
  disabled = var.disable_debug_log_exclusion

  project = var.project_id
}

# -----------------------------------------------------------------------------
# 将来の拡張候補（コメントのみ）
# -----------------------------------------------------------------------------
# 以下は将来的に追加を検討できる除外フィルターの例です:
#
# 1. Cloud Build ビルドログ（成功時のみ除外）
#    filter = "resource.type=\"build\" AND textPayload:\"SUCCESS\""
#
# 2. VPC Flow Logs（開発環境のみ除外、$0.25/GiB と高コスト）
#    filter = "resource.type=\"gce_subnetwork\" AND log_name:\"vpc_flows\""
#
# 3. 特定のパスへのアクセスログ（静的アセット等）
#    filter = "httpRequest.requestUrl:\"/static/\" OR httpRequest.requestUrl:\"/favicon.ico\""
