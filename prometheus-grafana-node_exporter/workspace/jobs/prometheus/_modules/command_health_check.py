import os
import sys

import requests

allocation_ip = os.environ.get("ALLOCATION_IP")
allocation_id = os.environ.get("ALLOCATION_ID")

def kv_get(namespace, key):
    r = requests.get("http://localhost:8080/kv", json={"namespace": namespace, "key": key}, headers={"X-ALLOCATION-ID":allocation_id}, timeout=5)
    assert r.status_code == 200
    return r.json()["value"]

try:
    user = kv_get("vars/job/prometheus", "prometheus_admin_user")
    password = kv_get("vars/job/prometheus", "prometheus_admin_password")
    r = requests.get(f"http://{allocation_ip}:9091/metrics", auth=(user, password), timeout=5)
    r.raise_for_status()
except Exception as e:
    sys.stderr.write(str(e) +"\n")
    sys.exit(1)