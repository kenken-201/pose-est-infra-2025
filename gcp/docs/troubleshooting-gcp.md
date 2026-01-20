# GCP デプロイ時のトラブルシューティング

このドキュメントは、`pose-est-infra/gcp` の Terraform を使ってデプロイする際に発生しやすい問題とその対処法をまとめたものです。

## 目次
- [Cloud Run のデプロイ・起動に関する問題](#cloud-run-のデプロイ起動に関する問題)
- [Terraform の実行に関する問題](#terraform-の実行に関する問題)

---

## Cloud Run のデプロイ・起動に関する問題

### 1. イメージが見つからない (Image not found)

`terraform apply` 中に Cloud Run が `Image '...:latest' not found` というエラーで失敗する場合があります。

#### 主な原因と対処法

*   **原因 A: イメージが Artifact Registry に存在しない**
    *   Terraform でリソースを作成する前に、バックエンドのコンテナイメージがビルド＆プッシュされていません。
    *   **対処法**: `apply` を実行する前に、必ず以下のスクリプトでイメージをビルド・プッシュしてください。
        ```bash
        ./gcp/scripts/push-backend-image.sh
        ```

*   **原因 B: `:latest` タグが更新されても Terraform が検知しない**
    *   `push-backend-image.sh` を実行してイメージを更新しても、Terraform はイメージ URL (`...:latest`) が変わらないため、変更を検知せず新しいリビジョンを作成しません。結果として、古い（問題のある）イメージを使い続けてしまいます。
    *   **対処法 1 (手動)**: `gcloud` コマンドでサービスを強制的に更新し、最新のイメージをデプロイさせます。
        ```bash
        gcloud run services update pose-est-backend-dev \
          --image=asia-northeast1-docker.pkg.dev/kenken-pose-est/pose-est-backend-dev/pose-est-backend:latest \
          --project=kenken-pose-est \
          --region=asia-northeast1
        ```
    *   **対処法 2 (恒久)**: Terraform が変更を検知できるように、`cloud-run/main.tf` のアノテーションにビルド時刻や Git コミットハッシュを含める方法が推奨されます。（将来的な改善点）


### 2. スタートアッププローブに失敗 (Startup probe failed)

Cloud Run のデプロイは開始されるものの、コンテナが正常に起動せず、ヘルスチェックに失敗するケースです。

#### 主な原因と対処法

*   **原因 A: Python の依存関係不足**
    *   ログに `ModuleNotFoundError: No module named 'ffmpeg'` のようなエラーが出力されることがあります。
    *   `pose-est-backend` の `pyproject.toml` にライブラリが記載されていない、または `Dockerfile` で必要なシステムパッケージ (`apt-get install` でのインストール) が不足しています。
    *   **対処法**:
        1.  `pose-est-backend/pyproject.toml` に不足している Python ライブラリ（例: `ffmpeg-python`）を追加します。
        2.  `pose-est-backend/Dockerfile` の `apt-get install` に不足しているシステムパッケージ（例: `ffmpeg`）を追加します。
        3.  `poetry.lock` を更新し (`cd ../pose-est-backend && poetry lock`)、`push-backend-image.sh` でイメージを再ビルドします。

*   **原因 B: ヘルスチェックのパスが違う**
    *   ログに `GET /health HTTP/1.1" 404 Not Found` のようなエラーが出力されます。
    *   Terraform (`cloud-run/main.tf`) で指定しているプローブのパス (`/health`) と、バックエンドアプリケーションで実装されているヘルスチェックエンドポイントのパス (`/api/v1/health`) が一致していません。
    *   **対処法**: `gcp/terraform/modules/cloud-run/main.tf` を開き、`startup_probe` と `liveness_probe` の `path` をアプリケーションの実装と一致させてください。
        ```hcl
        # 修正前
        path = "/health"
        # 修正後
        path = "/api/v1/health"
        ```

### 3. Secret が見つからない (Secret not found)

Cloud Run の起動時に `Secret .../versions/latest was not found` というエラーが出る場合があります。

#### 主な原因と対処法

*   **原因**: Terraform で Secret Manager の Secret リソース（いわば「箱」）は作成されましたが、その中に実際の値（バージョン）が登録されていません。
*   **対処法**: 以下のスクリプトを実行し、対話形式で R2 のクレデンシャルを Secret Manager に登録してください。
    ```bash
    ./gcp/scripts/register-r2-secrets.sh
    ```

---

## Terraform の実行に関する問題

### 1. プランが古い (Saved plan is stale)

`terraform apply` を実行した際に `Saved plan is stale` というエラーが出る場合があります。

#### 主な原因と対処法

*   **原因**: `terraform plan` を実行して `dev.tfplan` ファイルを作成した後、GCP 上のリソースが手動や別のプロセスで変更されたため、プランと実際の状態に差分が生じています。
*   **対処法**: `plan-dev.sh` を再実行して、最新の状態に基づいたプランファイルを生成し直してから `apply` を実行してください。
    ```bash
    ./gcp/scripts/plan-dev.sh
    ./gcp/scripts/apply-dev.sh
    ```

### 2. 削除保護によりリソースを破棄できない

`tainted` 状態のリソースを再作成しようとした際などに `cannot destroy service without setting deletion_protection=false` というエラーが出る場合があります。

#### 主な原因と対処法

*   **原因**: Google Provider v6 以降、Cloud Run サービスなど一部のリソースでは誤削除を防ぐ `deletion_protection` がデフォルトで有効になっています。Terraform は tainted なリソースを「破棄 & 再作成」しようとしますが、この保護に阻まれてしまいます。
*   **対処法**:
    1.  **Taint の解除**: まず、`untaint` コマンドでリソースの Taint 状態を解除します。
        ```bash
        cd gcp/terraform/environments/dev
        terraform untaint module.cloud_run.google_cloud_run_v2_service.service
        ```
    2.  **削除保護の無効化**: `gcp/terraform/modules/cloud-run/main.tf` の `google_cloud_run_v2_service` リソースに `deletion_protection = false` を明記します。これにより、開発環境での迅速なイテレーションが可能になります。
    3.  再度 `plan` と `apply` を実行します。今度は「破棄」ではなく「更新」として扱われます。

### 3. Terraform の Output が空になる

`apply` は成功したのに `terraform output service_url` の結果が空になることがあります。

#### 主な原因と対処法

*   **原因**: `apply` の直後、Terraform の state ファイルに Cloud Run の URL などの算出された値 (Computed Value) が即座に反映されていない場合があります。
*   **対処法**: `terraform refresh` を実行すると、現在のクラウド上のリソースの状態を state ファイルに同期させることができます。これにより、出力値が正しく表示されるようになります。
    ```bash
    cd gcp/terraform/environments/dev
    terraform refresh
    ```
