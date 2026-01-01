#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cloudflare Zone Settings 検証スクリプト
------------------------------------------------------------------------------
ゾーンのセキュリティ設定（SSL, HTTPS強制, TLS, DNSSEC等）が
想定通りに適用されているかを Cloudflare API 経由で確認します。

Usage:
    python3 scripts/verify-zone-settings.py

Requirements:
    - requests (pip install requests)
    - .env に CLOUDFLARE_API_TOKEN と CLOUDFLARE_ZONE_ID (or TF_VAR_CLOUDFLARE_ZONE_ID)
"""

import os
import sys
from typing import Any

try:
    import requests
except ImportError:
    print("❌ Error: 'requests' module not found. Run: pip install requests")
    sys.exit(1)


# -----------------------------------------------------------------------------
# .env ファイルの手動読み込み (外部依存を最小化)
# -----------------------------------------------------------------------------
def load_env_file(filepath: str) -> dict[str, str]:
    """
    .env ファイルをパースして環境変数の辞書を返す。
    python-dotenv を使わないことで依存を減らす。
    """
    env_vars: dict[str, str] = {}
    if not os.path.exists(filepath):
        return env_vars
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, value = line.split("=", 1)
                # 引用符を除去
                value = value.strip().strip('"').strip("'")
                env_vars[key.strip()] = value
    return env_vars


# 設定読み込み
ENV_PATH = os.path.join(os.path.dirname(__file__), "../.env")
ENV_VARS = load_env_file(ENV_PATH)

ZONE_ID = (
    ENV_VARS.get("CLOUDFLARE_ZONE_ID")
    or ENV_VARS.get("TF_VAR_CLOUDFLARE_ZONE_ID")
    or os.getenv("CLOUDFLARE_ZONE_ID")
)
API_TOKEN = ENV_VARS.get("CLOUDFLARE_API_TOKEN") or os.getenv("CLOUDFLARE_API_TOKEN")

if not ZONE_ID or not API_TOKEN:
    print("❌ Error: CLOUDFLARE_ZONE_ID or CLOUDFLARE_API_TOKEN not found in .env")
    sys.exit(1)

HEADERS = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json",
}


# -----------------------------------------------------------------------------
# 検証関数
# -----------------------------------------------------------------------------
def check_setting(setting_id: str, expected_value: str, value_key: str = "value") -> bool:
    """
    指定されたゾーン設定が期待値と一致するか確認する。
    """
    url = f"https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/settings/{setting_id}"
    try:
        response = requests.get(url, headers=HEADERS, timeout=30)
        response.raise_for_status()
        data: dict[str, Any] = response.json()

        if not data.get("success"):
            print(f"❌ Error fetching {setting_id}: {data.get('errors')}")
            return False

        current_value = data["result"][value_key]
        if current_value == expected_value:
            print(f"✅ {setting_id}: {current_value}")
            return True
        else:
            print(f"❌ {setting_id}: Expected {expected_value}, got {current_value}")
            return False

    except requests.exceptions.RequestException as e:
        print(f"❌ Network error checking {setting_id}: {e}")
        return False
    except (KeyError, TypeError) as e:
        print(f"❌ Parse error checking {setting_id}: {e}")
        return False


def check_dnssec() -> bool:
    """
    DNSSEC ステータスが 'active' かどうか確認する。
    Note: 'pending' はレジストラへの DS レコード登録待ち状態。
    """
    url = f"https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/dnssec"
    try:
        response = requests.get(url, headers=HEADERS, timeout=30)
        response.raise_for_status()
        data: dict[str, Any] = response.json()

        if not data.get("success"):
            print(f"❌ Error fetching DNSSEC: {data.get('errors')}")
            return False

        status = data["result"]["status"]
        if status == "active":
            print("✅ DNSSEC: active")
            return True
        elif status == "pending":
            print(f"⚠️ DNSSEC: pending (DS レコードをレジストラに登録してください)")
            return True  # pending は有効化済みだが DS 未登録
        else:
            print(f"❌ DNSSEC: Expected active, got {status}")
            return False

    except requests.exceptions.RequestException as e:
        print(f"❌ Network error checking DNSSEC: {e}")
        return False
    except (KeyError, TypeError) as e:
        print(f"❌ Parse error checking DNSSEC: {e}")
        return False


def main() -> None:
    """メイン処理: 全ゾーン設定を検証して結果を出力する。"""
    print(f"🔍 Verifying Zone Settings for Zone ID: {ZONE_ID}")
    print("-" * 60)

    results: list[bool] = []

    # セキュリティ設定の検証
    results.append(check_setting("ssl", "strict"))
    results.append(check_setting("always_use_https", "on"))
    results.append(check_setting("min_tls_version", "1.2"))
    results.append(check_setting("browser_check", "on"))
    results.append(check_setting("security_level", "medium"))
    results.append(check_dnssec())

    print("-" * 60)

    if all(results):
        print("🎉 All Zone Settings verified successfully!")
        sys.exit(0)
    else:
        print("⚠️ Some settings did not match expected values.")
        sys.exit(1)


if __name__ == "__main__":
    main()
