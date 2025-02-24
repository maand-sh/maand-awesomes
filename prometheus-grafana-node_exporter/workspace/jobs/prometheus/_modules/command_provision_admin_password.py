import os
import random
import string
import bcrypt
import requests

def generate_password(length=12):
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for _ in range(length))


def kv_put(key, value):
    allocation_id = os.environ.get("ALLOCATION_ID")
    r = requests.put("http://localhost:8080/kv",
                     json={"namespace": "vars/job/prometheus", "key": key, "value": value},
                     headers={"X-ALLOCATION-ID":allocation_id}, timeout=5)
    assert r.status_code == 200

def is_password_available():
    allocation_id = os.environ.get("ALLOCATION_ID")
    r = requests.get("http://localhost:8080/kv",
                     json={"namespace": "vars/job/prometheus", "key": "prometheus_admin_password"},
                     headers = {"X-ALLOCATION-ID":allocation_id}, timeout=5)
    return r.status_code == 200

def main():
    kv_put("prometheus_admin_user", "admin")
    if not is_password_available():
        password = str(generate_password())
        hashed_password = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
        kv_put("prometheus_admin_password", password)
        kv_put("prometheus_admin_password_hash", hashed_password)

main()