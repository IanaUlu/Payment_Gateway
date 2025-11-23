"""Configuration module for BePay Payment Gateway."""
import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Base configuration class."""
    
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    API_KEY = os.getenv('API_KEY', 'dev-api-key-change-in-production')
    
    # Database configuration
    DATABASE_PATH = os.getenv('DATABASE_PATH', 'transactions.db')
    
    # Payment gateway settings
    SUPPORTED_CURRENCIES = ['USD', 'EUR', 'GBP', 'JPY']
    MAX_TRANSACTION_AMOUNT = 1000000
    MIN_TRANSACTION_AMOUNT = 0.01
    
    # Security settings
    REQUIRE_API_KEY = os.getenv('REQUIRE_API_KEY', 'True').lower() == 'true'
    
    # Server settings
    HOST = os.getenv('HOST', '0.0.0.0')
    PORT = int(os.getenv('PORT', 5000))
    DEBUG = os.getenv('DEBUG', 'False').lower() == 'true'
