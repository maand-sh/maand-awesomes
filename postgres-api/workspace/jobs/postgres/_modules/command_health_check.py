import os
import sys
import psycopg2
from psycopg2 import OperationalError

import maand

def connect_to_db(host):
    """Establish a connection to the PostgreSQL database."""
    try:
        return psycopg2.connect(
            database="postgres",
            host=host,
            user="postgres",
            password="postgres",
            port=5432
        )
    except OperationalError as e:
        print(f"Database connection failed: {e}")
        sys.exit(1)

def main():
    """Main function to check PostgreSQL version."""
    host = maand.get_allocation_ip()

    # Using context manager for automatic connection closure
    with connect_to_db(host) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT version();")
            version = cur.fetchone()
            if version and version[0]:
                print(f"PostgreSQL version: {version[0]}")
            else:
                print("Error: Unable to fetch PostgreSQL version.")
                sys.exit(1)

if __name__ == "__main__":
    main()
