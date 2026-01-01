# TODO リスト: Google Cloud Platform インフラストラクチャ

## **作業ルール**

- **設計ファースト**:
  1.  既に詳細に TODO リストを作成しているが、各フェーズごとでより良くできないか、再度**設計**と**タスク見直し**を行う。
  2.  タスクリストを作成したら、**一旦作業をストップ**し、承認を得る。
- **細粒度な実装とレビュー**:
  1.  **1 つのタスク**のみを実装する。
  2.  そのタスクのテストと動作確認が完了したら、**作業をストップ**し、レビューを受ける。
  3.  承認を得たら、次のタスクへ進む。
- **品質基準**:
  - 各タスク完了時に Terraform fmt, tflint, checkov をパスすること。

## 🏗️ **フェーズ 1: 基本プロジェクト設定と認証**

#### ✅ タスク 1: リポジトリと基本設定

> [!NOTE]
> Cloudflare 側の既存実装 (`pose-est-infra/cloudflare/`) から流用可能なファイルを活用し、効率的に構築します。
> tfstate 管理先は **Cloudflare R2** (`pose-est-terraform-state` バケット) を使用します。

- [x] **1-1: ディレクトリ構造作成**
  - [x] `pose-est-infra/gcp/terraform/` ディレクトリ作成
  - [x] `pose-est-infra/gcp/terraform/modules/` ディレクトリ作成
  - [x] `pose-est-infra/gcp/terraform/environments/` ディレクトリ作成
  - [x] `pose-est-infra/gcp/docs/` ディレクトリ作成
  - [x] `pose-est-infra/gcp/scripts/` ディレクトリ作成
- [x] **1-2: `.gitignore` 作成**
  - [x] Cloudflare 版 (`cloudflare/.gitignore`) をそのまま流用
- [x] **1-3: `README.md` 作成**
  - [x] Cloudflare 版を参考に GCP 向けに調整
- [x] **1-4: `SECURITY.md` 作成**
  - [x] Cloudflare 版をそのまま流用
- [x] **1-5: `terraform/versions.tf` 作成**
  - [x] Terraform バージョン固定: `>= 1.14.3`
  - [x] Google プロバイダー設定
  - [x] Google Beta プロバイダー設定（オプション）
- [x] **1-6: `terraform/backend.tf` 作成**
  - [x] Cloudflare R2 をバックエンドとして設定
  - [x] バケット: `pose-est-terraform-state`
  - [x] キー: `gcp/terraform.tfstate`
  - [x] Cloudflare 版 (`cloudflare/terraform/backend.tf`) を参考に作成
- [x] **1-7: R2 バックエンド初期化テスト**
  - [x] `terraform init` の実行確認
  - [x] `terraform plan` の実行確認
  - [x] tfstate ファイルが R2 に作成されることを確認
- [x] **1-8: 環境変数設定 (.env)**
  - [x] `.env.example` 作成と `.env` 設定手順の整備
  - [x] `scripts/init-backend.sh` の作成と動作確認

#### ✅ タスク 2: GCP 認証設定

> [!NOTE]
> GCP プロジェクト `kenken-pose-est` に対する認証設定を行います。
> ローカル開発用と CI/CD（GitHub Actions）用の両方を整備します。

- [x] **2-1: ローカル認証設定（gcloud CLI）**
  - [x] `gcloud auth login` でユーザー認証
  - [x] `gcloud config set project kenken-pose-est` でプロジェクト設定
  - [x] `gcloud auth application-default login` で ADC（Application Default Credentials）設定
  - [x] `.env` に `GCP_PROJECT_ID` と `GCP_REGION` を追加（タスク 1 で設定済み）
- [x] **2-2: サービスアカウント作成（Terraform 用）**
  - [x] サービスアカウント名: `terraform-admin`
  - [x] 必要な権限（最小権限の原則）:
    - `roles/editor` または以下の個別ロール:
      - [x] `roles/run.admin` (Cloud Run)
      - [x] `roles/secretmanager.admin` (Secret Manager)
      - [x] `roles/artifactregistry.admin` (Artifact Registry)
      - [x] `roles/iam.serviceAccountUser` (サービスアカウント使用)
      - [x] `roles/storage.admin` (Cloud Storage - 一時ファイル用)
  - [x] キーファイル（JSON）のエクスポートは **非推奨**（Workload Identity Federation 推奨）
- [x] **2-3: Workload Identity Federation 設定（GitHub Actions 用）**
  - [x] Workload Identity Pool の作成
  - [x] GitHub プロバイダーの設定
  - [x] サービスアカウントへの IAM バインディング
  - 参考: [GitHub Actions OIDC with GCP](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
- [x] **2-4: 認証検証スクリプト作成**
  - [x] `scripts/verify-auth.sh` の作成
  - [x] 検証項目:
    - [x] `gcloud` CLI 認証状態
    - [x] プロジェクトアクセス確認
    - [x] R2 クレデンシャル存在確認（タスク 1 の継続）
- [x] **2-5: GitHub Secrets 設定（ドキュメント化）**
  - [x] 必要な Secrets 一覧:
    - `GCP_PROJECT_ID`: `kenken-pose-est`
    - `GCP_REGION`: `asia-northeast1`
    - `GCP_WORKLOAD_IDENTITY_PROVIDER`: Workload Identity Pool プロバイダー
    - `GCP_SERVICE_ACCOUNT`: Terraform サービスアカウントメール
    - `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`: タスク 1 で設定済み
  - [x] 設定手順のドキュメント作成 (`docs/github-secrets.md`)

#### ✅ タスク 3: CI/CD 基本パイプライン作成

> [!NOTE]
> Cloudflare 側の CI/CD 実装 (`cloudflare-terraform-ci.yml`, `cloudflare-security.yml`) を参考に、
> GCP 向けのワークフローを作成します。Workload Identity Federation を使用したキーレス認証を採用。

- [x] **3-1: Terraform CI ワークフロー作成**
  - [x] ファイル: `.github/workflows/gcp-terraform-ci.yml`
  - トリガー: `pull_request` (main ブランチへの PR 時、`pose-est-infra/gcp/**` パス変更時)
  - ステップ:
    - Checkout
    - Workload Identity Federation 認証 (`google-github-actions/auth`)
    - Terraform Setup
    - TFLint Setup
    - Format Check, Init, Validate, TFLint, Plan
    - PR へのコメント（Plan 結果サマリー）
- [x] **3-2: セキュリティスキャンワークフロー作成**
  - [x] ファイル: `.github/workflows/gcp-security.yml`
  - トリガー: `pull_request` (main ブランチへの PR 時)
  - ステップ:
    - Checkout
    - Checkov スキャン
    - SARIF ファイルのアップロード（GitHub Security タブ連携）
- [x] **3-3: Terraform Apply ワークフロー作成（手動/マージ時）**
  - [x] ファイル: `.github/workflows/gcp-terraform-apply.yml`
  - トリガー: `push` (main ブランチへのマージ時) または `workflow_dispatch` (手動実行)
  - ステップ:
    - Checkout
    - Workload Identity Federation 認証
    - Terraform Init, Plan, Apply
    - 実行結果の Slack 通知（オプション、将来対応）
- [x] **3-4: ワークフロー動作確認**
  - [x] テスト用 PR を作成し、Terraform CI と Security Scan が正常に動作することを確認
  - Plan 結果が PR コメントに表示されることを確認（実際の PR で検証予定）

### 🏛️ **フェーズ 2: GCP プロジェクト基盤構築**

#### ✅ タスク 4: GCP プロジェクト設定

> [!NOTE]
> 既存プロジェクト `kenken-pose-est` を継続使用します。
> 新規プロジェクト作成は行わず、API 有効化と予算アラート設定に集中します。
> 環境分離（dev/production）は Cloud Run サービス名で実現します。

- [x] **4-1: 環境ディレクトリ構造の確立**
  - `terraform/environments/dev/` ディレクトリ作成
  - `terraform/environments/production/` ディレクトリ作成（プレースホルダー）
  - 各環境に `main.tf`, `terraform.tfvars` を配置
- [x] **4-2: `modules/gcp-project` モジュール作成**
  - ファイル: `terraform/modules/gcp-project/main.tf`, `variables.tf`, `outputs.tf`
  - 機能:
    - 必須 API の有効化（Cloud Run, Cloud Build, Artifact Registry, Secret Manager, IAM, Monitoring, Logging）
    - 予算アラート設定（月額 $20 アラート）
- [x] **4-3: dev 環境の初期設定**
  - `terraform/environments/dev/terraform.tfvars` 作成
  - `gcp-project` モジュールの呼び出し設定
- [x] **4-4: 検証**
  - `terraform init` を `environments/dev` で実行
  - `terraform plan` で API 有効化が計画されることを確認

#### ✅ タスク 5: ネットワーク基盤構築

> [!NOTE]
> VPC Service Controls は初期段階では設定の複雑さを考慮し、フェーズ 4（セキュリティ強化）で検討します。
> Cloud Run は VPC 外で動作しますが、VPC Connector を通じて内部リソースにアクセス可能な構成とします。

- [x] **5-1: `modules/networking` モジュール作成**
  - ファイル: `terraform/modules/networking/main.tf`, `variables.tf`, `outputs.tf`
  - 機能:
    - VPC ネットワーク作成 (`pose-est-vpc-{env}`)
    - サブネット作成 (`asia-northeast1`, `10.0.0.0/24`)
    - Cloud Router 作成
    - Cloud NAT 作成（VPC 内リソースのインターネットアクセス用）
- [x] **5-2: dev 環境への統合**
  - `terraform/environments/dev/main.tf` に networking モジュール呼び出しを追加
- [x] **5-3: 検証**
  - `terraform plan` で VPC, Subnet, Router, NAT が計画されることを確認

#### ⬜ タスク 6: IAM とサービスアカウント設定

- [ ] Terraform モジュール: `modules/iam`
- [ ] サービスアカウント作成:
  - `cloud-run-sa` (Cloud Run 実行用)
  - `cloud-build-sa` (Cloud Build 実行用)
  - `github-actions-sa` (GitHub Actions 実行用)
- [ ] IAM ロール割り当て（最小権限の原則）
- [ ] カスタム IAM ロール作成（必要に応じて）

### 🐳 **フェーズ 3: コンテナレジストリとビルド環境**

#### ⬜ タスク 7: Artifact Registry 設定

- [ ] Terraform モジュール: `modules/artifact-registry`
- [ ] Docker リポジトリ作成: `pose-est-backend`
- [ ] リポジトリ設定:
  - フォーマット: DOCKER
  - ロケーション: asia-northeast1
- [ ] リポジトリ権限設定:
  - Cloud Build サービスアカウントへのアクセス許可
  - Cloud Run サービスアカウントへのアクセス許可
- [ ] ライフサイクルポリシー: 未使用イメージの自動削除
- [ ] 脆弱性スキャン設定: イメージスキャンの有効化

#### ⬜ タスク 8: Cloud Build 設定

- [ ] Cloud Build トリガー作成:
  - メインブランチプッシュ時トリガー
  - タグプッシュ時トリガー（本番デプロイ用）
- [ ] ビルド設定ファイル作成: `cloudbuild/backend-build.yaml`
  - Docker ビルドステップ（R2 SDK 含む）
  - ユニットテスト実行ステップ
  - 脆弱性スキャンステップ
  - Artifact Registry へのプッシュステップ
- [ ] ビルドキャッシュ設定: ビルド時間短縮のためのキャッシュ
- [ ] ビルド通知設定: ビルド失敗時の Slack 通知

### 🔐 **フェーズ 4: R2 連携とシークレット管理**

#### ⬜ タスク 9: R2 連携 Terraform モジュール作成

- [ ] Terraform モジュール: `modules/r2-integration`
- [ ] Secret Manager シークレットリソース定義:
  - `r2-access-key-id`: R2 アクセスキー ID
  - `r2-secret-access-key`: R2 シークレットアクセスキー
- [ ] シークレットバージョン管理設定
- [ ] アクセス権限設定: Cloud Run サービスアカウントへの権限付与

#### ⬜ タスク 10: R2 クレデンシャル管理

- [ ] R2 アクセスキー作成（手動または Terraform）
- [ ] シークレットの GitHub Secrets 登録（CI/CD 用）
- [ ] シークレットの Secret Manager 登録（本番用）
- [ ] キーローテーションポリシー策定（3 ヶ月ごと推奨）

#### ⬜ タスク 11: R2 環境設定

- [ ] R2 エンドポイント URL 設定: `https://<account_id>.r2.cloudflarestorage.com`
- [ ] R2 バケット名設定: 環境別バケット名（Cloudflare 側で作成）
- [ ] 署名 URL 有効期限設定: デフォルト 1 時間、必要に応じて調整
- [ ] R2 接続テストスクリプト作成: `scripts/test-r2-connection.sh`

### ☁️ **フェーズ 5: Cloud Run バックエンド環境構築**

#### ⬜ タスク 12: Cloud Run サービス基本設定

- [ ] Terraform モジュール: `modules/cloud-run`
- [ ] Cloud Run サービス作成: `pose-est-backend-{env}`
- [ ] コンテナ設定:
  - イメージソース: Artifact Registry (`pose-est-backend`)
  - ポート: 8080 (FastAPI デフォルト)
  - 環境変数: R2 設定を Secret Manager から注入
  - ヘルスチェックパス: `/health`
- [ ] リソース制限:
  - CPU: 1-2 コア
  - メモリ: 1-4GB
  - 最大インスタンス数: 10
  - 最小インスタンス数: 0 (開発環境), 1 (本番)

#### ⬜ タスク 13: 自動スケーリング設定

- [ ] スケーリングポリシー定義:
  - CPU 使用率: 60%ターゲット
  - リクエスト数: 100 リクエスト/インスタンス
  - 最大同時リクエスト: 80
- [ ] コールドスタート対策:
  - 最小インスタンス数調整（本番環境）
  - コンテナインスタンスウォームアップ設定
- [ ] スケールダウン設定:
  - アイドルタイムアウト: 5 分
  - スケールダウン遅延設定

#### ⬜ タスク 14: ネットワークとセキュリティ設定

- [ ] プライベートエンドポイント設定（VPC 接続）
- [ ] Cloud Armor 設定（DDoS 保護）
- [ ] SSL 証明書管理（マネージド SSL）
- [ ] カスタムドメイン準備: `api.kenken-pose-est.online`（Cloudflare 連携用）
- [ ] CORS 設定: Cloudflare ドメインのみ許可
- [ ] R2 署名 URL 生成エンドポイントの保護

### 📊 **フェーズ 6: 監視とアラート設定**

#### ⬜ タスク 15: Cloud Monitoring 設定

- [ ] Terraform モジュール: `modules/monitoring`
- [ ] カスタムダッシュボード作成:
  - Cloud Run メトリクス（応答時間、エラー率、CPU 使用率）
  - R2 連携メトリクス（署名 URL 生成成功率、API 呼び出し失敗率）
  - コストメトリクス（プロジェクト別コスト）
  - ビジネス KPI ダッシュボード
- [ ] アラートポリシー設定:
  - Cloud Run エラー率 > 1%
  - Cloud Run 応答時間（p95） > 3 秒
  - Cloud Run インスタンス数 > 最大値の 80%
  - **R2 署名 URL 生成エラー率 > 0.1%**
  - **R2 API 呼び出し失敗率 > 1%**
- [ ] 通知チャンネル設定: Email, Slack, PagerDuty

#### ⬜ タスク 16: ロギングと分析設定

- [ ] Cloud Logging 設定:
  - ログ保持期間: 30 日（デフォルト）
  - 重要なログの長期保存設定
- [ ] ログベースメトリクス定義:
  - R2 署名 URL 生成エラーログ数
  - ビジネストランザクション数
- [ ] 構造化ロギング設定: JSON 形式でのログ出力
- [ ] ログルーター設定: BigQuery へのエクスポート（分析用）

#### ⬜ タスク 17: パフォーマンスモニタリング (R2 連携)

- [ ] 稼働率チェック設定:
  - ヘルスチェックエンドポイント監視
  - R2 接続確認エンドポイント監視
- [ ] プロファイリング設定: Cloud Profiler 有効化
- [ ] トレーシング設定: Cloud Trace 有効化
- [ ] デバッグ設定: Cloud Debugger 有効化（開発環境）

### 🔄 **フェーズ 7: 完全な CI/CD パイプライン構築**

#### ⬜ タスク 18: バックエンド CI/CD パイプライン

- [ ] GitHub Actions ワークフロー: `backend-deploy.yml`
- [ ] ビルドステージ:
  - Docker イメージビルド（Cloud Build 連携）
  - ユニットテスト実行（R2 モック含む）
  - セキュリティスキャン（Trivy）
  - イメージ脆弱性スキャン
- [ ] デプロイステージ:
  - Artifact Registry へのイメージプッシュ
  - Cloud Run へのデプロイ（環境別）
  - R2 クレデンシャル自動注入
  - ブルーグリーンデプロイメント設定（本番環境）
- [ ] 検証ステージ:
  - API 結合テスト
  - R2 署名 URL 生成テスト
  - パフォーマンステスト（軽量）
  - ロールバック準備

#### ⬜ タスク 19: インフラ CI/CD パイプライン

- [ ] GitHub Actions ワークフロー: `terraform-apply.yml`
- [ ] Plan ステージ:
  - Terraform 初期化
  - 計画実行と出力
  - セキュリティスキャン（Checkov）
  - コスト見積もり
- [ ] Apply ステージ（承認ベース）:
  - 環境別 Terraform 適用
  - 状態ファイル管理（Cloud Storage）
  - 状態ロック（Cloud Spanner）
- [ ] R2 テストステージ:
  - Secret Manager シークレット確認
  - Cloud Run 環境変数注入確認
  - R2 接続テスト実行
- [ ] 検証ステージ:
  - インフラヘルスチェック
  - Cloudflare 連携テスト

#### ⬜ タスク 20: 署名 URL 統合テスト

- [ ] R2 署名 URL 生成エンドポイントテスト
- [ ] 署名 URL 有効期限テスト
- [ ] 署名 URL アクセス制御テスト
- [ ] エラーハンドリングテスト
- [ ] 負荷テスト: 同時署名 URL 生成リクエスト

### 🧪 **フェーズ 8: テストと検証 (R2 統合テスト)**

#### ⬜ タスク 21: 環境テスト

- [ ] 開発環境構築とテスト
- [ ] 本番環境シミュレーション
- [ ] フェイルオーバーテスト（基本）
- [ ] ロールバックテスト

#### ⬜ タスク 22: セキュリティテスト (R2 追加)

- [ ] 脆弱性スキャン: コンテナイメージ、依存関係
- [ ] ペネトレーションテスト: API エンドポイント
- [ ] コンプライアンスチェック: CIS GCP ベンチマーク
- [ ] シークレット漏洩チェック: Git 履歴スキャン
- [ ] ネットワークセキュリティテスト: ポートスキャン
- [ ] **R2 クレデンシャル保護テスト**: Secret Manager アクセス制御
- [ ] **署名 URL セキュリティテスト**: 不正アクセス防止

#### ⬜ タスク 23: パフォーマンステスト

- [ ] 負荷テスト: 想定ユーザー数でのテスト
- [ ] スケーリングテスト: 負荷時の自動スケーリング検証
- [ ] コールドスタートテスト: 0 インスタンスからの起動時間
- [ ] エンドツーエンドレイテンシテスト
- [ ] **R2 署名 URL 生成パフォーマンステスト**
- [ ] **同時 R2 アクセステスト**

### 🔗 **フェーズ 9: Cloudflare 連携と統合**

#### ⬜ タスク 24: DNS 連携設定

- [ ] Cloud Run URL 出力設定（Cloudflare 用）
- [ ] DNS 更新自動化スクリプト作成
- [ ] ドメイン検証設定
- [ ] SSL 証明書連携設定

#### ⬜ タスク 25: セキュリティ連携

- [ ] Cloudflare IP 範囲からのアクセス制限
- [ ] WAF 連携設定（Cloud Armor 連携）
- [ ] DDoS 保護連携
- [ ] セキュリティヘッダー連携
- [ ] R2 署名 URL と Cloudflare キャッシュ連携

#### ⬜ タスク 26: モニタリング連携

- [ ] クロスプロバイダーモニタリング設定
- [ ] アラート連携（Cloudflare → GCP）
- [ ] ログ連携設定
- [ ] ダッシュボード統合（GCP + Cloudflare メトリクス）

### 📚 **フェーズ 10: ドキュメントと運用準備**

#### ⬜ タスク 27: 技術ドキュメント

- [ ] アーキテクチャ図作成（GCP + Cloudflare 連携部分）
- [ ] デプロイ手順書作成
- [ ] トラブルシューティングガイド
- [ ] セキュリティ設定ガイド
- [ ] **R2 連携ガイド: 署名 URL 生成、クレデンシャル管理**

#### ⬜ タスク 28: 運用ドキュメント

- [ ] 監視ダッシュボード説明書
- [ ] アラート対応手順
- [ ] DNS 変更手順
- [ ] 証明書更新手順
- [ ] **R2 クレデンシャルローテーション手順**

#### ⬜ タスク 29: 開発者向けドキュメント

- [ ] ローカル開発環境構築ガイド
- [ ] デバッグ手順書
- [ ] テスト実施ガイド
- [ ] コーディング規約（インフラコード）

#### ⬜ タスク 30: 最終検証と本番移行

- [ ] 本番環境最終テスト
- [ ] パフォーマンスベースライン設定
- [ ] セキュリティ最終レビュー
- [ ] 移行計画作成（段階的ロールアウト）
- [ ] ロールバック計画作成
- [ ] 本番移行実行と検証

---

## 各フェーズ完了基準

1. **コード品質**: Terraform fmt, tflint, checkov でエラーなし
2. **テスト**: すべての機能テストが正常に完了
3. **セキュリティ**: セキュリティスキャンで重大な脆弱性なし
4. **パフォーマンス**: パフォーマンステストが基準を満たす
5. **コスト見積もり**: 想定コストが予算範囲内
6. **ドキュメント**: 必要なドキュメントが作成済み
7. **Cloudflare 連携**: DNS 設定と R2 統合が正常に動作

## 重要注意事項

1. **状態ファイル管理**:

   - 開発/本番で状態ファイルを分離（ステージング削除）
   - **バックエンドは Cloudflare R2**（Cloudflare 側と統一）
   - バケット: `pose-est-terraform-state`、キー: `gcp/terraform.tfstate`
   - 状態ロックは CI/CD ジョブの直列化で実現（R2 はネイティブロック非対応）
   - 状態ファイルの定期的なバックアップ

2. **シークレット管理**:

   - 全てのシークレットは Secret Manager で管理
   - Terraform 変数で直接シークレットを扱わない
   - R2 クレデンシャルの自動ローテーション計画（3 ヶ月ごと推奨）

3. **Cloudflare 連携**:

   - DNS 設定は Cloud Run 作成後に実施
   - CORS 設定は両環境で整合性を確保
   - R2 バケットは Cloudflare 側で作成、GCP 側はアクセスキーのみ管理
   - 定期的な接続テストの実施

4. **コスト最適化**:

   - 常に無料枠を確認しながら設計
   - R2 ストレージ使用量の監視（10GB 無料枠）
   - R2 操作回数の監視（100 万回/月無料枠）
   - Cloud Run の自動スケーリングでコスト最適化

5. **セキュリティ**:

   - 最小権限の原則を徹底（特に R2 クレデンシャル）
   - 定期的なセキュリティスキャンの実施
   - 監査ログの長期保存と定期的なレビュー
   - R2 署名 URL の適切な有効期限設定

6. **バックアップと DR**:
   - インフラ状態の定期的なバックアップ
   - R2 データは Cloudflare 側で管理、バックアップ不要
   - 災害復旧計画の定期的な見直し
