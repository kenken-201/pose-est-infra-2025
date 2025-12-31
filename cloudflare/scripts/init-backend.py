import os
import boto3
from botocore.exceptions import ClientError

account_id = os.environ.get('CLOUDFLARE_ACCOUNT_ID')
access_key = os.environ.get('R2_ACCESS_KEY_ID')
secret_key = os.environ.get('R2_SECRET_ACCESS_KEY')
bucket_name = "pose-est-terraform-state"

if not all([account_id, access_key, secret_key]):
    print("❌ Error: Missing required environment variables.")
    exit(1)

endpoint_url = f"https://{account_id}.r2.cloudflarestorage.com"

print(f"🔌 Connecting to R2 Endpoint: {endpoint_url}")
s3 = boto3.client('s3',
    endpoint_url=endpoint_url,
    aws_access_key_id=access_key,
    aws_secret_access_key=secret_key,
    region_name='auto' 
)

print(f"🔍 Checking bucket: {bucket_name}...")
try:
    s3.head_bucket(Bucket=bucket_name)
    print(f"✅ Bucket '{bucket_name}' already exists.")
except ClientError as e:
    error_code = int(e.response['Error']['Code'])
    if error_code == 404:
        print(f"🛠  Creating bucket '{bucket_name}'...")
        s3.create_bucket(Bucket=bucket_name)
        print(f"✅ Bucket '{bucket_name}' created successfully.")
    else:
        print(f"❌ Error checking bucket: {e}")
        exit(1)
