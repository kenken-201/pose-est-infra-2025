/*
  Artifact Registry モジュール main.tf
  -----------------------------------------------------------------------------
  コンテナイメージを格納する Artifact Registry リポジトリを作成します。
  クリーンアップポリシーと、CI/CD 用の IAM 権限設定（リソースレベル）を含みます。
*/

# -----------------------------------------------------------------------------
# Artifact Registry リポジトリ作成
# -----------------------------------------------------------------------------
resource "google_artifact_registry_repository" "repo" {
  provider = google-beta # cleanup_policies は Beta 機能

  location      = var.region
  repository_id = "pose-est-backend-${var.environment}"
  description   = "Docker repository for Pose Estimation Backend (${var.environment})"
  format        = "DOCKER"

  # Docker タグの不変性設定 (本番環境では true 推奨)
  docker_config {
    immutable_tags = var.immutable_tags
  }

  # -----------------------------------------------------------------------------
  # クリーンアップポリシー (コスト最適化)
  # -----------------------------------------------------------------------------

  # 1. タグなし (Untagged) イメージを 7 日後に削除
  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "604800s" # 7 days
    }
  }

  # 2. 古いバージョンのタグ付きイメージを削除 (最新 5 バージョンを保持)
  # 注意: "latest" などの重要タグは保持する設定が必要だが、単純な keep-count で運用開始
  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      package_name_prefixes = ["pose-est-backend"] # package_name が一致するものに対して
      keep_count            = 5
    }
  }
}

# -----------------------------------------------------------------------------
# IAM 権限設定 (リソースレベル: 最小権限)
# -----------------------------------------------------------------------------

# Cloud Build SA: イメージのプッシュ (Writer)
resource "google_artifact_registry_repository_iam_member" "writer" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.repo.name
  role       = "roles/artifactregistry.writer"
  member     = var.cloud_build_sa_member
}

# Cloud Run SA: イメージのプル (Reader)
resource "google_artifact_registry_repository_iam_member" "reader" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.repo.name
  role       = "roles/artifactregistry.reader"
  member     = var.cloud_run_sa_member
}
