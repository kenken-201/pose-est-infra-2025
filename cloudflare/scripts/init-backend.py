#!/usr/bin/env python3
"""
Terraform Backend 初期化スクリプト
-----------------------------------------------------------------------------
Cloudflare R2 上に Terraform State 保存用のバケットを作成します。
"""

import os
import boto3
from botocore.exceptions import ClientError

# 環境変数の取得
account_id = os.environ.get('CLOUDFLARE_ACCOUNT_ID')
access_key = os.environ.get('R2_ACCESS_KEY_ID')
secret_key = os.environ.get('R2_SECRET_ACCESS_KEY')
bucket_name = "pose-est-terraform-state"

if not all([account_id, access_key, secret_key]):
    print("❌ エラー: 必要な環境変数が設定されていません。")
    exit(1)

endpoint_url = f"https://{account_id}.r2.cloudflarestorage.com"

print(f"🔌 R2 エンドポイントに接続中: {endpoint_url}")
s3 = boto3.client('s3',
    endpoint_url=endpoint_url,
    aws_access_key_id=access_key,
    aws_secret_access_key=secret_key,
    region_name='auto' 
)

print(f"🔍 バケットを確認中: {bucket_name}...")
try:
    s3.head_bucket(Bucket=bucket_name)
    print(f"✅ バケット '{bucket_name}' は既に存在します。")
except ClientError as e:
    error_code = int(e.response['Error']['Code'])
    if error_code == 404:
        print(f"🛠  バケット '{bucket_name}' を作成中...")
        s3.create_bucket(Bucket=bucket_name)
        print(f"✅ バケット '{bucket_name}' の作成に成功しました。")
    else:
        print(f"❌ バケット確認中にエラーが発生しました: {e}")
        exit(1)
