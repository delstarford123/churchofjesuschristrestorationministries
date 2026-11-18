from flask import Blueprint, jsonify, current_app
from datetime import datetime
from app.models import db, User, TitheTransaction, LoanApplication

health_bp = Blueprint('health_bp', __name__)

@health_bp.route('/', methods=['GET'])
def api_root():
    """Root landing endpoint with system metadata and endpoint overview."""
    return jsonify({
        'organization': current_app.config.get('CHURCH_NAME'),
        'acronym': current_app.config.get('CHURCH_ACRONYM'),
        'developer': current_app.config.get('DEVELOPED_BY'),
        'system': 'Offline-First Church Management & Stewardship Kitty API',
        'status': 'online',
        'version': '1.0.0',
        'timestamp': datetime.utcnow().isoformat(),
        'endpoints': {
            'health': '/health',
            'auth': {
                'register': 'POST /api/v1/auth/register',
                'login': 'POST /api/v1/auth/login',
                'me': 'GET /api/v1/auth/me',
                'role_update': 'PUT /api/v1/auth/role (Super Admin)',
                'members': 'GET /api/v1/auth/members'
            },
            'tithes': {
                'offline_sync': 'POST /api/v1/tithes/sync (Flutter Batch Sync)',
                'submit': 'POST /api/v1/tithes/submit',
                'history': 'GET /api/v1/tithes/history',
                'stk_push': 'POST /api/v1/tithes/mpesa/stkpush',
                'mpesa_callback': 'POST /api/v1/tithes/mpesa/callback'
            },
            'stewardship_loans': {
                'apply': 'POST /api/v1/loans/apply (Offline-First)',
                'pending': 'GET /api/v1/loans/pending (Executive Directors)',
                'my_loans': 'GET /api/v1/loans/my-loans',
                'review': 'PUT /api/v1/loans/<loan_id>/review (Executive Directors)',
                'repay': 'POST /api/v1/loans/<loan_id>/repay'
            },
            'announcements': {
                'list': 'GET /api/v1/announcements?category=<category>',
                'create': 'POST /api/v1/announcements'
            },
            'support_bot': {
                'chat': 'POST /api/v1/chat/message'
            }
        }
    }), 200


@health_bp.route('/health', methods=['GET'])
def health_check():
    """System health check and diagnostic ping."""
    db_status = 'connected'
    try:
        # Simple test query
        db.session.execute(db.text('SELECT 1'))
    except Exception as e:
        db_status = f'error: {str(e)}'

    return jsonify({
        'status': 'healthy' if db_status == 'connected' else 'degraded',
        'database': db_status,
        'church': current_app.config.get('CHURCH_NAME'),
        'developer': current_app.config.get('DEVELOPED_BY'),
        'timestamp': datetime.utcnow().isoformat()
    }), 200
