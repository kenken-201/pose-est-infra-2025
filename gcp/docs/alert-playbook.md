# アラート対応プレイブック

このドキュメントでは、GCP Cloud Monitoring から発報されるアラートへの対応手順を説明します。

---

## 🚨 エラー率アラート

**アラート名**: `[dev] Cloud Run Error Rate High (> 5%)`

### 症状

Cloud Run サービスの 5xx エラー率が閾値 (5%) を超えています。

### 影響度

🔴 **High** - ユーザーへのサービス提供に影響

### 対応手順

#### Step 1: ログ確認

1. [Cloud Logging](https://console.cloud.google.com/logs/query) を開く
2. 以下のクエリでエラーログを確認:
   ```
   resource.type="cloud_run_revision"
   resource.labels.service_name="pose-est-backend-dev"
   severity>=ERROR
   ```
3. エラーメッセージからエラーの種類を特定

#### Step 2: 原因分析

| エラー種別                | 考えられる原因       | 対処法                             |
| ------------------------- | -------------------- | ---------------------------------- |
| 500 Internal Server Error | アプリケーションバグ | コード修正、ロールバック           |
| 502 Bad Gateway           | コンテナ起動失敗     | リソース設定確認、メモリ増加       |
| 503 Service Unavailable   | リソース不足         | インスタンス数増加、CPU/メモリ増加 |
| 504 Gateway Timeout       | 処理タイムアウト     | タイムアウト設定見直し             |

#### Step 3: 対処

- **直近のデプロイが原因の場合**: Cloud Run コンソールから前リビジョンにロールバック
- **リソース不足の場合**: `max_instance_count` を増加
- **外部依存サービス障害**: R2 等の依存サービスの状態を確認

#### Step 4: 解決確認

1. アラートが自動解消されることを確認
2. エラー率が正常範囲に戻ったことを確認

---

## ⏱️ レイテンシアラート

**アラート名**: `[dev] Cloud Run Latency High (> 5000ms)`

### 症状

Cloud Run サービスの応答時間 (p95) が閾値 (5000ms) を超えています。

### 影響度

🟡 **Medium** - ユーザー体験に影響（サービス停止ではない）

### 対応手順

#### Step 1: トレース確認

1. [Cloud Trace](https://console.cloud.google.com/traces/list) を開く
2. 遅いリクエストを選択し、ウォーターフォールチャートを確認
3. どの処理で時間がかかっているかを特定

#### Step 2: 原因分析

| ボトルネック     | 考えられる原因         | 対処法                         |
| ---------------- | ---------------------- | ------------------------------ |
| 画像処理         | 大きな画像、複雑な処理 | 画像サイズ制限、処理最適化     |
| R2 アクセス      | ネットワーク遅延       | リトライ設定、キャッシュ導入   |
| コールドスタート | インスタンス起動時間   | min_instance_count を 1 以上に |
| CPU/メモリ不足   | リソース制約           | リソース増加                   |

#### Step 3: 対処

- **コールドスタートが原因**: Terraform で `min_instance_count` を増加
- **リソース不足**: `cpu` / `memory` 設定を増加
- **アプリケーション処理**: コード最適化、非同期処理導入

#### Step 4: 解決確認

1. アラートが自動解消されることを確認
2. Cloud Trace で応答時間が改善されていることを確認

---

## 📞 エスカレーション

アラート発生から 30 分以内に解決できない場合、または原因が特定できない場合:

1. **開発チームリード**に連絡
2. 以下の情報を共有:
   - アラート名と発生時刻
   - 確認したログ・トレースのスクリーンショット
   - 試した対処法と結果

---

## 📚 関連リンク

- [GCP Cloud Run コンソール](https://console.cloud.google.com/run)
- [Cloud Logging](https://console.cloud.google.com/logs)
- [Cloud Trace](https://console.cloud.google.com/traces)
- [監視アーキテクチャ概要](./monitoring-overview.md)
