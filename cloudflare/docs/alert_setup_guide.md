# Cloudflare & GitHub Actions アラート設定ガイド

このガイドでは、Terraform で自動化できない範囲のアラート通知設定（コスト、死活監視、セキュリティ）についての手順を説明します。

## 1. コスト監視 (R2 Usage)

R2 の無料枠 (10GB ストレージ, 100 万回クラス A 操作) を超過しないよう監視します。

### 設定手順 (Cloudflare Dashboard)

1. **Dashboard** にログインし、アカウントホーム（特定のドメイン選択前）を開きます。
2. 左メニューから **Notifications** を選択します。
3. **Add** (または Create Notification) をクリックします。
4. **Billing** カテゴリを選択し、**Usage-based Billing** (利用可能な場合) または関連するアラートを探します。
   - _Note_: Free プランかつクレジットカード未登録の場合、一部の Billing アラートが作成できない場合があります。その場合は定期的に **R2 > Overview** で使用量を確認してください。
   - 閾値設定例: "Notifications when spending exceeds $0" (不意の課金検知)。

### 手動確認フロー

- 週 1 回程度、**R2 > Overview** 画面で `Storage` と `Class A Operations` のグラフを確認し、急激な増加がないかチェックすることを推奨します。

## 2. 外形監視 (Synthetic Monitoring)

`monitor-uptime.yml` (GitHub Actions) が失敗した際に通知を受け取ります。

### 通知設定 (GitHub)

1. リポジトリの **Settings** > **Notifications** は存在しません (個人設定になります)。
2. 右上のアイコン > **Settings** > **Notifications** を確認。
3. **Actions** の項目で "Failed workflows" がチェックされていることを確認します（デフォルトで有効）。
   - これにより、`uptime-check` ジョブが失敗 (200 OK 以外) すると、GitHub 登録メールアドレスに通知が届きます。
4. (Optional) Slack 通知を行いたい場合、GitHub Actions に「Slack Notify」ステップを追加するか、GitHub App for Slack を導入してください。

## 3. セキュリティ監視 (Cloudflare Notifications)

DDoS 攻撃や異常な WAF ブロックを検知します。

### 設定手順 (Cloudflare Dashboard)

1. アカウントホーム > **Notifications** > **Add**。
2. **Security** カテゴリを選択。
3. 以下のイベント通知を作成します (Plan により利用可否が異なります):
   - **DDoS Attack**: L3/L4 攻撃検知時。
   - **WAF Alert**: (Business プラン以上の場合が多いですが、利用可能な項目があれば有効化)。
   - **Origin Error Rate**: オリジン(Cloud Run/Workers)のエラー率上昇 (Available on Pro+ often).

### 代替手段 (Free Plan)

- **Security > Events** 画面を定期的に確認し、ブロックされたリクエスト (`Block`, `Challenge`) の傾向を把握します。
- Task 13 で設定した「IP 制限」や「レート制限」のログもここに表示されます。
