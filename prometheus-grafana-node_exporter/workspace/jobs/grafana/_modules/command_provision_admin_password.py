import os
import random
import string
import requests

def generate_password(length=12):
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for _ in range(length))


def kv_put(key, value):
    allocation_id = os.environ.get("ALLOCATION_ID")
    r = requests.put("http://localhost:8080/kv",
                     json={"namespace": "vars/job/grafana", "key": key, "value": value},
                     headers={"X-ALLOCATION-ID":allocation_id}, timeout=5)
    assert r.status_code == 200

def is_password_available():
    allocation_id = os.environ.get("ALLOCATION_ID")
    r = requests.get("http://localhost:8080/kv",
                     json={"namespace": "vars/job/grafana", "key": "grafana_admin_password"},
                     headers = {"X-ALLOCATION-ID":allocation_id}, timeout=5)
    return r.status_code == 200

def main():
    kv_put("grafana_admin_user", "admin")
    if not is_password_available():
        password = str(generate_password())
        kv_put("grafana_admin_password", password)

main()