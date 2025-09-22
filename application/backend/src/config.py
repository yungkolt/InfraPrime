import os
from urllib.parse import quote_plus

class Config:
    """Application configuration class"""
    
    # Basic Flask config
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    ENVIRONMENT = os.environ.get('ENVIRONMENT', 'development')
    VERSION = os.environ.get('APP_VERSION', '1.0.0')
    
    # Database configuration
    DB_HOST = os.environ.get('DATABASE_HOST', 'localhost')
    DB_PORT = os.environ.get('DATABASE_PORT', '5432')
    DB_NAME = os.environ.get('DATABASE_NAME', 'threetierapp')
    DB_USER = os.environ.get('DATABASE_USER', 'postgres')
    DB_PASSWORD = os.environ.get('DATABASE_PASSWORD', 'password123')
    
    # URL encode password for special characters
    encoded_password = quote_plus(DB_PASSWORD)
    
    # SQLAlchemy configuration
    SQLALCHEMY_DATABASE_URI = f'postgresql://{DB_USER}:{encoded_password}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_size': 10,
        'pool_recycle': 120,
        'pool_pre_ping': True,
        'connect_args': {
            'connect_timeout': 30,
            'application_name': 'three-tier-backend'
        }
    }
    
    # CORS settings
    ALLOWED_ORIGINS = os.environ.get('ALLOWED_ORIGINS', '*')
    
    # Logging configuration
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
