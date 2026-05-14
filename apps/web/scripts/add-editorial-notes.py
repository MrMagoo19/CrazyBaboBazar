#!/usr/bin/env python3
# Key must be set via environment variable: SUPABASE_SERVICE_ROLE_KEY
import requests, time, os

SUPABASE_URL = "https://ydiihvzcxaaoqhmgoqvu.supabase.co"
SERVICE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
HEADERS = {"apikey": SERVICE_KEY, "Authorization": f"Bearer {SERVICE_KEY}", "Content-Type": "application/json", "Prefer": "return=minimal"}
print("Script has already been run. See git history for notes content.")
