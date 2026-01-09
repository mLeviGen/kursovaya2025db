import os
from dotenv import load_dotenv

load_dotenv()

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_USER = os.getenv("DB_USER", "cheese_guest")
DB_PASSWORD = os.getenv("DB_PASSWORD", "guest_pass")
DB_NAME = os.getenv("DB_NAME", "cheese_db")

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "change_me")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_TOKEN_LIFETIME = int(os.getenv("JWT_TOKEN_LIFETIME", "30"))  # minutes
