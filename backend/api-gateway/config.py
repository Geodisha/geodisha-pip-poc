"""
Configuration settings for GeoDisha API Gateway
"""

from pydantic_settings import BaseSettings
from typing import List
import os


class Settings(BaseSettings):
    """Application settings"""
    
    # Environment
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    PROJECT_ID: str = os.getenv("GCP_PROJECT_ID", "")
    REGION: str = os.getenv("GCP_REGION", "asia-south1")
    
    # API
    API_VERSION: str = "v1"
    API_PREFIX: str = "/api/v1"
    
    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:3001",  # Flutter web
        "http://localhost:8080",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:3001",
        "https://geodisha.com",
        "https://app.geodisha.com",
        "*"  # Allow all origins for development
    ]
    
    # Database
    DB_HOST: str = os.getenv("DB_HOST", "localhost")
    DB_PORT: int = int(os.getenv("DB_PORT", "5432"))
    DB_NAME: str = os.getenv("DB_NAME", "geodisha")
    DB_USER: str = os.getenv("DB_USER", "geodisha_app")
    DB_PASSWORD: str = os.getenv("DB_PASSWORD", "")
    DB_POOL_SIZE: int = 20
    DB_MAX_OVERFLOW: int = 10
    
    @property
    def DATABASE_URL(self) -> str:
        """Construct database URL"""
        return f"postgresql+asyncpg://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
    
    # Cloud SQL (for production)
    CLOUD_SQL_CONNECTION_NAME: str = os.getenv("CLOUD_SQL_CONNECTION_NAME", "")
    
    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = os.getenv("FIREBASE_CREDENTIALS_PATH", "")
    
    # Storage
    MEDIA_BUCKET: str = os.getenv("MEDIA_BUCKET", "")
    ML_MODELS_BUCKET: str = os.getenv("ML_MODELS_BUCKET", "")
    
    # Pub/Sub Topics
    GRIEVANCE_TOPIC: str = "grievance-events"
    VISIT_TOPIC: str = "visit-events"
    ANALYTICS_TOPIC: str = "analytics-events"
    
    # JWT
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # Security
    BCRYPT_ROUNDS: int = 12
    
    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 60
    
    # Logging
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    
    # BigQuery
    BIGQUERY_DATASET: str = "geo_pulse_data"  # Updated to use main dataset
    BIGQUERY_PROJECT_ID: str = os.getenv("BIGQUERY_PROJECT_ID", os.getenv("GCP_PROJECT_ID", "geo-pulse-463507"))
    
    # Vertex AI
    VERTEX_AI_LOCATION: str = os.getenv("VERTEX_AI_LOCATION", "asia-south1")
    
    # Redis (for caching - optional)
    REDIS_HOST: str = os.getenv("REDIS_HOST", "")
    REDIS_PORT: int = int(os.getenv("REDIS_PORT", "6379"))
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "allow"  # Allow extra fields from env file


settings = Settings()
