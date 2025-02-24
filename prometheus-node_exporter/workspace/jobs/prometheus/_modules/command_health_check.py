import os
import sys

import requests

allocation_ip = os.environ.get("ALLOCATION_IP")

try:
    r = requests.get(f"http://{allocation_ip}:9100/metrics")
    r.raise_for_status()
except Exception as e:
    sys.stderr.write(str(e))
    sys.exit(1)