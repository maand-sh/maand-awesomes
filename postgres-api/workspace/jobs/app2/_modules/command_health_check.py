import sys
import maand
import requests


def check_postgres_version():
    allocation_ip = maand.get_allocation_ip()
    url = f"http://{allocation_ip}:8000/postgres-version"
    try:
        response = requests.get(url, timeout=5)
        response.raise_for_status()  # Raise exception for HTTP errors
    except requests.RequestException as e:
        print(f"Error: {e}")
        sys.exit(1)


def main():
    check_postgres_version()


if __name__ == "__main__":
    main()
