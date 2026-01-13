# -----------------------------------------------------------------------------
# Logging Module - ログ除外フィルター設定
# -----------------------------------------------------------------------------
# GCP 無料枠を最大限活用するため、不要なログを除外します。
# - ヘルスチェック成功ログ: ノイズが多いため除外
# - DEBUG レベルログ: 本番環境では不要なため除外（オプション）

# 除外フィルター: Cloud Run ヘルスチェック成功ログ
# -----------------------------------------------------------------------------
# ヘルスチェックは高頻度で実行されるため、成功ログは除外してコストを削減します。
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

  filter  = "severity=\"DEBUG\""
  project = var.project_id
}
