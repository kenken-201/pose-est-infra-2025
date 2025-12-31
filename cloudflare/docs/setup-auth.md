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

## 5. 検証 (Verification)

トークンが機能することを確認するために検証スクリプトを実行します:

```bash
cd pose-est-infra/cloudflare
make verify-auth
# または
./scripts/verify-auth.sh
```
