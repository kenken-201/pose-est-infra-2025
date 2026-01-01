import os
import sys
import requests
import json
# Load .env manually to avoid dependencies
def load_env_file(filepath):
    env_vars = {}
    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                if '=' in line:
                    key, value = line.split('=', 1)
                    # Remove quotes if present
                    value = value.strip('"').strip("'")
                    env_vars[key.strip()] = value
    return env_vars

env_path = os.path.join(os.path.dirname(__file__), "../.env")
env_vars = load_env_file(env_path)

ZONE_ID = env_vars.get("CLOUDFLARE_ZONE_ID") or env_vars.get("TF_VAR_CLOUDFLARE_ZONE_ID") or os.getenv("CLOUDFLARE_ZONE_ID")
API_TOKEN = env_vars.get("CLOUDFLARE_API_TOKEN") or os.getenv("CLOUDFLARE_API_TOKEN")

if not ZONE_ID or not API_TOKEN:
    print("❌ Error: CLOUDFLARE_ZONE_ID or CLOUDFLARE_API_TOKEN not found in .env")
    sys.exit(1)

HEADERS = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

def check_setting(setting_id, expected_value, value_key="value"):
    url = f"https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/settings/{setting_id}"
    try:
        response = requests.get(url, headers=HEADERS)
        response.raise_for_status()
        data = response.json()
        
        if not data["success"]:
            print(f"❌ Error fetching {setting_id}: {data.get('errors')}")
            return False

        current_value = data["result"][value_key]
        if current_value == expected_value:
            print(f"✅ {setting_id}: {current_value}")
            return True
        else:
            print(f"❌ {setting_id}: Expected {expected_value}, got {current_value}")
            return False

    except Exception as e:
        print(f"❌ Exception checking {setting_id}: {e}")
        return False

def check_dnssec():
    url = f"https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/dnssec"
    try:
        response = requests.get(url, headers=HEADERS)
        response.raise_for_status()
        data = response.json()
        
        if not data["success"]:
            print(f"❌ Error fetching DNSSEC: {data.get('errors')}")
            return False

        status = data["result"]["status"]
        if status == "active":
            print(f"✅ DNSSEC: active")
            return True
        else:
            print(f"❌ DNSSEC: Expected active, got {status}")
            return False
    except Exception as e:
        print(f"❌ Exception checking DNSSEC: {e}")
        return False

def main():
    print(f"🔍 Verifying Zone Settings for Zone ID: {ZONE_ID}")
    
    success = True
    
    success &= check_setting("ssl", "strict")
    success &= check_setting("always_use_https", "on")
    success &= check_setting("min_tls_version", "1.2")
    success &= check_setting("browser_check", "on")
    success &= check_setting("security_level", "medium")
    success &= check_dnssec()
    
    # Check SPF/DMARC existence (via DNS records API)
    # This is a bit more complex as we need to search records, 
    # but the settings above are the critical "Zone Settings" we just fixed permissions for.
    
    if success:
        print("\n🎉 All Zone Settings verified successfully!")
        sys.exit(0)
    else:
        print("\n⚠️ Some settings matched incorrectly or failed.")
        sys.exit(1)

if __name__ == "__main__":
    main()
