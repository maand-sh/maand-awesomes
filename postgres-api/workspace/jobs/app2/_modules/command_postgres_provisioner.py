import sys
import maand


def main():
    job = maand.get_job()
    try:
        r = maand.kv_get("vars/job/postgres", f"{job}/user")
        r.raise_for_status()
        user = r.json()["value"]

        r = maand.kv_get("vars/job/postgres", f"{job}/password")
        r.raise_for_status()
        password = r.json()["value"]

        r = maand.kv_get("vars/job/postgres", f"{job}/database")
        r.raise_for_status()
        database = r.json()["value"]

        maand.kv_put("postgres_user", user)
        maand.kv_put("postgres_password", password)
        maand.kv_put("postgres_database", database)
    except Exception as e:
        print(e)
        sys.exit(1)


if __name__ == "__main__":
    main()
