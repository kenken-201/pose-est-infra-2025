# フェーズ 2 コードレビュー: R2 ストレージ層設定

**レビュアー**: クラウドインフラストラクチャエンジニア (Terraform / Cloudflare スペシャリスト)
**日付**: 2025-12-31
**ステータス**: ✅ 全ての問題を解決済み

---

## 概要

フェーズ 2 では、Cloudflare R2 を使用した動画ストレージ層を構築しました。Terraform モジュールによるインフラ管理、セキュアなアクセス制御、署名付き URL によるクライアント直接アクセスの基盤を確立しました。

---

## レビュー結果と適用した改良

### 1. [Critical] R2 Terraform モジュールの作成

再利用可能な R2 バケットモジュールを `terraform/modules/r2/` に作成しました。

| ファイル       | 内容                                        |
| -------------- | ------------------------------------------- |
| `main.tf`      | バケット、ライフサイクル、CORS リソース定義 |
| `variables.tf` | 入力変数 (バリデーション付き)               |
| `outputs.tf`   | バケット名、ドメイン、保持期間の出力        |
| `versions.tf`  | プロバイダーバージョン制約                  |

**改善点**:

- `retention_days` 変数を追加し、ライフサイクルポリシーを動的に設定可能に
- `cors_origins` に空リスト禁止のバリデーションを追加
- `bucket_domain` 出力を `sensitive = true` に設定し、アカウント ID の漏洩を防止

---

### 2. [Security] CORS 設定の厳格化

開発・本番環境で許可オリジンを分離し、ワイルドカード (`["*"]`) を排除しました。

| 環境       | 許可オリジン                                                  |
| ---------- | ------------------------------------------------------------- |
| Dev        | `localhost:3000`, `dev.kenken-pose-est.online`, `*.pages.dev` |
| Production | `kenken-pose-est.online`, `www.kenken-pose-est.online`        |

**設定ファイル**:

- `terraform/environments/dev/terraform.tfvars`
- `terraform/environments/production/terraform.tfvars`

---

### 3. [Security] アクセスキー管理の自動化

Cloudflare Dashboard での手動キー発行と、スクリプトによる安全な登録フローを確立しました。

| スクリプト                       | 機能                               |
| -------------------------------- | ---------------------------------- |
| `scripts/setup-secrets.sh`       | ローカル `.env` への対話式キー登録 |
| `scripts/register-gh-secrets.sh` | GitHub Secrets への一括登録        |

**セキュリティ強化**:

- `.env` ファイルのパーミッションを `600` に強制設定
- 更新前に自動バックアップ (`.env.bak`) を作成
- Git リポジトリ外での実行を検出してエラー終了

---

### 4. [Feature] 署名付き URL (Presigned URL) の実装

バックエンド実装のリファレンスとなる Python スクリプトを作成しました。

**ファイル**: `scripts/generate-presigned-url.py`

```python
# 使用例
python3 generate-presigned-url.py <object_key> <GET|PUT> --expires 3600
```

**実装詳細**:

- `argparse` による堅牢な CLI インターフェース
- Type Hints と Docstrings による可読性向上
- `boto3` の `s3v4` 署名を使用

---

### 5. [Testing] セキュリティ自動検証

R2 バケットのセキュリティ設定を自動検証するスクリプトを作成しました。

**ファイル**: `scripts/verify-r2-security.sh`

| テスト項目                    | 期待結果           |
| ----------------------------- | ------------------ |
| 認証なしアクセス              | 400/401/403 で拒否 |
| 署名付き URL でのアップロード | 成功               |
| 署名付き URL でのダウンロード | 成功               |

**改善点**:

- `trap` によるテストファイルの確実なクリーンアップ

---

### 6. [DevOps] 運用スクリプトの整備

Terraform 操作を簡素化するヘルパースクリプトを作成しました。

| スクリプト                | 機能                              |
| ------------------------- | --------------------------------- |
| `scripts/init-backend.sh` | R2 State バケットの初期化         |
| `scripts/init-backend.py` | `boto3` によるバケット作成        |
| `scripts/plan-dev.sh`     | Dev 環境の `terraform plan` 実行  |
| `scripts/apply-dev.sh`    | Dev 環境の `terraform apply` 実行 |
| `scripts/verify-r2.sh`    | R2 バケット存在・CORS 設定確認    |

---

### 7. [Cleanup] 不要ファイルの除外

Git 履歴から不要なファイルを削除し、`.gitignore` を更新しました。

```diff
+ # Terraform Plan files
+ *.tfplan
+
+ # Provider schema dumps
+ schema.json
```

**削除したファイル**:

- `terraform/dev.tfplan`
- `terraform/schema.json`

---

## 最終品質チェック

| 項目                    | ステータス                   |
| ----------------------- | ---------------------------- |
| `terraform fmt`         | ✅ パス                      |
| `terraform validate`    | ✅ パス                      |
| `tflint`                | ✅ パス (未使用変数警告のみ) |
| `checkov`               | ✅ パス                      |
| CORS ワイルドカード排除 | ✅ 完了                      |
| 署名付き URL 動作確認   | ✅ 成功                      |
| 公開アクセス拒否確認    | ✅ 成功                      |
| シークレット管理自動化  | ✅ 導入済み                  |
| 変数バリデーション      | ✅ 厳格化済み                |

---

## 作成・変更されたファイル一覧

### Terraform

| パス                                                 | 変更種別 |
| ---------------------------------------------------- | -------- |
| `terraform/modules/r2/main.tf`                       | 新規     |
| `terraform/modules/r2/variables.tf`                  | 新規     |
| `terraform/modules/r2/outputs.tf`                    | 新規     |
| `terraform/modules/r2/versions.tf`                   | 新規     |
| `terraform/main.tf`                                  | 変更     |
| `terraform/outputs.tf`                               | 変更     |
| `terraform/variables.tf`                             | 変更     |
| `terraform/environments/dev/terraform.tfvars`        | 新規     |
| `terraform/environments/production/terraform.tfvars` | 新規     |

### スクリプト

| パス                                | 変更種別                    |
| ----------------------------------- | --------------------------- |
| `scripts/init-backend.sh`           | 新規                        |
| `scripts/init-backend.py`           | 新規                        |
| `scripts/plan-dev.sh`               | 新規                        |
| `scripts/apply-dev.sh`              | 新規                        |
| `scripts/verify-r2.sh`              | 新規                        |
| `scripts/verify-r2.py`              | 新規                        |
| `scripts/setup-secrets.sh`          | 新規                        |
| `scripts/register-gh-secrets.sh`    | 新規                        |
| `scripts/generate-presigned-url.py` | 新規                        |
| `scripts/verify-r2-security.sh`     | 新規                        |
| `scripts/requirements.txt`          | 新規 (別エージェントが追加) |

### ドキュメント

| パス                 | 変更種別 |
| -------------------- | -------- |
| `docs/setup-auth.md` | 変更     |

---

## 次のステップ

フェーズ 2 の R2 ストレージ層構築が完了しました。次は **フェーズ 3: DNS とドメイン設定** に進みます。
