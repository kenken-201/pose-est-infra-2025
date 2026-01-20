# パフォーマンスモニタリング設定手順

このドキュメントでは、**GCP 無料枠**を活用したパフォーマンスモニタリングの設定手順を説明します。
Terraform による自動化がコストや複雑性の面で過剰な場合、GCP コンソールでの手動設定やアプリケーションコードでの対応を推奨しています。

---

## 1. 稼働率監視 (Uptime Checks)

GCP の Cloud Monitoring Uptime Checks を使用して、エンドポイントの健全性を定期的にチェックします。
月 100 件までは無料です。

### 手順（手動設定）

1. [GCP コンソール > Monitoring > Uptime Checks](https://console.cloud.google.com/monitoring/uptime) に移動します。
2. **「+ CREATE UPTIME CHECK」** をクリックします。

#### ① Target 設定

- **Title**: `Cloud Run Health Check (Dev)`
- **Target Type**: `URL`
- **Protocol**: `HTTPS`
- **Resource Type**: `URL`
- **Hostname**: `pose-est-backend-dev-blahblah.asia-northeast1.run.app` (実際の Cloud Run URL)
- **Path**: `/health`
- **Check Frequency**: `5 minutes` (無料枠節約のため長めに設定推奨、最短 1 分でも可)

#### ② Response Validation (オプション)

- **Response Timeout**: `10s`
- **Content match enabled**: 必要に応じて設定 (例: `{"status":"ok"}`)

#### ③ Alert & Notification

- **Alert Policy**: チェックを作成するとアラートポリシー作成画面に進みます。
- **Name**: `Uptime Check Failure - Cloud Run (Dev)`
- **Duration**: `1 minute` (1 分以上ダウンしたら通知)
- **Notification Channels**: 作成済みの Email チャンネルを選択

---

## 2. トレーシング (Cloud Trace)

Cloud Run などのマネージドサービスは、デフォルトで Cloud Trace にトレースデータを送信します。
これにより、リクエストごとのレイテンシの内訳（どこで時間がかかっているか）を可視化できます。

### 確認方法

1. [GCP コンソール > Trace > Trace list](https://console.cloud.google.com/trace/list) に移動します。
2. 最近のリクエスト一覧が表示されます。
3. 特定のリクエストをクリックすると、ウォーターフォールチャートが表示され、処理のボトルネックを特定できます。

### カスタム計装 (Backend)

アプリケーションコード内で特定のスパン（例: `process_image` 関数、`upload_to_r2` 関数）を詳細に計測したい場合は、OpenTelemetry を導入します。
現時点では Cloud Run の自動トレースで十分ですが、必要に応じてバックエンドチームと連携してください。

---

## 3. プロファイリング (Cloud Profiler)

Cloud Profiler は、本番環境で継続的に CPU やメモリの使用状況を収集し、パフォーマンスのボトルネックを特定するツールです。
**完全無料**で使用できますが、バックエンドアプリケーション側での設定が必要です。

### 有効化手順 (Backend)

1. **API 有効化**: `cloudprofiler.googleapis.com` (Terraform で有効化済み)
2. **ライブラリ追加**: `google-cloud-profiler` をバックエンドの依存関係に追加します。
3. **初期化コード追加**:

```python
# main.py の冒頭などで
import googlecloudprofiler

try:
    googlecloudprofiler.start(
        service='pose-est-backend',
        service_version='1.0.0',
        # verbose=3, # デバッグ時のみ
    )
except (ValueError, NotImplementedError) as exc:
    print(exc)  # ローカル環境などでは例外が出る場合があるため
```

4. デプロイ後、[GCP コンソール > Profiler](https://console.cloud.google.com/profiler) でデータを確認できます。
