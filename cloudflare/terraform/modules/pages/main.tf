# ==============================================================================
# Cloudflare Pages Project Module
# ==============================================================================
# Cloudflare Pages プロジェクトを管理します。
#
# ⚠️ 注意: Provider v5 の制限により、source (GitHub 連携) 設定は
#    Terraform からは管理できません（read-only）。
#    Dashboard で手動連携した後、このリソースを import して使用します。
# ==============================================================================

resource "cloudflare_pages_project" "this" {
  account_id        = var.account_id
  name              = var.project_name
  production_branch = var.production_branch

  # ---------------------------------------------------------------------------
  # Build Configuration
  # ---------------------------------------------------------------------------
  build_config {
    build_command       = var.build_config.command
    destination_dir     = var.build_config.destination_dir
    root_dir            = var.build_config.root_dir
    web_analytics_tag   = null
    web_analytics_token = null
  }

  # ---------------------------------------------------------------------------
  # Deployment Configurations (Environment Variables)
  # ---------------------------------------------------------------------------
  # deployment_configs ブロックは v5 で単一のネストされた属性になりました

  deployment_configs {
    preview {
      environment_variables = merge(
        { "NODE_VERSION" = var.node_version },
        var.preview_vars
      )
      compatibility_date  = "2024-04-01" # 必要に応じて更新
      compatibility_flags = ["nodejs_compat"]
    }

    production {
      environment_variables = merge(
        { "NODE_VERSION" = var.node_version },
        var.production_vars
      )
      compatibility_date  = "2024-04-01"
      compatibility_flags = ["nodejs_compat"]
    }
  }

  lifecycle {
    # source 設定は外部(Dashboard)で管理されるため、Terraform での変更を無視します
    # ただし、v5 では source ブロック自体が read-only なので ignore_changes は
    # 必須ではないかもしれませんが、念のため記述する場合もありますが、
    # 構成ドリフトを防ぐため、ここでは明示的な ignore は一旦避けます。
    # 代わりに手動連携後の import を前提とします。
  }
}
