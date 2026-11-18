from functools import wraps
import jwt
from datetime import datetime, timedelta
from flask import request, jsonify, current_app
from app.models import User

def create_jwt_token(user: User) -> str:
    """Generate a JWT token for an authenticated user."""
    expiration_hours = current_app.config.get('JWT_EXPIRATION_HOURS', 72)
    payload = {
        'sub': str(user.id),
        'member_id': user.member_id,
        'email': user.email,
        'full_name': user.full_name,
        'role': user.role,
        'iat': datetime.utcnow(),
        'exp': datetime.utcnow() + timedelta(hours=expiration_hours)
    }
    return jwt.encode(payload, current_app.config['JWT_SECRET_KEY'], algorithm='HS256')


def decode_jwt_token(token: str):
    """Decode and validate a JWT token."""
    try:
        payload = jwt.decode(token, current_app.config['JWT_SECRET_KEY'], algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        return {'error': 'Token has expired. Please log in again.'}
    except jwt.InvalidTokenError:
        return {'error': 'Invalid token signature.'}


def token_required(f):
    """Decorator to require a valid Bearer JWT token."""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({
                'status': 'error',
                'message': 'Authorization header is missing.'
            }), 401

        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != 'bearer':
            return jsonify({
                'status': 'error',
                'message': 'Invalid token format. Expected: Bearer <token>'
            }), 401

        token = parts[1]
        decoded = decode_jwt_token(token)
        
        if 'error' in decoded:
            return jsonify({
                'status': 'error',
                'message': decoded['error']
            }), 401

        current_user = User.query.filter_by(member_id=decoded.get('member_id')).first()
        if not current_user or not current_user.is_active:
            return jsonify({
                'status': 'error',
                'message': 'User account not found or deactivated.'
            }), 401

        return f(current_user, *args, **kwargs)
    return decorated


def roles_required(*allowed_roles):
    """Decorator to restrict access to specific church roles."""
    def decorator(f):
        @wraps(f)
        def decorated_function(current_user: User, *args, **kwargs):
            # Super Admin always has access to all administrative actions
            if current_user.role != 'Super Admin' and current_user.role not in allowed_roles:
                return jsonify({
                    'status': 'error',
                    'message': f"Access forbidden. Requires one of the following roles: {', '.join(allowed_roles)}. Your role is '{current_user.role}'."
                }), 403
            return f(current_user, *args, **kwargs)
        return decorated_function
    return decorator
