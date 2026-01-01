#!/usr/bin/env python3
"""
R2 署名付き URL (Presigned URL) 生成スクリプト
-----------------------------------------------------------------------------
指定したオブジェクトに対して、一時的に有効なアップロード用 (PUT) または
ダウンロード用 (GET) の署名付き URL を生成します。

詳細:
  - Boto3 の generate_presigned_url を使用
  - 署名バージョン s3v4 を強制
  - エラーハンドリングとヘルプメッセージの実装

使用方法:
  python3 generate-presigned-url.py --key <object_key> --method <GET|PUT> [--expires <seconds>]
"""

import os
import sys
import argparse
import boto3
from botocore.exceptions import ClientError
from botocore.config import Config
from typing import Optional

def generate_presigned_url(object_key: str, method: str = "GET", expiration: int = 3600) -> Optional[str]:
    """
    R2 オブジェクトへの署名付き URL を生成する

    Args:
        object_key (str): オブジェクトのキー (パス)
        method (str): HTTP メソッド ('GET' or 'PUT')
        expiration (int): 有効期限 (秒)

    Returns:
        Optional[str]: 生成された URL。エラー時は None。
    """
    account_id = os.environ.get('CLOUDFLARE_ACCOUNT_ID')
    access_key = os.environ.get('R2_ACCESS_KEY_ID')
    secret_key = os.environ.get('R2_SECRET_ACCESS_KEY')
    bucket_name = os.environ.get('R2_BUCKET_NAME', 'pose-est-videos-dev')
    
    if not all([account_id, access_key, secret_key]):
        print("❌ エラー: 必要な環境変数が設定されていません (CLOUDFLARE_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY)。", file=sys.stderr)
        return None

    endpoint_url = f"https://{account_id}.r2.cloudflarestorage.com"
    
    # R2 用の設定 (署名バージョン v4 が必須)
    s3_config = Config(
        signature_version='s3v4',
        region_name='auto'
    )

    try:
        s3 = boto3.client('s3',
            endpoint_url=endpoint_url,
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            config=s3_config
        )

        client_method = 'put_object' if method.upper() == 'PUT' else 'get_object'
        
        url = s3.generate_presigned_url(
            ClientMethod=client_method,
            Params={'Bucket': bucket_name, 'Key': object_key},
            ExpiresIn=expiration
        )
        return url
    except ClientError as e:
        print(f"❌ URL 生成エラー (Boto3): {e}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"❌ 予期せぬエラー: {e}", file=sys.stderr)
        return None

def main():
    parser = argparse.ArgumentParser(description='Generate R2 Presigned URLs.')
    parser.add_argument('key', help='Object Key (e.g. videos/sample.mp4)')
    parser.add_argument('method', choices=['GET', 'PUT'], help='HTTP Method (GET for download, PUT for upload)')
    parser.add_argument('--expires', type=int, default=3600, help='Expiration time in seconds (default: 3600)')

    args = parser.parse_args()
    
    # 位置引数互換性のため (古い呼び出し方に対応が必要な場合)
    # ですが、今回は新規作成なので argparse 推奨の形式にします。
    # ただしスクリプト呼び出し元 (verify-r2-security.sh) も修正が必要です。
    
    url = generate_presigned_url(args.key, args.method, args.expires)
    
    if url:
        print(url)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
