from fastapi import FastAPI, HTTPException
import psycopg2
import os

app = FastAPI()

# Database connection parameters
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")


def get_postgres_version():
    """Function to get PostgreSQL version"""
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
        )
        with conn.cursor() as cursor:
            cursor.execute("SELECT version();")
            version = cursor.fetchone()[0]
        conn.close()
        return version
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection error: {str(e)}")


@app.get("/postgres-version")
def read_postgres_version():
    """API endpoint to get PostgreSQL version"""
    version = get_postgres_version()
    return {"postgres_version": version, "name": "app1"}
