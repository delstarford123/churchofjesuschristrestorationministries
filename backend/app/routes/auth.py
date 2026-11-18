import random
from flask import Blueprint, request, jsonify
from app.models import db, User, VALID_ROLES
from app.services.auth_service import create_jwt_token, token_required, roles_required

auth_bp = Blueprint('auth_bp', __name__, url_prefix='/api/v1/auth')

@auth_bp.route('/register', methods=['POST'])
def register():
    """Register a new church member."""
    data = request.get_json() or {}
    
    required = ['full_name', 'email', 'phone_number', 'password']
    missing = [f for f in required if not data.get(f)]
    if missing:
        return jsonify({
            'status': 'error',
            'message': f"Missing required fields: {', '.join(missing)}"
        }), 400

    email = data['email'].strip().lower()
    if User.query.filter_by(email=email).first():
        return jsonify({'status': 'error', 'message': 'A member with this email already exists.'}), 409

    # Generate or validate member_id
    member_id = data.get('member_id')
    if not member_id:
        member_id = f"RLDS-{random.randint(10000, 99999)}"
    elif User.query.filter_by(member_id=member_id).first():
        return jsonify({'status': 'error', 'message': 'Member ID already registered.'}), 409

    requested_role = data.get('role', 'Normal Member')
    if requested_role not in VALID_ROLES:
        requested_role = 'Normal Member'

    new_user = User(
        member_id=member_id,
        full_name=data['full_name'].strip(),
        email=email,
        phone_number=data['phone_number'].strip(),
        role=requested_role,
        department=data.get('department', 'General Congregation')
    )
    new_user.set_password(data['password'])

    db.session.add(new_user)
    db.session.commit()

    token = create_jwt_token(new_user)

    return jsonify({
        'status': 'success',
        'message': 'Member registered successfully.',
        'token': token,
        'user': new_user.to_dict()
    }), 201


@auth_bp.route('/login', methods=['POST'])
def login():
    """Authenticate member and return JWT bearer token."""
    data = request.get_json() or {}
    identifier = data.get('email') or data.get('member_id')
    password = data.get('password')

    if not identifier or not password:
        return jsonify({'status': 'error', 'message': 'Identifier (email or member_id) and password are required.'}), 400

    identifier = identifier.strip()
    user = User.query.filter(
        (User.email == identifier.lower()) | (User.member_id == identifier)
    ).first()

    if not user or not user.check_password(password):
        return jsonify({'status': 'error', 'message': 'Invalid credentials. Please verify your email/ID and password.'}), 401

    if not user.is_active:
        return jsonify({'status': 'error', 'message': 'Your account has been deactivated. Please contact church leadership.'}), 403

    token = create_jwt_token(user)

    return jsonify({
        'status': 'success',
        'message': 'Login successful.',
        'token': token,
        'user': user.to_dict()
    }), 200


@auth_bp.route('/me', methods=['GET'])
@token_required
def get_current_profile(current_user):
    """Retrieve profile of currently authenticated church member."""
    return jsonify({
        'status': 'success',
        'user': current_user.to_dict()
    }), 200


@auth_bp.route('/role', methods=['PUT'])
@token_required
@roles_required('Super Admin')
def update_user_role(current_user):
    """Assign or change church roles (Super Admin only)."""
    data = request.get_json() or {}
    target_member_id = data.get('member_id')
    new_role = data.get('role')

    if not target_member_id or not new_role:
        return jsonify({'status': 'error', 'message': 'Target member_id and new role are required.'}), 400

    if new_role not in VALID_ROLES:
        return jsonify({'status': 'error', 'message': f"Invalid role. Must be one of: {', '.join(VALID_ROLES)}"}), 400

    target_user = User.query.filter_by(member_id=target_member_id).first()
    if not target_user:
        return jsonify({'status': 'error', 'message': 'Target church member not found.'}), 404

    target_user.role = new_role
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': f"Updated {target_user.full_name}'s role to '{new_role}'.",
        'user': target_user.to_dict()
    }), 200


@auth_bp.route('/members', methods=['GET'])
@token_required
def list_members(current_user):
    """List church members directory."""
    role_filter = request.args.get('role')
    query = User.query.filter_by(is_active=True)
    if role_filter:
        query = query.filter_by(role=role_filter)

    members = query.order_by(User.full_name.asc()).limit(100).all()
    return jsonify({
        'status': 'success',
        'count': len(members),
        'members': [m.to_dict() for m in members]
    }), 200
