environment = "dev"
domain_name = "kenken-pose-est.online"
cors_origins = [
  "http://localhost:3000",
  "https://dev.kenken-pose-est.online",
  "https://pose-est-front.pages.dev"
]

# Pages 設定
pages_project_name = "pose-est-frontend" # プロジェクト名
node_version       = "20"                # LTS 推奨

pages_build_config = {
  command         = "npm run build"
  destination_dir = "dist"
  root_dir        = "pose-est-front" # モノレポ構成のため指定
}

pages_preview_vars = {
  VITE_API_URL = "https://api-dev.kenken-pose-est.online" # 暫定値 (GCP未構築のため)
}

pages_production_vars = {
  VITE_API_URL = "https://api.kenken-pose-est.online" # 暫定値
}
