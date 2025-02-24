import os
import sys

import requests

allocation_ip = os.environ.get("ALLOCATION_IP")
allocation_id = os.environ.get("ALLOCATION_ID")

def kv_get(namespace, key):
    r = requests.get("http://localhost:8080/kv", json={"namespace": namespace, "key": key}, headers={"X-ALLOCATION-ID":allocation_id}, timeout=5)
    if r.status_code == 200:
        return r.json()["value"]
    else:
        return ""

def kv_put(key, value):
    r = requests.put("http://localhost:8080/kv",
                     json={"namespace": "vars/job/grafana", "key": key, "value": value},
                     headers={"X-ALLOCATION-ID":allocation_id}, timeout=5)
    assert r.status_code == 200

try:
    prometheus_user = kv_get("vars/job/prometheus", "grafana_user")
    prometheus_password = kv_get("vars/job/prometheus", "grafana_password")
    kv_put("prometheus_user", prometheus_user)
    kv_put("prometheus_password", prometheus_password)
except Exception as e:
    print(e)
    sys.exit(1)