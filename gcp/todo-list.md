# 🌩️ GCP インフラ構築進捗 (Navigator-Driver Model)

本プロジェクトは **Navigator（ユーザー）** と **Driver（AI）** の協業モデルで進行します。
GCP 構築はセキュリティリスク（IAM、公開設定）管理が重要であるため、**「権限設計・Plan」→「承認」→「実装」** のサイクルを重視します。

---

## 🏗️ フェーズ 1: IaC 基盤と State 管理

### ⬜ タスク 1-1: Terraform バックエンド設計

- **Goal**: チーム開発に耐えうる State 管理環境の構築
- [ ] State 管理用 GCS バケットの構成案（バージョニング、ロック）
- [ ] ディレクトリ構成と環境分離戦略の提示
- [ ] **🛑 [Review] State 管理戦略の承認**

### ⬜ タスク 1-2: プロジェクト初期設定

- **Goal**: Terraform 実行環境の整備
- [ ] `backend.tf` と `provider.tf` の実装
- [ ] 必要な Google Cloud API の有効化リスト定義（`google_project_service`）
- [ ] `terraform init` による初期化確認
- [ ] **🛑 [Review] プロジェクト基盤の確認**

---

## 🔐 フェーズ 2: 認証と CI/CD 連携 (IAM & OIDC)

### ⬜ タスク 2-1: CI/CD 認証設計 (Workload Identity)

- **Goal**: キーレスで安全な GitHub Actions 連携
- [ ] Workload Identity Pool と Provider の設計
- [ ] GitHub Actions 用サービスアカウントと権限セット（最小権限）の設計
- [ ] **🛑 [Review] 認証・認可設計の承認**

### ⬜ タスク 2-2: IAM リソース実装

- **Goal**: GitHub Actions から Terraform/Docker Push ができる状態にする
- [ ] `modules/iam` の実装（WIF プール, SA, IAM Policy）
- [ ] CI/CD パイプラインからの接続テスト準備
- [ ] **🛑 [Review] IAM 設定コードと Plan 結果の確認**

---

## 📦 フェーズ 3: コンテナレジストリ (Artifact Registry)

### ⬜ タスク 3-1: レジストリ設計

- **Goal**: Docker イメージの安全な保管場所
- [ ] Artifact Registry リポジトリ構成（Docker format）
- [ ] ライフサイクルポリシー（古いイメージの自動削除）設計
- [ ] **🛑 [Review] レジストリ構成の承認**

### ⬜ タスク 3-2: レジストリリソース実装

- **Goal**: イメージプッシュ先の確保
- [ ] `modules/storage` (Artifact Registry) の実装
- [ ] **🛑 [Review] レジストリ作成コードの確認**

---

## 🚀 フェーズ 4: コンピュート (Cloud Run)

### ⬜ タスク 4-1: サービス実行基盤設計

- **Goal**: サーバーレスでスケーラブルな API ホスティング設計
- [ ] Cloud Run サービス構成（CPU, メモリ, 同時実行数）
- [ ] スケーリング設定（Min/Max instances）
- [ ] 環境変数とシークレット管理（Secret Manager 連携）の方針
- [ ] ネットワーク（Ingress）と認証（公開/内部のみ）の方針
- [ ] **🛑 [Review] Cloud Run 構成案の承認**

### ⬜ タスク 4-2: Cloud Run リソース実装

- **Goal**: API がデプロイ・稼働できる状態にする
- [ ] `modules/compute` の実装
- [ ] デプロイ用サービスアカウントの権限設定
- [ ] **🛑 [Review] Cloud Run 設定コードと Plan 結果の確認**

---

## 💾 フェーズ 5: ストレージ (Cloud Storage)

### ⬜ タスク 5-1: データ保存設計

- **Goal**: 動画ファイル（入力/出力）の保存先設計
- [ ] 入力用・出力用バケットの構成
- [ ] ライフサイクルルール（一時ファイルの削除期間）
- [ ] CORS 設定（フロントエンドからの直接アップロード用）
- [ ] **🛑 [Review] ストレージ設計の承認**

### ⬜ タスク 5-2: ストレージリソース実装

- **Goal**: バケットのプロビジョニング
- [ ] `modules/storage` (GCS) の実装
- [ ] バケット権限設定（Cloud Run SA からのアクセス許可）
- [ ] **🛑 [Review] ストレージ設定コードの確認**

---

## 🔄 フェーズ 6: CI/CD パイプライン (GitHub Actions)

### ⬜ タスク 6-1: デプロイパイプライン設計

- **Goal**: バックエンドアプリの自動デプロイ
- [ ] コンテナビルドと Push のフロー
- [ ] `terraform apply` によるインフラ同期フロー
- [ ] Cloud Run への新しいリビジョンデプロイフロー
- [ ] **🛑 [Review] デプロイフローの承認**

### ⬜ タスク 6-2: Workflow 実装

- **Goal**: `.github/workflows` の実装
- [ ] `backend-deploy.yaml` の実装
- [ ] `infra-gcp-apply.yaml` の実装
- [ ] **🛑 [Review] Workflow 定義の確認**

---

## 各フェーズ完了基準

1.  **IAM Review**: 権限付与は必ず「最小権限」であること。`Owner` や `Editor` などの広範なロール使用は禁止。
2.  **Naming Convention**: リソース名は命名規則（例: `pose-est-{env}-{resource}`）に従っていること。
3.  **Plan Review**: 削除（Destroy）や再作成（Replacement）を含む変更は特に慎重にレビューする。
4.  **No Keys**: サービスアカウントキー（JSON）の発行は行わず、Workload Identity を使用する。

---

**特記事項**: Google Cloud はリソース作成に時間がかかる場合がある（特に API 有効化直後など）。依存関係の設定には `depends_on` や API 有効化の完了待ちを適切に考慮すること。
