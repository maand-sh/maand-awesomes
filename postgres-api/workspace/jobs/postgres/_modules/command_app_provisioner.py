import os
import random
import string
import maand
import psycopg2
from psycopg2 import sql
from psycopg2 import OperationalError, Error


def generate_password(length=12):
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for _ in range(length))


def create_database_and_user(db_name, db_user, db_password):
    try:
        conn = psycopg2.connect(
            host=maand.get_allocation_ip(),
            port=os.getenv("DB_PORT", "5432"),
            database=os.getenv("ADMIN_DB_NAME", "postgres"),
            user=os.getenv("ADMIN_DB_USER", "postgres"),
            password=os.getenv("ADMIN_DB_PASSWORD", "postgres")
        )
        conn.autocommit = True

        with conn.cursor() as cursor:
            cursor.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(db_name)))
            print(f"Database '{db_name}' created successfully.")

            cursor.execute(sql.SQL("CREATE USER {} WITH PASSWORD %s").format(sql.Identifier(db_user)), [db_password])
            print(f"User '{db_user}' created successfully.")

            cursor.execute(
                sql.SQL("GRANT ALL PRIVILEGES ON DATABASE {} TO {}")
                .format(sql.Identifier(db_name), sql.Identifier(db_user))
            )
            print(f"Privileges granted to user '{db_user}' on database '{db_name}'.")

    except OperationalError as e:
        print(f"Database connection failed: {e}")
    except Error as e:
        print(f"Database operation error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()


def main():
    job = maand.get_job()

    r = maand.demands()
    assert r.status_code == 200

    demands = r.json()
    for demand in demands:

        requester_job = demand.get("job")
        r = maand.kv_get(f"vars/job/{job}", f"{requester_job}/user")

        if r.status_code == 404:
            user = f"{requester_job}_user"
            password = generate_password()
            database = f"{requester_job}_database"

            create_database_and_user(database, user, password)

            maand.kv_put(f"{requester_job}/user", user)
            maand.kv_put(f"{requester_job}/password", password)
            maand.kv_put(f"{requester_job}/database", database)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Error: {e}")
