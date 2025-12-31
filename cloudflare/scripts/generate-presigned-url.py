#!/usr/bin/env python3
"""
R2 署名付き URL (Presigned URL) 生成スクリプト
-----------------------------------------------------------------------------
指定したオブジェクトに対して、一時的に有効なアップロード用 (PUT) または
ダウンロード用 (GET) の署名付き URL を生成します。

使用方法:
  python3 generate-presigned-url.py <object_key> <method> [expiration_seconds]

  例: python3 generate-presigned-url.py test-video.mp4 PUT 3600
"""

import os
import sys
import boto3
from botocore.exceptions import ClientError
from botocore.config import Config

def generate_presigned_url(object_key, method="GET", expiration=3600):
    """
    R2 オブジェクトへの署名付き URL を生成する
    """
    account_id = os.environ.get('CLOUDFLARE_ACCOUNT_ID')
    access_key = os.environ.get('R2_ACCESS_KEY_ID')
    secret_key = os.environ.get('R2_SECRET_ACCESS_KEY')
    bucket_name = os.environ.get('R2_BUCKET_NAME', 'pose-est-videos-dev')
    
    if not all([account_id, access_key, secret_key]):
        print("❌ エラー: 必要な環境変数が設定されていません (CLOUDFLARE_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY)。")
        sys.exit(1)

    endpoint_url = f"https://{account_id}.r2.cloudflarestorage.com"
    
    # R2 用の設定 (署名バージョン v4 が必須)
    s3_config = Config(
        signature_version='s3v4',
        region_name='auto'
    )

    s3 = boto3.client('s3',
        endpoint_url=endpoint_url,
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        config=s3_config
    )

    try:
        url = s3.generate_presigned_url(
            ClientMethod='put_object' if method.upper() == 'PUT' else 'get_object',
            Params={'Bucket': bucket_name, 'Key': object_key},
            ExpiresIn=expiration
        )
        return url
    except ClientError as e:
        print(f"❌ URL 生成エラー: {e}")
        return None

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
        
    obj_key = sys.argv[1]
    method = sys.argv[2]
    expiry = int(sys.argv[3]) if len(sys.argv) > 3 else 3600
    
    print(f"🔑 生成中: {method} {obj_key} (有効期限: {expiry}秒)")
    print("-" * 60)
    
    url = generate_presigned_url(obj_key, method, expiry)
    
    if url:
        print(url)
        print("-" * 60)
        print("✅ 生成完了")
    else:
        sys.exit(1)
