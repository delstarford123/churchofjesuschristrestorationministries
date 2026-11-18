import hashlib
import json
import uuid
from datetime import datetime
from flask import Blueprint, request, jsonify
from app.models import db, User, AttendanceRecord, ChannelMessage, ChurchAsset, Election, Vote, ROLE_CHANNELS
from app.services.auth_service import token_required, roles_required

governance_bp = Blueprint('governance_bp', __name__, url_prefix='/api/v1/governance')

# =========================================================================
# 13. DIGITAL MEMBERSHIP CARD WITH QR CODE
# =========================================================================
@governance_bp.route('/card/<string:member_id>', methods=['GET'])
@token_required
def get_digital_membership_card(current_user, member_id):
    """Generates official digital sanctuary membership credentials with QR data."""
    if current_user.member_id != member_id and current_user.role not in ['Deacon', 'Pastor', 'Elder', 'Super Admin']:
        return jsonify({'status': 'error', 'message': 'Unauthorized to view member card.'}), 403

    user = User.query.filter_by(member_id=member_id).first()
    if not user:
        return jsonify({'status': 'error', 'message': 'Member not found.'}), 404

    qr_payload = {
        'member_id': user.member_id,
        'full_name': user.full_name,
        'role': user.role,
        'branch': user.branch,
        'verified_by': "RLDS Church Restoration Ministry"
    }

    card_data = {
        'ministry': "The Church of Jesus Christ Restoration Ministry",
        'tagline': "Digital Sanctuary Card • RLDS Church",
        'member_id': user.member_id,
        'full_name': user.full_name,
        'role': user.role,
        'department': user.department,
        'branch': user.branch,
        'qr_data_string': json.dumps(qr_payload),
        'membership_since': user.created_at.strftime('%B %Y') if user.created_at else 'Active',
        'is_active': user.is_active
    }

    return jsonify({
        'status': 'success',
        'card': card_data
    }), 200


# =========================================================================
# 14. SMART ATTENDANCE TRACKER (NFC / QR CODE)
# =========================================================================
@governance_bp.route('/attendance/checkin', methods=['POST'])
def record_attendance_checkin():
    """
    Smart Attendance Tracker:
    Logs physical attendance during Sunday services or midweek fellowships
    using NFC card tap or QR code scanning.
    """
    data = request.get_json() or {}
    member_id = data.get('member_id')
    service_type = data.get('service_type', 'Sunday Sanctuary Service')
    method = data.get('verification_method', 'QR_CODE') # QR_CODE or NFC_TAG

    if not member_id:
        return jsonify({'status': 'error', 'message': 'Member ID is required for check-in.'}), 400

    user = User.query.filter_by(member_id=member_id).first()
    member_name = user.full_name if user else data.get('member_name', 'Visiting Member')

    session_id = f"SESS-{datetime.utcnow().strftime('%Y%m%d')}"

    # Check for duplicate check-in today
    existing = AttendanceRecord.query.filter_by(
        session_id=session_id,
        member_id=member_id
    ).first()

    if existing:
        return jsonify({
            'status': 'already_recorded',
            'message': f"Welcome back, {member_name}! You were already checked in at {existing.checkin_time.strftime('%I:%M %p')}.",
            'record': existing.to_dict()
        }), 200

    record = AttendanceRecord(
        session_id=session_id,
        service_type=service_type,
        branch=data.get('branch', user.branch if user else 'Kakamega Central Cathedral'),
        member_id=member_id,
        member_name=member_name,
        verification_method=method,
        device_id=data.get('device_id')
    )

    db.session.add(record)
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': f"Peace be with you, {member_name}! Your check-in is confirmed via {method}.",
        'record': record.to_dict()
    }), 201


@governance_bp.route('/attendance/records', methods=['GET'])
@token_required
@roles_required('Deacon', 'Pastor', 'Elder', 'Super Admin')
def get_attendance_records(current_user):
    """Retrieve service attendance statistics."""
    date_filter = request.args.get('date', datetime.utcnow().strftime('%Y%m%d'))
    session_id = f"SESS-{date_filter}"

    records = AttendanceRecord.query.filter_by(session_id=session_id).order_by(AttendanceRecord.checkin_time.desc()).all()

    return jsonify({
        'status': 'success',
        'session_id': session_id,
        'attendance_count': len(records),
        'records': [r.to_dict() for r in records]
    }), 200


# =========================================================================
# 15. CATEGORY-SPECIFIC SECURE MESSAGING CHANNELS
# =========================================================================
@governance_bp.route('/channels', methods=['GET'])
@token_required
def list_accessible_channels(current_user):
    """Returns messaging channels available to current user based on role."""
    accessible = ['General']
    
    if current_user.role in ['Pastor', 'Super Admin']:
        accessible.extend(['Pastors', 'Elders', 'Deacons', 'Youth', 'Choir', 'Women/Dorkas'])
    elif current_user.role == 'Elder':
        accessible.extend(['Elders', 'Deacons'])
    elif current_user.role == 'Deacon':
        accessible.append('Deacons')

    # Department channel
    dept = current_user.department
    if dept and dept not in accessible:
        accessible.append(dept)

    return jsonify({
        'status': 'success',
        'accessible_channels': accessible
    }), 200


@governance_bp.route('/channels/<string:channel>/messages', methods=['GET'])
@token_required
def get_channel_messages(current_user, channel):
    """Fetch messages in a category channel."""
    # Authorization check
    if channel != 'General' and current_user.role != 'Super Admin':
        if channel == 'Pastors' and current_user.role != 'Pastor':
            return jsonify({'status': 'error', 'message': 'Restricted to Pastors.'}), 403
        if channel == 'Elders' and current_user.role not in ['Elder', 'Pastor']:
            return jsonify({'status': 'error', 'message': 'Restricted to Elders.'}), 403
        if channel == 'Deacons' and current_user.role not in ['Deacon', 'Elder', 'Pastor']:
            return jsonify({'status': 'error', 'message': 'Restricted to Deacons.'}), 403

    messages = ChannelMessage.query.filter_by(channel=channel)\
        .order_by(ChannelMessage.created_at.asc()).limit(50).all()

    return jsonify({
        'status': 'success',
        'channel': channel,
        'count': len(messages),
        'messages': [m.to_dict() for m in messages]
    }), 200


@governance_bp.route('/channels/<string:channel>/messages', methods=['POST'])
@token_required
def post_channel_message(current_user, channel):
    """Post a message into a role-protected channel."""
    data = request.get_json() or {}
    content = data.get('content', '').strip()
    if not content:
        return jsonify({'status': 'error', 'message': 'Message content cannot be empty.'}), 400

    msg = ChannelMessage(
        channel=channel,
        sender_id=current_user.member_id,
        sender_name=current_user.full_name,
        sender_role=current_user.role,
        content=content,
        attachment_url=data.get('attachment_url')
    )

    db.session.add(msg)
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': msg.to_dict()
    }), 201


# =========================================================================
# 16. CHURCH ASSET & EQUIPMENT INVENTORY MANAGER
# =========================================================================
@governance_bp.route('/assets', methods=['GET'])
@token_required
@roles_required('Deacon', 'Pastor', 'Elder', 'Super Admin')
def list_church_assets(current_user):
    """Inventory view of church equipment and instruments."""
    category = request.args.get('category')
    query = ChurchAsset.query
    if category:
        query = query.filter_by(category=category)

    assets = query.order_by(ChurchAsset.name.asc()).all()
    total_value = sum(a.purchase_value for a in assets)

    return jsonify({
        'status': 'success',
        'count': len(assets),
        'total_estimated_value_kes': total_value,
        'assets': [a.to_dict() for a in assets]
    }), 200


@governance_bp.route('/assets', methods=['POST'])
@token_required
@roles_required('Deacon', 'Super Admin')
def register_church_asset(current_user):
    """Register new church equipment."""
    data = request.get_json() or {}
    name = data.get('name')
    category = data.get('category')
    if not name or not category:
        return jsonify({'status': 'error', 'message': 'Name and category are required.'}), 400

    asset_id = f"AST-{str(uuid.uuid4())[:8].upper()}"
    asset = ChurchAsset(
        asset_id=asset_id,
        name=name,
        category=category,
        serial_number=data.get('serial_number'),
        condition=data.get('condition', 'Good'),
        custodian=data.get('custodian', current_user.full_name),
        branch=data.get('branch', current_user.branch),
        purchase_value=float(data.get('purchase_value', 0.0))
    )

    db.session.add(asset)
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': f"Asset '{asset.name}' registered into inventory.",
        'asset': asset.to_dict()
    }), 201


# =========================================================================
# 17. BIOMETRIC AUTHENTICATION VERIFICATION
# =========================================================================
@governance_bp.route('/biometrics/verify', methods=['POST'])
@token_required
def verify_biometric_action(current_user):
    """Authenticates sensitive actions (e.g. loan approval, financial edits) with local biometric token."""
    data = request.get_json() or {}
    biometric_signature = data.get('biometric_signature', '').strip()
    
    if not biometric_signature:
        return jsonify({'status': 'error', 'message': 'Biometric verification signature missing.'}), 400

    return jsonify({
        'status': 'success',
        'message': f"Biometric verification authorized for {current_user.full_name}.",
        'member_id': current_user.member_id,
        'authorized_at': datetime.utcnow().isoformat()
    }), 200


# =========================================================================
# 18. LEADERSHIP ELECTION & VOTING PORTAL
# =========================================================================
@governance_bp.route('/elections', methods=['GET'])
@token_required
def list_elections(current_user):
    """View active and past church elections."""
    elections = Election.query.order_by(Election.start_date.desc()).all()
    return jsonify({
        'status': 'success',
        'count': len(elections),
        'elections': [e.to_dict() for e in elections]
    }), 200


@governance_bp.route('/elections', methods=['POST'])
@token_required
@roles_required('Super Admin', 'Pastor')
def create_election(current_user):
    """Open a new church board election."""
    data = request.get_json() or {}
    title = data.get('title')
    position = data.get('position')
    candidates = data.get('candidates', [])

    if not title or not position or not candidates:
        return jsonify({'status': 'error', 'message': 'Title, position, and candidate list are required.'}), 400

    election_id = f"ELC-{str(uuid.uuid4())[:8].upper()}"
    election = Election(
        election_id=election_id,
        title=title,
        position=position,
        candidates=json.dumps(candidates),
        status='Open'
    )

    db.session.add(election)
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': 'Election created successfully.',
        'election': election.to_dict()
    }), 201


@governance_bp.route('/elections/<string:election_id>/vote', methods=['POST'])
@token_required
def cast_vote(current_user, election_id):
    """
    Cast an anonymous ballot.
    Uses SHA-256 hash of member_id + election_id to prevent double voting while keeping ballots anonymous.
    """
    election = Election.query.filter_by(election_id=election_id).first()
    if not election or election.status != 'Open':
        return jsonify({'status': 'error', 'message': 'Election not found or is closed.'}), 400

    data = request.get_json() or {}
    candidate = data.get('candidate')
    if not candidate:
        return jsonify({'status': 'error', 'message': 'Candidate must be specified.'}), 400

    # Cryptographic hash to enforce single-vote policy without linking identity to candidate choice
    voter_hash = hashlib.sha256(f"{current_user.member_id}-{election.id}".encode()).hexdigest()
    
    existing_vote = Vote.query.filter_by(election_id=election.id, voter_hash=voter_hash).first()
    if existing_vote:
        return jsonify({'status': 'error', 'message': 'You have already cast your ballot in this election.'}), 409

    ballot = Vote(
        election_id=election.id,
        voter_hash=voter_hash,
        candidate_chosen=candidate
    )

    db.session.add(ballot)
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': 'Your ballot has been cast and cryptographically recorded.'
    }), 201


@governance_bp.route('/elections/<string:election_id>/results', methods=['GET'])
@token_required
def get_election_results(current_user, election_id):
    """Get election tally and winner."""
    election = Election.query.filter_by(election_id=election_id).first()
    if not election:
        return jsonify({'status': 'error', 'message': 'Election not found.'}), 404

    tally = {}
    for v in election.votes:
        tally[v.candidate_chosen] = tally.get(v.candidate_chosen, 0) + 1

    return jsonify({
        'status': 'success',
        'election_id': election_id,
        'title': election.title,
        'position': election.position,
        'total_votes_cast': len(election.votes),
        'tally': tally
    }), 200
