# Cloudflare 認証セットアップガイド

このガイドでは、Terraform が Cloudflare リソースを管理するために必要な API Token を生成する方法について説明します。

## 1. API Token の作成

1. Cloudflare Dashboard にログインします。
2. **My Profile** > **API Tokens** に移動します。
3. **Create Token** をクリックします。
4. **Custom Token** テンプレート (Get started) を使用します。
5. トークンに名前を付けます (例: `Terraform Provisioning`)。
6. **Permissions**: 以下の権限を設定します:

   - **Zone** > **Zone** > **Read**
   - **Zone** > **DNS** > **Edit** (Read/Write)
   - **Account** > **Cloudflare Pages** > **Edit** (Read/Write)
   - **Account** > **Worker R2 Storage** > **Edit** (Read/Write)
   - **Account** > **Account Settings** > **Read** (Account ID 検証用)
   - **Zone** > **Workers Routes** > **Edit** (Workers を使用する場合)
   - **Zone** > **Firewall Services** > **Edit** (WAF 用)
   - **Zone** > **Page Rules** > **Edit** (Page Rules 用)

   _注意: "Include" > "All zones" (または特定のゾーン `kenken-pose-est.online`) が選択されていることを確認してください。_

7. **Continue to summary** をクリックし、**Create Token** をクリックします。
8. **トークンをすぐにコピーしてください** (再表示されません)。

## 2. Account ID の取得

1. ダッシュボードのホームページに移動します。
2. URL は `https://dash.cloudflare.com/<ACCOUNT_ID>` となっています。
3. `<ACCOUNT_ID>` の部分をコピーします。

## 3. R2 Access Keys (Backend/Terraform State 用)

1. サイドバーから **R2** に移動します。
2. **Manage R2 API Tokens** をクリックします。
3. **Create API Token** をクリックします。
4. Permissions: **Admin Read & Write** を選択します。
5. TTL: **Forever** (または必要に応じて) を設定します。
6. **Create API Token** をクリックします。
7. **Access Key ID** と **Secret Access Key** をコピーします。

## 4. ローカルセットアップ (Local Setup)

1. `.env.example` を `.env` にコピーします:
   ```bash
   cp pose-est-infra/cloudflare/.env.example pose-est-infra/cloudflare/.env
   ```
2. `.env` の値を入力します:
   ```bash
   CLOUDFLARE_API_TOKEN="your_token_here"
   CLOUDFLARE_ACCOUNT_ID="your_account_id_here"
   R2_ACCESS_KEY_ID="your_r2_access_key_id"
   R2_SECRET_ACCESS_KEY="your_r2_secret_key"
   ```

## 5. アプリケーション用 R2 アクセスキーの発行 (タスク 6)

アプリケーション（GCP Backend など）から R2 バケットのみへのアクセスに限定した、セキュアなアクセスキーを発行します。

1. **API トークン作成画面へ移動**:

   - Cloudflare Dashboard > R2 > 画面右側の「Manage R2 API Tokens」をクリック。
   - 「Create API Token」をクリック。

2. **トークン設定**:

   - **Token Name**: `pose-est-backend-app` (任意の識別名)
   - **Permissions**: `Object Read & Write` を選択。
   - **Specific Bucket(s)**: `Apply to specific bucket(s) only` を選択し、作成したバケット（例: `pose-est-videos-dev`）のみを選択。**推奨**: セキュリティのため、全バケットへのアクセス権は避けてください。
   - **TTL**: 必要に応じて設定（`Forever` またはポリシーに従って設定）。

3. **発行と保存**:

   - 「Create API Token」をクリック。
   - 表示された `Access Key ID` と `Secret Access Key` をコピーします。
   - **注意**: Secret Key はこの画面でしか確認できません。

4. **ローカル環境への登録**:

   - プロジェクトルートで以下のヘルパースクリプトを実行し、キーを登録します。
     ```bash
     ./pose-est-infra/cloudflare/scripts/setup-secrets.sh
     ```

5. **GitHub Secrets への登録**:
   - 以下のスクリプトを実行して、CI/CD 用に登録します (gh CLI が必要)。
     ```bash
     ./pose-est-infra/cloudflare/scripts/register-gh-secrets.sh
     ```

## 6. 検証 (Verification)

トークンが機能することを確認するために検証スクリプトを実行します:

```bash
cd pose-est-infra/cloudflare
make verify-auth
# または
./scripts/verify-auth.sh
```
