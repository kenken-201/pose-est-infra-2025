# フェーズ 3 レビュー: コンテナレジストリとビルド環境

## 1. 概要

本フェーズでは、アプリケーションのデリバリーパイプラインの中核となる **Artifact Registry** と **Cloud Build** 環境を構築しました。
特に、**不変性 (Immutability)** と **最小権限 (Least Privilege)** を徹底し、エンタープライズグレードの堅牢な基盤を実現しました。

## 2. 達成事項

### ✅ タスク 7: Artifact Registry 設定

- **セキュアなリポジトリ**:
  - `modules/artifact-registry` を実装。
  - **Immutable Tags**: 本番運用を見据え、タグの上書き禁止設定 (`immutable_tags`) を実装（Dev 環境では柔軟性のため無効化）。
  - **Cleanup Policies**: コスト最適化のため、タグなしイメージの自動削除と、古いバージョンの世代管理を導入。
- **IAM 最適化**:
  - `roles/artifactregistry.writer/reader` を **リソース単位** で付与。プロジェクト全体への広範な権限付与を排除しました。

### ✅ タスク 8: Cloud Build 設定 (Hybrid CI/CD)

- **ハイブリッド構成**:
  - GitHub Actions をトリガーとし、Cloud Build を実行エンジンとして使用する構成を採用。
  - 既存の **Workload Identity Federation (WIF)** を活用し、追加の認証情報管理を不要にしました。
- **Build as Code**:
  - `gcp/cloudbuild/backend-build.yaml` を作成し、ビルドプロセスをコード化。
  - `--no-cache` オプションや置換変数 (`substitutions`) の活用により、再現性と柔軟性を確保。

## 3. 品質とエンジニアリングのハイライト

### 🛡️ セキュリティ・ファースト (Deep Dive)

- **専用サービスアカウントの徹底活用**:
  - Cloud Build の実行主体として、デフォルトの SA ではなく、Terraform で管理された `cloud-build-sa` を明示的に指定 (`--service-account`)。
  - これにより、ビルドジョブが持つ権限を厳密にコントロール可能にしました。

### 🏗️ モジュール設計の標準化

- **構成の分離**:
  - `versions.tf` を各モジュールに新設し、プロバイダー要件を分離。
  - 変数のバリデーション (`validation` ブロック) を活用し、誤った環境指定などを早期に検知。

## 4. 次のステップ (フェーズ 4)

デプロイ基盤が整いました。次はアプリケーションから安全にデータを扱うための **R2 連携** を構築します。

1.  **タスク 9: R2 連携 Terraform モジュール**
    - Secret Manager を活用した R2 クレデンシャル管理。
2.  **タスク 10: IAM 連携**
    - Cloud Run が Secret Manager にアクセスするための権限設定（確認と調整）。

---

_Created by Antigravity Agent - 2026-01-01_
