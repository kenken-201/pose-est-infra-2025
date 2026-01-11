# TODO リスト: Cloudflare インフラストラクチャ

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

- [x] Cloudflare ディレクトリ作成 (確認): `pose-est-infra/cloudflare/`
- [x] ディレクトリ構造作成: `terraform/`, `terraform/modules/`, `terraform/environments/`
- [x] 基本ファイル作成: `README.md`, `.gitignore`, `SECURITY.md`, `.terraform-version`
- [x] 開発用ツール作成: `Makefile` (terraform コマンドのラッパー)
- [x] Terraform バージョン固定: `terraform/versions.tf` 作成
- [x] Terraform バックエンド設計と初期化:
  - [x] バックエンドに R2 (S3 互換) を採用決定
  - [x] 状態管理バケット作成手順の策定 (ブートストラップ)
  - [x] `terraform/backend.tf` (または `backend` block in `versions.tf`) の設定

#### ✅ タスク 2: Cloudflare 認証設定

- [x] Cloudflare API トークン作成ガイド作成: `docs/setup-auth.md`
- [x] API トークン発行と検証:
  - [x] 必要な権限: Zone Read/Write, DNS Edit, Page Write, R2 Read/Write, etc.
  - [x] 検証スクリプト作成: `scripts/verify-auth.sh`
  - [x] 動作確認: `make verify-auth` (またはスクリプト直接実行)
- [x] 環境変数テンプレート作成: `.env.example`
- [x] ローカル環境変数設定: `.env` (gitignored)
- [x] GitHub Secrets 設定
  - `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`
  - `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`

#### ✅ タスク 3: CI/CD 基本パイプライン作成

- [x] GitHub Actions 共通設定:
  - [x] ワークフローのパスフィルタリング設定 (`pose-est-infra/cloudflare/**`)
- [x] Terraform CI ワークフロー作成: `.github/workflows/cloudflare-terraform-ci.yml`
  - [x] `fmt`, `validate`
  - [x] `tflint` (リンター)
  - [x] `plan` (PR への結果コメントなど)
- [x] セキュリティスキャンワークフロー作成: `.github/workflows/cloudflare-security.yml`
  - [x] `checkov` による静的解析

### 🗄️ **フェーズ 2: R2 ストレージ層設定**

#### ✅ タスク 4: R2 Terraform モジュール作成

- [x] Terraform モジュールディレクトリ作成: `modules/r2`
- [x] R2 リソース定義 (`main.tf`):
  - [x] `cloudflare_r2_bucket`: バケット作成
  - [x] `cloudflare_r2_bucket_lifecycle_rule`: 7 日自動削除設定
  - [x] `cloudflare_r2_bucket_cors`: フロントエンドからのアクセス許可
- [x] 変数定義 (`variables.tf`):
  - [x] `account_id`, `bucket_name`, `location`, `cors_origins`
- [x] 出力定義 (`outputs.tf`):
  - [x] `bucket_name`, `bucket_domain`

#### ✅ タスク 5: R2 バケット要件定義と実装

- [x] `terraform/main.tf` に `modules/r2` 呼び出しを追加
- [x] 環境別変数ファイル作成:
  - [x] `terraform/environments/dev/terraform.tfvars`
  - [x] `terraform/environments/production/terraform.tfvars`
- [x] 適用と検証 (`dev`):
  - [x] `terraform plan -var-file=environments/dev/terraform.tfvars`
  - [x] `terraform apply` (Dev)
  - [x] バケット作成確認 (Python script + curl)
- [x] テスト:
  - [x] CORS 検証 (curl / boto3)

#### ✅ タスク 6: R2 アクセスキー管理

- [x] アプリケーション用 R2 アクセスキー発行 (Cloudflare Dashboard 経由 - 手動)
  - [x] 権限: `Object Read/Write` (バケット単位の制限推奨)
- [x] シークレット管理スクリプト作成:
  - [x] `scripts/setup-secrets.sh`: ローカル `.env` への追加ヘルパー
  - [x] `scripts/register-gh-secrets.sh`: GitHub Secrets への登録
- [x] キーローテーション運用ルールの策定 (ドキュメント化: `docs/setup-auth.md`)

#### ✅ タスク 7: R2 セキュリティ設定

- [x] CORS 設定の厳格化: `["*"]` から具体的なオリジン (`localhost`, 本番ドメイン) へ変更
- [x] 署名付き URL (Presigned URL) 生成スクリプトの実装:
  - [x] `scripts/generate-presigned-url.py`: PUT(アップロード) / GET(ダウンロード) 用
- [x] アクセス制御 (ACL) 検証テスト:
  - [x] `scripts/verify-r2-security.sh`: 匿名アクセスの拒否 (403/401/400) を確認
  - [x] 公開バケット設定 (Public Access) が無効であることを確認
- [x] (Optional) 監査ログ設定調査 (プラン依存のため確認のみ/今回はスキップ)

### 🛡️ **フェーズ 3: DNS とドメイン設定**

#### ✅ タスク 8: DNS モジュールとゾーン設定

- [x] `modules/dns` の作成 (Zone Settings, Security Headers)
- [x] Zone ID の取得 (`.env` or `tfvars`)
- [x] SSL/TLS (Strict), DNSSEC, Email Security (SPF/DMARC) の適用
- [x] DNSSEC DS レコードの出力確認等の管理
- [x] `cloudflare_record`: 汎用的なレコード管理リソース (`cloudflare_dns_record` として実装済み)
- [x] ゾーン関連の変数・値の設定:
  - [x] 既存ゾーン ID の取得と `terraform.tfvars` への反映 (`.env` 経由で実装)
- [x] ゾーンセキュリティ設定の実装と適用:
  - [x] SSL/TLS: Full (Strict)
  - [x] Always Use HTTPS: On
  - [x] DNSSEC: 有効化
  - [x] Min TLS Version: 1.2
- [x] メールセキュリティ設定 (DMARC/SPF):
  - [x] メール送信を行わない場合の推奨設定 (なりすまし防止)

#### ⬜ タスク 9: 環境別 DNS 設定

**目的**: 開発環境・プレビュー環境・API サブドメインの DNS レコードを Terraform で管理

**依存関係**:

- ⚠️ API サブドメイン (`api.`) は GCP Cloud Run URL が必要 (GCP IaC 構築後に実装)
- ✅ 開発環境 DNS (`dev.`) は Cloudflare Pages 構築後に実装可能

**サブタスク**:

- [x] **9-1: DNS モジュール拡張 (汎用レコード対応)**

  - [x] `modules/dns` に汎用 DNS レコード作成機能を追加
  - [x] 変数: `additional_records` (list of objects: name, type, value, proxied, ttl, comment)
  - [x] 既存の SPF/DMARC とは別に、動的レコード追加を可能に

- [ ] **9-2: 開発環境 DNS レコード設定 (Pages 依存)**

  - [ ] `dev.kenken-pose-est.online` → Cloudflare Pages (プレビュー URL)
  - [ ] ⚠️ Task 10 (Pages プロジェクト作成) 完了後に実装
  - [ ] CNAME レコードを `tfvars` で環境別に定義

- [ ] **9-3: API サブドメイン DNS 設定 (GCP 依存)**

  - [ ] `api.kenken-pose-est.online` → GCP Cloud Run URL (CNAME)
  - [ ] ⚠️ GCP IaC で Cloud Run URL 出力後に実装
  - [ ] `var.gcp_cloud_run_url` を variables.tf に追加
  - [ ] Proxied = true で Cloudflare 経由にする

- [ ] **9-4: プレビュー環境 DNS (自動生成)**
  - [ ] Cloudflare Pages のブランチプレビュー機能を活用
  - [ ] `{branch}.pose-est-front.pages.dev` は自動生成
  - [ ] カスタムドメイン (`{branch}.kenken-pose-est.online`) は Pages 設定側で対応

### 🌐 **フェーズ 4: Cloudflare Workers 設定（フロントエンド SSR）**

> [!IMPORTANT] > **アーキテクチャ変更**: React Router v7 は SSR が必要なため、静的ホスティング (Pages) から
> **Cloudflare Workers** に変更しました。Terraform での IaC 管理は引き続き行いますが、
> Workers 固有の設定（wrangler.toml 等）はフロントエンドリポジトリ側で管理します。

#### ✅ タスク 10: Workers プロジェクト設定

**目的**: Cloudflare Workers でフロントエンドアプリケーション (SSR) をホストし、自動デプロイを実現

**依存関係**:

- ⚠️ フロントエンド側での `@react-router/cloudflare` アダプター導入が必要
- ⚠️ 環境変数 `VITE_API_URL` は GCP 完了後に最終値を設定

**サブタスク**:

- [x] **10-1〜10-5**: Pages モジュール作成（完了、Workers 移行により一部無効）
- [x] **10-6: Pages リソースのクリーンアップ**
  - [x] `modules/pages` の削除: **実施済み (ディレクトリ削除)**
  - [x] `terraform state rm module.pages`: **実施済み**
  - [x] `terraform.tfvars` の Pages 設定削除: **実施済み**
- [x] **10-7: Workers カスタムドメイン設定**
  - [x] `cloudflare_workers_custom_domain` リソースの使用
  - [x] Dev: `dev.kenken-pose-est.online` → `pose-est-frontend` (Service Name)
  - [ ] Prod: `kenken-pose-est.online` → `pose-est-frontend` (Service Name)
- [ ] **10-8: Workers モジュール化の検討 (将来的な課題)**
  - [ ] 現状は `main.tf` 内の単一リソースで十分なため、`modules/workers` は作成しない
  - [ ] Workers 関連リソース (KV, Durable Objects 等) が増えた場合にモジュール化を再検討

#### ✅ タスク 11: カスタムドメイン設定

**目的**: Workers アプリケーションに対してカスタムドメインを割り当て、HTTPS アクセスを確保する

> [!NOTE]
> Workers へのドメイン割り当ては `cloudflare_workers_custom_domain` リソースで管理。
> HTTPS 強制・証明書管理は Cloudflare が自動的に処理するため、追加設定は不要。

**サブタスク**:

- [x] **11-1: 開発環境ドメイン**

  - [x] `dev.kenken-pose-est.online` → `pose-est-frontend` (Task 10-7 で実施済み)
  - [x] HTTPS 強制: Cloudflare 自動処理 (Zone Settings で `always_use_https` 有効済み)
  - [x] SSL 証明書: Cloudflare Edge Certificate 自動発行済み

- [ ] **11-2: 本番環境ドメイン (Production 環境構築後)**

  - [ ] `kenken-pose-est.online` → `pose-est-frontend` (Production)
  - [ ] `www.kenken-pose-est.online` → リダイレクト設定 (apex へ)
  - [ ] ⚠️ Production 環境の Terraform 構成が必要

- [x] **11-3: Zone レベルセキュリティ設定 (Task 8 で実施済み)**
  - [x] SSL/TLS: Full (Strict)
  - [x] Always Use HTTPS: On
  - [x] Min TLS Version: 1.2

#### ✅ タスク 12: セキュリティヘッダーとキャッシュ設定

**目的**: フロントエンド Workers のセキュリティとパフォーマンスを最適化する

> [!NOTE]
> フロントエンド側 (`pose-est-front`) で実装完了。
> `workers/utils/security-headers.ts` と `public/_headers` で設定済み。

**サブタスク**:

- [x] **12-1: セキュリティヘッダー設定 (フロントエンド側)**

  - [x] Worker スクリプトでレスポンスヘッダーを追加 (`workers/utils/security-headers.ts`)
  - [x] 対象ヘッダー: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy`, `HSTS`
  - [x] ユニットテスト作成済み (`test/workers/utils/security-headers.test.ts`)
  - [x] 📍 実装場所: `pose-est-front`

- [x] **12-2: キャッシュ設定 (フロントエンド側)**

  - [x] 静的アセット: `public/_headers` で `max-age=31536000, immutable`
  - [x] その他アセット: `max-age=604800` (1 週間)
  - [x] 📍 実装場所: `pose-est-front/public/_headers`

- [ ] **12-3: リダイレクト設定 (Production 構築時)**
  - [ ] `www` → apex ドメインリダイレクト
  - [ ] 📍 実装場所: Worker スクリプト or Cloudflare Redirect Rules

### 🔒 **フェーズ 5: セキュリティ設定**

#### ✅ タスク 13: WAF とセキュリティルール設定

**目的**: Web アプリケーションファイアウォール (WAF) を導入し、悪意のあるトラフィックやボットからアプリケーションを保護する

**サブタスク**:

- [x] **13-1: セキュリティモジュール作成 (`modules/security`)**

  - [x] `cloudflare_ruleset` リソースを使用した WAF 設定のモジュール化
  - [x] 変数定義: `zone_id`, `environment`
  - [x] 出力定義

- [x] **13-2: マネージド WAF ルールセット (Managed Rules)**

  - [x] **Cloudflare Managed Ruleset**: Terraform での有効化はスキップ (Free プラン制限)
  - [ ] **OWASP Core Ruleset**: Dashboard から手動有効化を推奨 (Free プラン)

- [x] **13-3: カスタムファイアウォールルール (Custom Rules)**

  - [x] **API 保護**: `/api/*` (`contains` operator) への不審なリクエストブロック
  - [x] **国別制限 (Geo-blocking)**: 日本国外からのボット以外を Challenge (初期無効)
  - [x] **脅威スコア制限**: Threat Score > 40 ブロック

- [x] **13-4: ボット対策 (Bot Fight Mode)**
  - [x] Dashboard で [Security] > [Bots] から "Bot Fight Mode" を ON にする (Terraform 非対応)
  - [x] 自動化されたボットアクセスの軽減

#### ✅ タスク 14: R2 セキュリティ強化

# (R2 セキュリティとアクセス制御の最適化)

- [x] **14-1: Public Access の無効化確認**

  - [x] Public Domain (r2.dev) が Terraform で構成されていないことを確認 (Verified in `modules/r2`)
  - [x] バケットへのアクセスを Worker Binding または署名付き URL 経由に限定するアーキテクチャの維持

- [x] **14-2: CORS ポリシーの環境別厳格化**

  - [x] Dev 環境: 開発効率のため `*` を許可 (現状維持)
  - [x] Prod 環境: `https://www.kenken-pose-est.online` のみに制限する変数の準備 (`tfvars.example` に記載)

- [x] **14-3: 許可メソッドの最小化**
  - [x] 現在の設定 (`GET`, `PUT`, `HEAD`, `POST`) がアプリケーション要件と合致しているか再確認 (署名付き UPLOAD 対応)
  - [x] 不要なメソッド (`DELETE` 等) が許可されていないことを維持 (Verified)

#### ✅ タスク 15: レート制限設定 (Free Plan Strategy)

- [x] **15-1: Security モジュール拡張 (`http_ratelimit`)**

  - [x] `cloudflare_ruleset` に `http_ratelimit` フェーズを追加定義
  - [x] Free プラン制限 (10s period, block action, colo-based) を考慮した設計

- [x] **15-2: API レート制限ルールの実装**
- [x] **対象**: `/api/*` (contains `/api/`)
  - [x] **ポリシー**: 20 requests / 10s (approx 120 req/min)
  - [x] **アクション**: `block` (Free プラン制限により managed_challenge 利用不可)
  - [x] **特性**: `ip.src` + `cf.colo.id` (PoP 単位でのカウント)

#### ✅ タスク 16: セキュリティヘッダー設定 (Defense in Depth)

**方針**: フロントエンド実装に加え、インフラ層 (Cloudflare) でもヘッダーを強制付与し、多層防御を実現する。(エラーページや予期せぬレスポンス漏れを防ぐため)

- [x] **16-1: Security モジュール拡張 (`http_response_headers_transform`)**

  - [x] `cloudflare_ruleset` (Transform Rules) を使用してレスポンスヘッダ変更フェーズを定義

- [x] **16-2: ベースラインセキュリティヘッダーの実装**
  - [x] `Strict-Transport-Security`: `max-age=63072000; includeSubDomains; preload`
  - [x] `X-Content-Type-Options`: `nosniff`
  - [x] `X-Frame-Options`: `DENY`
  - [x] `Referrer-Policy`: `strict-origin-when-cross-origin`
  - [x] **注意**: アプリ側と値が競合しないよう、`set` (上書き) または `set_if_missing` (不足時のみ) の戦略を選択 (現在は `set` で強制)

### ⚡ **フェーズ 6: パフォーマンス最適化**

#### ✅ タスク 17: パフォーマンスとプロトコル最適化 (Zone Settings)

- [x] **17-1: 最新プロトコルの有効化 (`modules/dns`)**

  - [x] **HTTP/3 (QUIC)**: 通信速度と信頼性の向上
  - [x] **0-RTT Connection Resumption**: 再接続時のレイテンシ短縮
  - [x] **IPv6**: 有効化確認

- [x] **17-2: キャッシュと配信の最適化**

  - [x] **Tiered Cache (Argo)**: Free プランではデフォルト設定を使用
  - [x] **Brotli**: 圧縮有効化 (Gzip より高効率)
  - [x] **Rocket Loader**: **無効化 (OFF)** (React アプリとの競合回避・ハイドレーション保護)
  - [x] **Auto Minify**: **無効化 (OFF)** (ビルドツール側での最適化を優先 - Terraform エラー回避のため手動確認またはデフォルト維持)

- [x] **17-3: Cache Rules (Optional)**
  - [x] 必要に応じて `cloudflare_ruleset` (`http_request_cache_settings`) を検討 (現状は Workers 制御を優先)

#### ✅ タスク 18: R2 スケーラビリティと最適化

- [x] **18-1: マルチパートアップロードのライフサイクル管理 (`modules/r2`)**

  - [x] **不完全なアップロードの削除**: 失敗または中断されたマルチパートアップロードを 7 日後に自動削除し、ストレージコストと整合性を維持する。
  - [x] **スケーラビリティ対応**: 大容量ファイル増加に伴うゴミデータの自動清掃メカニズムを確立。

- [x] **18-2: R2 スケーラブルアーキテクチャ設計 (Artifact)**
  - [x] **設計ドキュメント作成**: 大容量動画のマルチパートアップロード、並列処理、レジューム機能を実現するためのアーキテクチャガイドを作成 (`docs/r2_scalability_guide.md`)。
  - [x] **目的**: アプリケーション実装時の指針（Signed URL vs Worker）を明確化。

#### ⬜ タスク 19: 画像とアセット最適化

- [ ] 画像最適化: Polish の有効化
- [ ] WebP 変換: 自動的な次世代フォーマット配信
- [ ] ミニファイケーション: CSS/JS の自動圧縮
- [ ] 早期ヒンティング: 重要なリソースの事前読み込み

#### ⬜ タスク 20: ネットワーク最適化

- [ ] HTTP/2 と HTTP/3 の有効化
- [ ] 0-RTT 接続リサム: QUIC プロトコルの活用
- [ ] Argo Smart Routing: 最適なネットワーク経路の選択
- [ ] WebSocket 最適化: リアルタイム通信の効率化

### 📊 **フェーズ 7: 監視と分析**

#### ⬜ タスク 21: アナリティクス設定

- [ ] Terraform モジュール: `modules/monitoring`
- [ ] Web Analytics 有効化: プライバシー重視の分析
- [ ] カスタムメトリクス: ビジネス KPI の追跡
- [ ] R2 Analytics 連携: ストレージ使用量監視
- [ ] トラフィック分析ダッシュボードの設定

#### ⬜ タスク 22: ユーザー体験監視

- [ ] Browser Insights 有効化: 実際のユーザーメトリクス
- [ ] コアウェブバイタル監視: LCP, FID, CLS
- [ ] 合成モニタリング: 定期的なページ読み込みテスト
- [ ] リアルユーザーモニタリング (RUM): 詳細なパフォーマンスデータ

#### ⬜ タスク 23: アラート設定

- [ ] 帯域幅アラート: 異常なトラフィック増加
- [ ] セキュリティアラート: WAF ブロック数の急増
- [ ] パフォーマンスアラート: ページ読み込み時間の悪化
- [ ] **R2 ストレージアラート: 使用量が無料枠の 80%超**
- [ ] **R2 操作回数アラート: 無料枠の 80%超**
- [ ] 通知チャンネル設定: Slack/Email 通知

### 🔄 **フェーズ 8: CI/CD パイプライン完成 **

#### ⬜ タスク 24: フロントエンド CI/CD パイプライン

- [ ] GitHub Actions ワークフロー: `frontend-deploy.yml`
- [ ] ビルドステージ:
  - 依存関係インストール
  - テスト実行（Vitest）
  - ビルド最適化
- [ ] デプロイステージ:
  - Cloudflare Pages デプロイ
  - 環境別設定注入
- [ ] 検証ステージ:
  - 本番環境 E2E テスト
  - パフォーマンステスト

#### ⬜ タスク 25: インフラ CI/CD パイプライン

- [ ] GitHub Actions ワークフロー: `terraform-apply.yml`
- [ ] Plan ステージ:
  - Terraform 初期化
  - 計画実行と出力
  - セキュリティスキャン（Checkov）
- [ ] Apply ステージ（承認ベース）:
  - 環境別 Terraform 適用
  - 状態ファイル管理
- [ ] R2 テストステージ:
  - バケット作成確認
  - ライフサイクルポリシー検証
  - 署名 URL 生成テスト
- [ ] 検証ステージ:
  - DNS 設定確認
  - SSL 証明書検証
  - R2 アクセス検証

#### ⬜ タスク 26: プレビュー環境自動化

- [ ] ブランチベースのプレビュー環境自動作成
- [ ] PR ごとの一時的なドメイン割り当て
- [ ] プレビュー環境の自動クリーンアップ
- [ ] プレビュー環境のセキュリティ設定

#### ⬜ タスク 27: 署名 URL 統合テスト

- [ ] GCP バックエンドとの署名 URL 生成連携テスト
- [ ] クライアントからの直接 R2 アクセステスト
- [ ] 署名 URL 有効期限テスト
- [ ] エラーハンドリングテスト

### 🧪 **フェーズ 9: テストと検証 (R2 統合テスト)**

#### ⬜ タスク 28: 機能テスト

- [ ] DNS 解決テスト: すべてのドメインの正しい解決
- [ ] SSL/TLS テスト: 証明書の有効性と設定
- [ ] フロントエンド配信テスト: 全環境でのアクセス確認
- [ ] API 連携テスト: GCP バックエンドとの通信確認
- [ ] **R2 ストレージテスト: アップロード/ダウンロード機能**
- [ ] **署名 URL 生成テスト: 有効期限、アクセス制限**

#### ⬜ タスク 29: セキュリティテスト

- [ ] WAF ルールテスト: 攻撃パターンのブロック確認
- [ ] レート制限テスト: 過剰リクエストの制限確認
- [ ] セキュリティヘッダーテスト: 適切なヘッダー設定確認
- [ ] SSL/TLS 設定テスト: 暗号化強度の確認
- [ ] **R2 アクセス制御テスト: 未承認アクセスのブロック**
- [ ] **署名 URL セキュリティテスト: 期限切れ URL の無効化**

#### ⬜ タスク 30: パフォーマンステスト

- [ ] キャッシュ効果テスト: CDN キャッシュの動作確認
- [ ] グローバルアクセステスト: 各地域からのアクセス速度
- [ ] 負荷テスト: 大量トラフィックへの対応確認
- [ ] フェイルオーバーテスト: 障害時の動作確認
- [ ] **R2 アップロード/ダウンロード速度テスト**
- [ ] **同時アクセステスト: 複数ユーザーからの R2 アクセス**

### 📚 **フェーズ 10: ドキュメントと運用準備**

#### ⬜ タスク 31: 技術ドキュメント

- [ ] アーキテクチャ図作成（Cloudflare + R2 部分）
- [ ] デプロイ手順書作成
- [ ] トラブルシューティングガイド
- [ ] セキュリティ設定ガイド
- [ ] **R2 統合ガイド: 署名 URL 生成、アクセス制御**

#### ⬜ タスク 32: 運用ドキュメント

- [ ] 監視ダッシュボード説明書
- [ ] アラート対応手順
- [ ] DNS 変更手順
- [ ] 証明書更新手順
- [ ] **R2 運用ガイド: バケット管理、ライフサイクル設定**

#### ⬜ タスク 33: GCP 連携ドキュメント

- [ ] API 連携仕様書
- [ ] 環境変数連携手順
- [ ] 障害時の連携手順
- [ ] バージョン互換性マトリックス
- [ ] **R2 署名 URL 生成実装ガイド**
- [ ] **Secret Manager 連携手順**

#### ⬜ タスク 34: 最終検証と本番移行

- [ ] 本番環境最終テスト
- [ ] 移行計画作成（段階的ロールアウト）
- [ ] ロールバック計画作成 (R2 データ保全計画)
- [ ] 本番移行実行と検証

---

## 各フェーズ完了基準

1. **コード品質**: Terraform fmt, tflint, checkov でエラーなし
2. **テスト**: すべての機能テストが正常に完了
3. **ドキュメント**: 必要なドキュメントが作成済み
4. **セキュリティ**: セキュリティスキャンで重大な脆弱性なし
5. **GCP 連携**: API 連携が正常に動作
6. **R2 統合**: ストレージ層が完全に機能し、コスト最適化確認済み

## 重要注意事項 (R2 対応更新)

1. **状態ファイル管理**:

   - 開発/本番で状態ファイルを分離
   - 適切なバックエンド設定（推奨: Cloudflare R2 または Terraform Cloud）

2. **シークレット管理**:

   - API トークンは GitHub Secrets で管理
   - Terraform 変数で直接シークレットを扱わない
   - R2 アクセスキーは Secret Manager 経由で GCP バックエンドに渡す

3. **GCP 連携**:

   - API DNS レコードの値は GCP 側の完了を待って設定
   - R2 署名 URL 生成は GCP バックエンドで実装
   - 定期的な接続テストの実施

4. **コスト管理**:

   - 常に Free プランの範囲内で設計
   - R2 ストレージ使用量の監視（10GB 無料枠）
   - R2 操作回数の監視（100 万回/月無料枠）
   - 7 日ライフサイクルポリシーによるストレージ最適化

5. **R2 特有の注意点**:
   - S3 互換 API だが、完全な互換性ではない点に注意
   - 署名 URL の最大有効期限は 7 日間
   - マルチパートアップロードのサイズ制限確認
   - リージョン選択: `apac`（アジア太平洋）推奨
