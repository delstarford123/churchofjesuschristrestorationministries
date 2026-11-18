import random
import uuid
from datetime import datetime
from flask import Blueprint, request, jsonify
from app.models import (
    db, User, SundaySchoolLesson, ChildPickupCode,
    NewBelieverMilestone, CommunityProject, VolunteerRoster,
    VolunteerSignup, CounselingMessage
)
from app.services.auth_service import token_required, roles_required

community_bp = Blueprint('community_bp', __name__, url_prefix='/api/v1/community')

# =========================================================================
# 19. SUNDAY SCHOOL & CHILDREN'S MINISTRY PORTAL
# =========================================================================
@community_bp.route('/sundayschool/lessons', methods=['GET'])
def get_sunday_school_lessons():
    """Retrieve weekly Sunday School lesson outlines, memory verses, and homework."""
    lessons = SundaySchoolLesson.query.order_by(SundaySchoolLesson.week_number.desc()).limit(10).all()
    return jsonify({
        'status': 'success',
        'count': len(lessons),
        'lessons': [l.to_dict() for l in lessons]
    }), 200


@community_bp.route('/sundayschool/pickup/generate', methods=['POST'])
@token_required
def generate_child_pickup_code(current_user):
    """Generates a secure 4-digit parent verification code for child collection."""
    data = request.get_json() or {}
    child_name = data.get('child_name')
    if not child_name:
        return jsonify({'status': 'error', 'message': 'Child name is required.'}), 400

    code = f"{random.randint(1000, 9999)}"
    pickup = ChildPickupCode(
        code=code,
        child_name=child_name,
        parent_member_id=current_user.member_id,
        parent_phone=current_user.phone_number
    )
    db.session.add(pickup)
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': f"Pickup verification code generated for {child_name}.",
        'pickup_code': code,
        'parent_phone': current_user.phone_number
    }), 201


@community_bp.route('/sundayschool/pickup/verify', methods=['POST'])
@token_required
@roles_required('Deacon', 'Pastor', 'Super Admin')
def verify_child_pickup(current_user):
    """Teachers/Deacons verify the 4-digit code before releasing a child."""
    data = request.get_json() or {}
    code = data.get('code')
    pickup = ChildPickupCode.query.filter_by(code=code, status='Active').first()
    if not pickup:
        return jsonify({'status': 'error', 'message': 'Invalid or expired pickup code.'}), 404

    pickup.status = 'Verified/Picked'
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': f"Pickup authorized for child '{pickup.child_name}'. Parent: {pickup.parent_phone}."
    }), 200


# =========================================================================
# 20. FOUNDATIONS / NEW BELIEVERS CLASS TRACKER
# =========================================================================
@community_bp.route('/classes/milestones', methods=['GET'])
@token_required
def get_new_believer_milestones(current_user):
    """Track milestones for baptism and discipleship classes."""
    query = NewBelieverMilestone.query
    if current_user.role not in ['Pastor', 'Elder', 'Super Admin']:
        query = query.filter_by(member_id=current_user.member_id)

    milestones = query.all()
    return jsonify({
        'status': 'success',
        'count': len(milestones),
        'milestones': [m.to_dict() for m in milestones]
    }), 200


@community_bp.route('/classes/milestones/<string:member_id>', methods=['PUT'])
@token_required
@roles_required('Pastor', 'Elder', 'Super Admin')
def update_milestone(current_user, member_id):
    """Pastors update a believer's baptism or discipleship graduation."""
    data = request.get_json() or {}
    milestone = NewBelieverMilestone.query.filter_by(member_id=member_id).first()
    if not milestone:
        user = User.query.filter_by(member_id=member_id).first()
        milestone = NewBelieverMilestone(
            member_id=member_id,
            member_name=user.full_name if user else 'New Believer'
        )
        db.session.add(milestone)

    if 'orientation_completed' in data:
        milestone.orientation_completed = bool(data['orientation_completed'])
    if 'discipleship_stage' in data:
        milestone.discipleship_stage = data['discipleship_stage']
    if 'baptism_date' in data:
        milestone.baptism_date = datetime.utcnow()
        milestone.certificate_id = f"RLDS-CERT-BAP-{member_id}"

    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': f"Updated milestone for {milestone.member_name}.",
        'milestone': milestone.to_dict()
    }), 200


# =========================================================================
# 21. COMMUNITY OUTREACH & CBO PROJECT TRACKER (FARD CBO)
# =========================================================================
@community_bp.route('/outreach/projects', methods=['GET'])
def list_community_projects():
    """Transparency dashboard linking church members to community initiatives (FARD CBO)."""
    projects = CommunityProject.query.order_by(CommunityProject.created_at.desc()).all()
    return jsonify({
        'status': 'success',
        'count': len(projects),
        'projects': [p.to_dict() for p in projects]
    }), 200


@community_bp.route('/outreach/projects', methods=['POST'])
@token_required
@roles_required('Executive Director', 'Pastor', 'Super Admin')
def create_community_project(current_user):
    """Launch a new community development or feeding project."""
    data = request.get_json() or {}
    name = data.get('name')
    target_budget = data.get('target_budget')
    if not name or not target_budget:
        return jsonify({'status': 'error', 'message': 'Name and target budget are required.'}), 400

    project = CommunityProject(
        project_id=f"PRJ-{str(uuid.uuid4())[:8].upper()}",
        name=name,
        description=data.get('description', 'Community support program.'),
        target_budget=float(target_budget),
        raised_budget=float(data.get('raised_budget', 0.0)),
        cbo_partner=data.get('cbo_partner', 'FARD Community Based Organization'),
        beneficiaries_reached=int(data.get('beneficiaries', 0))
    )

    db.session.add(project)
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': 'Community project launched.',
        'project': project.to_dict()
    }), 201


# =========================================================================
# 22. VOLUNTEER & MINISTRY SERVICE SIGNUP
# =========================================================================
@community_bp.route('/volunteers/roster', methods=['GET'])
def get_volunteer_rosters():
    """View active ministry service opportunities (ushering, clean-up, cooking)."""
    rosters = VolunteerRoster.query.order_by(VolunteerRoster.event_date.asc()).all()
    return jsonify({
        'status': 'success',
        'count': len(rosters),
        'rosters': [r.to_dict() for r in rosters]
    }), 200


@community_bp.route('/volunteers/signup', methods=['POST'])
@token_required
def signup_as_volunteer(current_user):
    """Sign up for an active volunteer slot."""
    data = request.get_json() or {}
    roster_id = data.get('roster_id')
    roster = VolunteerRoster.query.get(roster_id)
    if not roster:
        return jsonify({'status': 'error', 'message': 'Service roster slot not found.'}), 404

    # Check for existing signup
    existing = VolunteerSignup.query.filter_by(roster_id=roster.id, member_id=current_user.member_id).first()
    if existing:
        return jsonify({'status': 'error', 'message': 'You are already registered on this service roster.'}), 409

    signup = VolunteerSignup(
        roster_id=roster.id,
        member_id=current_user.member_id,
        member_name=current_user.full_name,
        phone=current_user.phone_number
    )
    db.session.add(signup)
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': f"Blessings, {current_user.full_name}! You are registered for '{roster.service_role}' at '{roster.event_name}'."
    }), 201


# =========================================================================
# 23. VIRTUAL COMMUNION & HOME FELLOWSHIP GUIDE
# =========================================================================
@community_bp.route('/liturgy/communion', methods=['GET'])
def get_communion_guide():
    """Liturgy, readings, and guide for home-bound members participating remotely."""
    return jsonify({
        'status': 'success',
        'liturgy': {
            'title': "RLDS Church Sacred Order of The Lord's Supper",
            'scripture_reading': "1 Corinthians 11:23-26",
            'bread_blessing': (
                "O God, the Eternal Father, we ask Thee in the name of Thy Son, Jesus Christ, "
                "to bless and sanctify this bread to the souls of all those who partake of it, "
                "that they may eat in remembrance of the body of Thy Son, and witness unto Thee, "
                "O God, the Eternal Father, that they are willing to take upon them the name of Thy Son..."
            ),
            'wine_water_blessing': (
                "O God, the Eternal Father, we ask Thee in the name of Thy Son, Jesus Christ, "
                "to bless and sanctify this wine/cup to the souls of all those who drink of it, "
                "that they may do it in remembrance of the blood of Thy Son, which was shed for them..."
            ),
            'fellowship_hymns': ["The Spirit of God Like a Fire Is Burning", "I Stand Amazed in the Presence"],
            'guidelines': "Prepare unleavened bread or plain crackers and pure fruit juice or water in prayerful reverence."
        }
    }), 200


# =========================================================================
# 24. ANONYMOUS COUNSELING & PASTORAL FEEDBACK BOX
# =========================================================================
@community_bp.route('/counseling/submit', methods=['POST'])
def submit_counseling_request():
    """Submit confidential prayer or pastoral care message."""
    data = request.get_json() or {}
    message = data.get('message')
    if not message:
        return jsonify({'status': 'error', 'message': 'Message is required.'}), 400

    ticket_id = f"CARE-{str(uuid.uuid4())[:8].upper()}"
    msg = CounselingMessage(
        ticket_id=ticket_id,
        subject=data.get('subject', 'Spiritual Guidance / Prayer Request'),
        message=message,
        is_anonymous=bool(data.get('is_anonymous', True)),
        contact_phone_or_email=data.get('contact')
    )

    db.session.add(msg)
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': 'Your prayer/counseling request has been placed in the pastoral care desk in strict confidence.',
        'ticket_id': ticket_id
    }), 201


@community_bp.route('/counseling/inbox', methods=['GET'])
@token_required
@roles_required('Pastor', 'Super Admin')
def get_pastoral_counseling_inbox(current_user):
    """Pastors view incoming counseling requests."""
    messages = CounselingMessage.query.order_by(CounselingMessage.submitted_at.desc()).all()
    return jsonify({
        'status': 'success',
        'count': len(messages),
        'requests': [m.to_dict() for m in messages]
    }), 200
