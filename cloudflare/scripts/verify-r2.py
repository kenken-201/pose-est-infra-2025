#!/usr/bin/env python3
"""
R2 バケット検証スクリプト
-----------------------------------------------------------------------------
指定された R2 バケットの存在確認と CORS 設定の検証を行います。
"""

import os
import boto3
from botocore.exceptions import ClientError

account_id = os.environ.get('CLOUDFLARE_ACCOUNT_ID')
access_key = os.environ.get('R2_ACCESS_KEY_ID')
secret_key = os.environ.get('R2_SECRET_ACCESS_KEY')
bucket_name = os.environ.get('R2_BUCKET_NAME', 'pose-est-videos-dev')

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
    print(f"✅ バケット '{bucket_name}' は存在します。")
    
    # CORS 設定の確認
    try:
        cors = s3.get_bucket_cors(Bucket=bucket_name)
        print("✅ CORS 設定が見つかりました:")
        for rule in cors['CORSRules']:
            print(f"   - Origins: {rule.get('AllowedOrigins')}")
            print(f"   - Methods: {rule.get('AllowedMethods')}")
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchCORSConfiguration':
            print("⚠️ CORS 設定が見つかりません。")
        else:
            print(f"⚠️ CORS 取得エラー: {e}")

except ClientError as e:
    print(f"❌ バケット確認エラー: {e}")
    exit(1)
