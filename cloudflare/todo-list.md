# ☁️ Cloudflare インフラ構築進捗 (Navigator-Driver Model)

本プロジェクトは **Navigator（ユーザー）** と **Driver（AI）** の協業モデルで進行します。
インフラ構築は「破壊的変更」のリスクがあるため、**「設計・Plan」→「承認」→「実装・コード化」** のサイクルを特に重視します。

---

## 🏗️ フェーズ 1: IaC 基盤構築と認証設定

### ⬜ タスク 1-1: Terraform プロジェクト設計

- **Goal**: 拡張性と保守性の高いディレクトリ構成の確立
- [ ] ディレクトリ構造案 (`modules/`, `environments/`) の提示
- [ ] 状態管理 (State Backend) の戦略（Cloudflare R2 or Terraform Cloud）提案
- [ ] **🛑 [Review] ディレクトリ構成と State 戦略の承認**

### ⬜ タスク 1-2: プロジェクト初期化と認証

- **Goal**: Terraform が Cloudflare API を操作できる状態にする
- [ ] `versions.tf` (Provider 設定) の実装
- [ ] API トークンの環境変数設定 (`run.sh` や `.env` テンプレート)
- [ ] `terraform init` 実行確認
- [ ] **🛑 [Review] 初期化成功と接続確認**

---

## 🌐 フェーズ 2: ネットワークとドメイン (DNS/SSL)

### ⬜ タスク 2-1: DNS モジュール設計

- **Goal**: 環境ごとに安全に DNS レコードを管理する設計
- [ ] DNS モジュールのインターフェース（入力変数）設計
- [ ] ゾーン管理とレコード管理（A, CNAME, TXT）の方針
- [ ] **🛑 [Review] DNS 管理方針の承認**

### ⬜ タスク 2-2: DNS リソース実装

- **Goal**: ドメイン `kenken-pose-est.com` のコード化
- [ ] `modules/dns` の実装
- [ ] 開発環境 (`dev`) 用の `tfvars` 作成
- [ ] `terraform plan` による変更内容の確認
- [ ] **🛑 [Review] DNS 設定コードと Plan 結果の確認**

---

## 📄 フェーズ 3: フロントエンドホスティング (Cloudflare Pages)

### ⬜ タスク 3-1: Pages モジュール設計

- **Goal**: フロントエンドアプリの自動デプロイ基盤設計
- [ ] Pages プロジェクト設定案（ビルドコマンド、出力先）
- [ ] 環境変数 (`NODE_VERSION` 等) の注入方法
- [ ] GitHub 連携または Direct Upload の方針決定
- [ ] **🛑 [Review] Pages 構成案の承認**

### ⬜ タスク 3-2: Pages リソース実装

- **Goal**: フロントエンドのデプロイ先確保
- [ ] `modules/pages` の実装
- [ ] カスタムドメイン (`www`, ルート) との紐付け設定
- [ ] SPA ルーティング用設定 (`_routes.json` 等) の管理方針
- [ ] **🛑 [Review] Pages 設定コードの確認**

---

## 🔒 フェーズ 4: エッジセキュリティ (WAF/DDoS)

### ⬜ タスク 4-1: セキュリティポリシー設計

- **Goal**: 無料枠で実現可能なセキュリティ対策の定義
- [ ] WAF マネージドルールの選定
- [ ] レート制限 (Rate Limiting) の閾値設計
- [ ] HTTP ヘッダーセキュリティ (HSTS, CSP) の設計
- [ ] **🛑 [Review] セキュリティポリシーの承認**

### ⬜ タスク 4-2: セキュリティリソース実装

- **Goal**: 攻撃からの保護設定のコード化
- [ ] `modules/security` の実装 (Page Rules, Firewall Rules)
- [ ] 開発用と本番用のポリシー差異化
- [ ] **🛑 [Review] セキュリティ設定コードの確認**

---

## ⚡ フェーズ 5: パフォーマンスと監視

### ⬜ タスク 5-1: キャッシュと最適化設計

- **Goal**: ユーザー体験向上のための最適化
- [ ] キャッシュルール (TTL) の設計
- [ ] 画像最適化 (Polish/Mirage) の設定方針（※Pro プラン以上要検討、Free 範囲の確認）
- [ ] **🛑 [Review] 最適化方針の承認**

### ⬜ タスク 5-2: 監視設定の実装

- **Goal**: インフラの状態可視化
- [ ] Analytics 設定（Web Analytics）
- [ ] Health Check（※必要であれば）
- [ ] **🛑 [Review] 監視設定の確認**

---

## 🔄 フェーズ 6: CI/CD パイプライン (GitHub Actions)

### ⬜ タスク 6-1: IaC パイプライン設計

- **Goal**: 自動化された Plan と Apply
- [ ] PR 時の `terraform plan` 自動実行フロー設計
- [ ] マージ時の `terraform apply` フロー設計
- [ ] シークレット管理方針
- [ ] **🛑 [Review] CI/CD フローの承認**

### ⬜ タスク 6-2: Workflow 実装

- **Goal**: パイプラインのコード化
- [ ] `.github/workflows/terraform.yaml` の実装
- [ ] **🛑 [Review] Workflow 定義の確認**

---

## 各フェーズ完了基準

1.  **設計合意**: 必ずコードを書く前に「何を作るか」がドキュメントまたはコメントで合意されている。
2.  **Lint/Validate**: `terraform fmt`, `terraform validate`, `tflint` がエラーなし。
3.  **Plan Review**: Implement 完了時のレビューには、必ず `terraform plan` の想定出力が含まれている（または CI で確認できる）。
4.  **No Hardcoding**: API キーやアカウント ID はコードに直書きせず、変数または環境変数から読み込む。

---

**特記事項**: Cloudflare Pages と DNS の連携部分は、反映に時間がかかる場合があるため、検証時は伝播待ち時間を考慮すること。
