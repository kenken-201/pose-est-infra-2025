import os
import boto3
from botocore.exceptions import ClientError

account_id = os.environ.get('CLOUDFLARE_ACCOUNT_ID')
access_key = os.environ.get('R2_ACCESS_KEY_ID')
secret_key = os.environ.get('R2_SECRET_ACCESS_KEY')
bucket_name = os.environ.get('R2_BUCKET_NAME', 'pose-est-videos-dev')

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
    print(f"✅ Bucket '{bucket_name}' exists.")
    
    # Check CORS (via Boto3 if possible, or just skip and use curl)
    try:
        cors = s3.get_bucket_cors(Bucket=bucket_name)
        print("✅ CORS Configuration found:")
        for rule in cors['CORSRules']:
            print(f"   - Origins: {rule.get('AllowedOrigins')}")
            print(f"   - Methods: {rule.get('AllowedMethods')}")
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchCORSConfiguration':
            print("⚠️ No CORS configuration found.")
        else:
            print(f"⚠️ Error getting CORS: {e}")

except ClientError as e:
    print(f"❌ Error checking bucket: {e}")
    exit(1)
