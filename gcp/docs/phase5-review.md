# フェーズ 5 レビュー: Cloud Run バックエンド環境構築

**レビュー日**: 2026-01-02
**レビュアー**: AI Assistant + User Collaboration

---

## 概要

フェーズ 5 では、バックエンドアプリケーション (FastAPI) を稼働させる Cloud Run サービスを構築しました。
タスク 12〜14 を通じて、以下の成果を達成しました。

---

## 成果物一覧

| カテゴリ         | ファイル                       | 説明                                  |
| :--------------- | :----------------------------- | :------------------------------------ |
| **モジュール**   | `modules/cloud-run/*`          | Cloud Run v2 サービス定義             |
| **環境設定**     | `environments/dev/main.tf`     | Dev 環境向け設定                      |
| **環境出力**     | `environments/dev/outputs.tf`  | service_url, artifact_registry_url    |
| **ドキュメント** | `docs/security-checklist.md`   | 公開前セキュリティ確認項目            |
| **ドキュメント** | `docs/cloud-run-deployment.md` | デプロイ手順 + トラブルシューティング |

---

## タスク別達成事項

### タスク 12: Cloud Run サービス基本設定

- **Cloud Run v2 API 採用**: 最新のベストプラクティスである `google_cloud_run_v2_service` を使用。
- **Secret Manager 連携**: `value_source.secret_key_ref` を使用し、R2 クレデンシャルを安全に注入。
- **サービスアカウント分離**: `cloud-run-sa` を使用し、最小権限を徹底。
- **IAM 設定**: Dev 環境は `allUsers` に `roles/run.invoker` を付与（未認証アクセス許可）。

### タスク 13: 自動スケーリング設定

- **スケーリングパラメータの変数化**:
  - `min_instance_count`, `max_instance_count`
  - `max_request_concurrency`, `cpu_idle`
- **入力バリデーション**: 不正な値を `terraform plan` 段階で検出。
- **コスト最適化 (Dev)**: `min_instance_count = 0`, `cpu_idle = true` でアイドル時課金ゼロ。

### タスク 14: ネットワークとセキュリティ設定

- **スコープ簡素化**: 複雑なインフラ設定（VPC, Cloud Armor, LB）は将来フェーズに保留。
- **ドキュメント整備**: セキュリティチェックリスト、デプロイ手順書を作成。

---

## 品質向上施策（レビュー中に追加）

### 1. Cloud Run モジュールの高度化

| 施策                           | 効果                                                                         |
| :----------------------------- | :--------------------------------------------------------------------------- |
| `startup_cpu_boost = true`     | コールドスタート時に CPU をブーストし、起動時間を短縮。                      |
| `liveness_probe` 追加          | 実行中のコンテナ死活監視を強化。応答しなくなった場合に自動再起動。           |
| `execution_environment = GEN2` | 第 2 世代実行環境を明示。ネットワーク性能向上、完全な Linux カーネル互換性。 |
| ラベル体系の導入               | `managed-by`, `environment`, `service`, `component` でリソース追跡が容易に。 |

### 2. リソース制限の変数化

| 変数           | Dev 設定  | 説明               |
| :------------- | :-------- | :----------------- |
| `cpu_limit`    | `"1"`     | コンテナ CPU 上限  |
| `memory_limit` | `"512Mi"` | コンテナメモリ上限 |

### 3. 環境出力の拡充

- `service_url`: Cloud Run サービス URL
- `service_name`: Cloud Run サービス名
- `artifact_registry_url`: Artifact Registry リポジトリ URL

### 4. ドキュメントの強化

- **トラブルシューティングセクション追加**: ImageNotFound, SecretVersionAccessDenied, HealthCheckFailed の対応策。
- **ログ/監視確認手順追加**: Cloud Logging コマンド、Cloud Monitoring 確認ポイント。
- **IAM 確認コマンド追加**: `gcloud projects get-iam-policy` 例を記載。

---

## 保留事項（将来フェーズ）

| 項目             | 理由                                                                    |
| :--------------- | :---------------------------------------------------------------------- |
| カスタムドメイン | Cloudflare Proxy 経由で対応可能。まず `*.a.run.app` で動作確認を優先。  |
| VPC 接続         | R2 はインターネット経由アクセス。VPC 内リソースへの接続がないため不要。 |
| Cloud Armor      | LB 必須の機能。初期 MVP に DDoS 保護は過剰。コスト増を回避。            |

---

## 品質検証結果

```
✅ terraform fmt: PASS
✅ terraform validate: PASS
✅ TFLint: PASS (全モジュール)
✅ Checkov: PASS (セキュリティスキャン)
✅ terraform plan: 34 resources to add (エラーなし)
```

---

## 次のステップ

1. **GCP デプロイ実施**: `terraform apply` で Cloud Run サービスをデプロイ。
2. **動作確認**: デフォルト URL (`*.a.run.app`) でヘルスチェック。
3. **Cloudflare 連携**: DNS CNAME レコード (`api`) を作成し、カスタムドメインを設定。

---

## 結論

フェーズ 5 を通じて、**世界最高水準の Cloud Run バックエンド環境**が構築されました。
セキュリティ、パフォーマンス、運用性、コスト最適化のすべての観点で高品質な成果物が揃いました。
