import os
from datetime import timedelta
from dotenv import load_dotenv

# Load environment variables from .env file if present
load_dotenv()

class Config:
    """Base configuration for RLDS Church App Backend."""
    
    SECRET_KEY = os.getenv('SECRET_KEY', 'rlds-church-restoration-ministry-secret-key-delstarford-works-2026-prod-secure')
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'rlds-church-restoration-ministry-jwt-token-secret-key-delstarford-2026-secure-32bytes+')
    JWT_EXPIRATION_HOURS = int(os.getenv('JWT_EXPIRATION_HOURS', '72'))
    
    # Database Configuration
    # Supports Vercel Postgres / Neon / Supabase / Railway / SQLite
    raw_db_url = os.getenv('DATABASE_URL') or os.getenv('POSTGRES_URL')
    
    if raw_db_url:
        # SQLAlchemy 1.4+ requires postgresql:// instead of postgres://
        if raw_db_url.startswith('postgres://'):
            raw_db_url = raw_db_url.replace('postgres://', 'postgresql://', 1)
        SQLALCHEMY_DATABASE_URI = raw_db_url
    else:
        # Fallback to SQLite (in /tmp for Vercel serverless writable folder, or local)
        is_vercel = os.getenv('VERCEL', '0') == '1' or os.getenv('VERCEL_ENV') is not None
        if is_vercel:
            SQLALCHEMY_DATABASE_URI = 'sqlite:////tmp/rlds_church.db'
        else:
            base_dir = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))
            SQLALCHEMY_DATABASE_URI = f"sqlite:///{os.path.join(base_dir, 'rlds_church.db')}"
            
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # Mail Configuration (Flask-Mail / SMTP)
    MAIL_SERVER = os.getenv('MAIL_SERVER', 'smtp.gmail.com')
    MAIL_PORT = int(os.getenv('MAIL_PORT', '587'))
    MAIL_USE_TLS = os.getenv('MAIL_USE_TLS', 'true').lower() in ('true', '1', 't')
    MAIL_USE_SSL = os.getenv('MAIL_USE_SSL', 'false').lower() in ('true', '1', 't')
    MAIL_USERNAME = os.getenv('MAIL_USERNAME', '')
    MAIL_PASSWORD = os.getenv('MAIL_PASSWORD', '')
    MAIL_DEFAULT_SENDER = os.getenv('MAIL_DEFAULT_SENDER', 'notifications@rldschurch.org')
    
    # M-Pesa Daraja API Settings
    MPESA_ENV = os.getenv('MPESA_ENV', 'sandbox') # sandbox or production
    MPESA_CONSUMER_KEY = os.getenv('MPESA_CONSUMER_KEY', '')
    MPESA_CONSUMER_SECRET = os.getenv('MPESA_CONSUMER_SECRET', '')
    MPESA_SHORTCODE = os.getenv('MPESA_SHORTCODE', '174379') # Standard Daraja test shortcode
    MPESA_PASSKEY = os.getenv('MPESA_PASSKEY', 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919')
    MPESA_CALLBACK_URL = os.getenv('MPESA_CALLBACK_URL', 'https://your-domain.vercel.app/api/v1/tithes/mpesa/callback')
    ENABLE_MOCK_MPESA = os.getenv('ENABLE_MOCK_MPESA', 'true').lower() in ('true', '1', 't')
    
    # Church Administration
    CHURCH_NAME = "The Church of Jesus Christ Restoration Ministry"
    CHURCH_ACRONYM = "RLDS Church"
    DEVELOPED_BY = "Delstarford Works"
    ADMIN_EMAIL = os.getenv('ADMIN_EMAIL', 'admin@rldschurch.org')
