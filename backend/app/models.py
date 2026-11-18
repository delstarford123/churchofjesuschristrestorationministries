from datetime import datetime
import uuid
from werkzeug.security import generate_password_hash, check_password_hash
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

# Recognized Church Roles
VALID_ROLES = [
    'Normal Member',
    'Deacon',
    'Pastor',
    'Elder',
    'Executive Director',
    'Super Admin'
]

# Recognized Roles for Secure Messaging Channels
ROLE_CHANNELS = [
    'Pastors',
    'Elders',
    'Deacons',
    'Youth',
    'Choir',
    'Women/Dorkas',
    'General'
]

# =========================================================================
# CORE USER & AUTHENTICATION
# =========================================================================
class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    member_id = db.Column(db.String(50), unique=True, nullable=False, index=True)
    full_name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    phone_number = db.Column(db.String(30), nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(50), nullable=False, default='Normal Member')
    department = db.Column(db.String(100), default='General Congregation')
    branch = db.Column(db.String(100), default='Kakamega Central Cathedral')
    qr_code_hash = db.Column(db.String(100), nullable=True, unique=True)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime, nullable=True)

    def set_password(self, password: str):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password: str) -> bool:
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            'id': self.id,
            'member_id': self.member_id,
            'full_name': self.full_name,
            'email': self.email,
            'phone_number': self.phone_number,
            'role': self.role,
            'department': self.department,
            'branch': self.branch,
            'qr_code_hash': self.qr_code_hash or f"RLDS-QR-{self.member_id}",
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


# =========================================================================
# TITHES & ADVANCED FINANCIALS (Phase 1 & 2)
# =========================================================================
class TitheTransaction(db.Model):
    __tablename__ = 'tithe_transactions'
    
    id = db.Column(db.Integer, primary_key=True)
    client_transaction_id = db.Column(db.String(100), unique=True, nullable=False, index=True)
    member_id = db.Column(db.String(50), nullable=True, index=True)
    member_name = db.Column(db.String(120), nullable=False)
    member_email = db.Column(db.String(120), nullable=True)
    amount = db.Column(db.Float, nullable=False)
    currency = db.Column(db.String(10), default='KES')
    category = db.Column(db.String(50), nullable=False, default='Tithe')
    mpesa_receipt = db.Column(db.String(50), nullable=True, index=True)
    payment_method = db.Column(db.String(30), default='M-Pesa')
    status = db.Column(db.String(30), default='Confirmed')
    transaction_date = db.Column(db.DateTime, default=datetime.utcnow)
    synced_at = db.Column(db.DateTime, default=datetime.utcnow)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'client_transaction_id': self.client_transaction_id,
            'member_id': self.member_id,
            'member_name': self.member_name,
            'member_email': self.member_email,
            'amount': self.amount,
            'currency': self.currency,
            'category': self.category,
            'mpesa_receipt': self.mpesa_receipt,
            'payment_method': self.payment_method,
            'status': self.status,
            'transaction_date': self.transaction_date.isoformat() if self.transaction_date else None,
            'synced_at': self.synced_at.isoformat() if self.synced_at else None
        }


class LoanApplication(db.Model):
    __tablename__ = 'loan_applications'
    
    id = db.Column(db.Integer, primary_key=True)
    loan_id = db.Column(db.String(50), unique=True, nullable=False, index=True)
    client_loan_id = db.Column(db.String(100), unique=True, nullable=True, index=True)
    member_id = db.Column(db.String(50), nullable=False, index=True)
    member_name = db.Column(db.String(120), nullable=False)
    member_email = db.Column(db.String(120), nullable=True)
    member_phone = db.Column(db.String(30), nullable=True)
    amount_requested = db.Column(db.Float, nullable=False)
    amount_approved = db.Column(db.Float, nullable=True)
    repayment_period_months = db.Column(db.Integer, nullable=False)
    guarantor_name = db.Column(db.String(120), nullable=True)
    guarantor_phone = db.Column(db.String(30), nullable=False)
    guarantor_status = db.Column(db.String(30), default='Pending_Signoff')
    guarantor_otp = db.Column(db.String(10), nullable=True)
    credit_score = db.Column(db.Float, default=75.0)
    purpose = db.Column(db.String(255), default='General Development')
    status = db.Column(db.String(50), default='Pending_Executive_Review')
    due_date = db.Column(db.DateTime, nullable=True)
    applied_at = db.Column(db.DateTime, default=datetime.utcnow)
    reviewed_by = db.Column(db.String(120), nullable=True)
    reviewed_at = db.Column(db.DateTime, nullable=True)
    review_notes = db.Column(db.Text, nullable=True)
    total_repaid = db.Column(db.Float, default=0.0)

    repayments = db.relationship('LoanRepayment', backref='loan', lazy=True, cascade='all, delete-orphan')

    def to_dict(self):
        balance = (self.amount_approved or self.amount_requested) - (self.total_repaid or 0.0)
        return {
            'id': self.id,
            'loan_id': self.loan_id,
            'client_loan_id': self.client_loan_id,
            'member_id': self.member_id,
            'member_name': self.member_name,
            'member_email': self.member_email,
            'member_phone': self.member_phone,
            'amount_requested': self.amount_requested,
            'amount_approved': self.amount_approved,
            'repayment_period_months': self.repayment_period_months,
            'guarantor_name': self.guarantor_name,
            'guarantor_phone': self.guarantor_phone,
            'guarantor_status': self.guarantor_status,
            'credit_score': self.credit_score,
            'purpose': self.purpose,
            'status': self.status,
            'due_date': self.due_date.isoformat() if self.due_date else None,
            'applied_at': self.applied_at.isoformat() if self.applied_at else None,
            'reviewed_by': self.reviewed_by,
            'reviewed_at': self.reviewed_at.isoformat() if self.reviewed_at else None,
            'review_notes': self.review_notes,
            'total_repaid': self.total_repaid,
            'remaining_balance': max(0.0, balance),
            'repayments_count': len(self.repayments) if self.repayments else 0
        }


class LoanRepayment(db.Model):
    __tablename__ = 'loan_repayments'
    
    id = db.Column(db.Integer, primary_key=True)
    repayment_id = db.Column(db.String(50), unique=True, nullable=False, index=True)
    loan_application_id = db.Column(db.Integer, db.ForeignKey('loan_applications.id'), nullable=False)
    loan_id = db.Column(db.String(50), nullable=False, index=True)
    amount = db.Column(db.Float, nullable=False)
    mpesa_receipt = db.Column(db.String(50), nullable=True)
    paid_by = db.Column(db.String(120), nullable=False)
    paid_at = db.Column(db.DateTime, default=datetime.utcnow)
    notes = db.Column(db.String(255), nullable=True)

    def to_dict(self):
        return {
            'id': self.id,
            'repayment_id': self.repayment_id,
            'loan_id': self.loan_id,
            'amount': self.amount,
            'mpesa_receipt': self.mpesa_receipt,
            'paid_by': self.paid_by,
            'paid_at': self.paid_at.isoformat() if self.paid_at else None,
            'notes': self.notes
        }


class Pledge(db.Model):
    """Pledge Tracker for church land acquisition and construction campaigns."""
    __tablename__ = 'pledges'

    id = db.Column(db.Integer, primary_key=True)
    pledge_id = db.Column(db.String(50), unique=True, nullable=False, index=True)
    member_id = db.Column(db.String(50), nullable=False, index=True)
    member_name = db.Column(db.String(120), nullable=False)
    campaign_name = db.Column(db.String(150), nullable=False)
    target_date = db.Column(db.DateTime, nullable=True)
    currency = db.Column(db.String(10), default='KES')
    pledged_amount = db.Column(db.Float, nullable=False)
    fulfilled_amount = db.Column(db.Float, default=0.0)
    status = db.Column(db.String(30), default='Active')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        percentage = round((self.fulfilled_amount / self.pledged_amount * 100), 1) if self.pledged_amount > 0 else 0
        return {
            'id': self.id,
            'pledge_id': self.pledge_id,
            'member_id': self.member_id,
            'member_name': self.member_name,
            'campaign_name': self.campaign_name,
            'currency': self.currency,
            'pledged_amount': self.pledged_amount,
            'fulfilled_amount': self.fulfilled_amount,
            'remaining': max(0.0, self.pledged_amount - self.fulfilled_amount),
            'progress_percent': min(100.0, percentage),
            'status': self.status,
            'target_date': self.target_date.isoformat() if self.target_date else None,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


# =========================================================================
# PHASE 3: ADMINISTRATION, GOVERNANCE & SECURITY
# =========================================================================
class AttendanceRecord(db.Model):
    """Smart Attendance Tracker using NFC and QR Codes."""
    __tablename__ = 'attendance_records'

    id = db.Column(db.Integer, primary_key=True)
    session_id = db.Column(db.String(50), nullable=False, index=True)
    service_type = db.Column(db.String(80), nullable=False)
    branch = db.Column(db.String(100), default='Kakamega Central Cathedral')
    member_id = db.Column(db.String(50), nullable=False, index=True)
    member_name = db.Column(db.String(120), nullable=False)
    verification_method = db.Column(db.String(30), default='QR_CODE')
    device_id = db.Column(db.String(80), nullable=True)
    checkin_time = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'session_id': self.session_id,
            'service_type': self.service_type,
            'branch': self.branch,
            'member_id': self.member_id,
            'member_name': self.member_name,
            'verification_method': self.verification_method,
            'checkin_time': self.checkin_time.isoformat() if self.checkin_time else None
        }


class ChannelMessage(db.Model):
    """Category-specific secure messaging."""
    __tablename__ = 'channel_messages'

    id = db.Column(db.Integer, primary_key=True)
    channel = db.Column(db.String(50), nullable=False, index=True)
    sender_id = db.Column(db.String(50), nullable=False)
    sender_name = db.Column(db.String(120), nullable=False)
    sender_role = db.Column(db.String(50), nullable=False)
    content = db.Column(db.Text, nullable=False)
    attachment_url = db.Column(db.String(255), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'channel': self.channel,
            'sender_id': self.sender_id,
            'sender_name': self.sender_name,
            'sender_role': self.sender_role,
            'content': self.content,
            'attachment_url': self.attachment_url,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class ChurchAsset(db.Model):
    """Church Asset & Equipment Inventory Manager."""
    __tablename__ = 'church_assets'

    id = db.Column(db.Integer, primary_key=True)
    asset_id = db.Column(db.String(50), unique=True, nullable=False, index=True)
    name = db.Column(db.String(150), nullable=False)
    category = db.Column(db.String(80), nullable=False)
    serial_number = db.Column(db.String(100), nullable=True)
    condition = db.Column(db.String(50), default='Good')
    custodian = db.Column(db.String(120), default='Deacons Ministry')
    branch = db.Column(db.String(100), default='Kakamega Central Cathedral')
    purchase_value = db.Column(db.Float, default=0.0)
    last_inspected = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'asset_id': self.asset_id,
            'name': self.name,
            'category': self.category,
            'serial_number': self.serial_number,
            'condition': self.condition,
            'custodian': self.custodian,
            'branch': self.branch,
            'purchase_value': self.purchase_value,
            'last_inspected': self.last_inspected.isoformat() if self.last_inspected else None
        }


class Election(db.Model):
    """Leadership Election & Voting Portal."""
    __tablename__ = 'elections'

    id = db.Column(db.Integer, primary_key=True)
    election_id = db.Column(db.String(50), unique=True, nullable=False, index=True)
    title = db.Column(db.String(200), nullable=False)
    position = db.Column(db.String(100), nullable=False)
    candidates = db.Column(db.Text, nullable=False)
    status = db.Column(db.String(30), default='Open')
    start_date = db.Column(db.DateTime, default=datetime.utcnow)
    end_date = db.Column(db.DateTime, nullable=True)

    votes = db.relationship('Vote', backref='election', lazy=True, cascade='all, delete-orphan')

    def to_dict(self):
        import json
        return {
            'id': self.id,
            'election_id': self.election_id,
            'title': self.title,
            'position': self.position,
            'candidates': json.loads(self.candidates) if self.candidates else [],
            'status': self.status,
            'total_votes': len(self.votes),
            'start_date': self.start_date.isoformat() if self.start_date else None,
            'end_date': self.end_date.isoformat() if self.end_date else None
        }


class Vote(db.Model):
    __tablename__ = 'votes'

    id = db.Column(db.Integer, primary_key=True)
    election_id = db.Column(db.Integer, db.ForeignKey('elections.id'), nullable=False)
    voter_hash = db.Column(db.String(100), nullable=False)
    candidate_chosen = db.Column(db.String(120), nullable=False)
    cast_at = db.Column(db.DateTime, default=datetime.utcnow)


# =========================================================================
# PHASE 4: COMMUNITY, OUTREACH & EDUCATION
# =========================================================================
class SundaySchoolLesson(db.Model):
    __tablename__ = 'sunday_school_lessons'

    id = db.Column(db.Integer, primary_key=True)
    week_number = db.Column(db.Integer, nullable=False)
    theme = db.Column(db.String(200), nullable=False)
    memory_verse = db.Column(db.String(255), nullable=False)
    scripture_reading = db.Column(db.String(120), nullable=False)
    homework_task = db.Column(db.Text, nullable=True)
    age_group = db.Column(db.String(50), default='Ages 6-12')
    publish_date = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'week_number': self.week_number,
            'theme': self.theme,
            'memory_verse': self.memory_verse,
            'scripture_reading': self.scripture_reading,
            'homework_task': self.homework_task,
            'age_group': self.age_group,
            'publish_date': self.publish_date.isoformat() if self.publish_date else None
        }


class ChildPickupCode(db.Model):
    __tablename__ = 'child_pickup_codes'

    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(20), unique=True, nullable=False)
    child_name = db.Column(db.String(120), nullable=False)
    parent_member_id = db.Column(db.String(50), nullable=False)
    parent_phone = db.Column(db.String(30), nullable=False)
    status = db.Column(db.String(30), default='Active')
    generated_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'code': self.code,
            'child_name': self.child_name,
            'parent_phone': self.parent_phone,
            'status': self.status,
            'generated_at': self.generated_at.isoformat() if self.generated_at else None
        }


class NewBelieverMilestone(db.Model):
    __tablename__ = 'new_believer_milestones'

    id = db.Column(db.Integer, primary_key=True)
    member_id = db.Column(db.String(50), nullable=False, index=True)
    member_name = db.Column(db.String(120), nullable=False)
    orientation_completed = db.Column(db.Boolean, default=False)
    baptism_date = db.Column(db.DateTime, nullable=True)
    discipleship_stage = db.Column(db.String(80), default='Foundation Classes')
    certificate_id = db.Column(db.String(50), nullable=True)
    mentor_name = db.Column(db.String(120), default='Evangelism Team')

    def to_dict(self):
        return {
            'id': self.id,
            'member_id': self.member_id,
            'member_name': self.member_name,
            'orientation_completed': self.orientation_completed,
            'baptism_date': self.baptism_date.isoformat() if self.baptism_date else None,
            'discipleship_stage': self.discipleship_stage,
            'certificate_id': self.certificate_id,
            'mentor_name': self.mentor_name
        }


class CommunityProject(db.Model):
    __tablename__ = 'community_projects'

    id = db.Column(db.Integer, primary_key=True)
    project_id = db.Column(db.String(50), unique=True, nullable=False)
    name = db.Column(db.String(180), nullable=False)
    description = db.Column(db.Text, nullable=False)
    target_budget = db.Column(db.Float, nullable=False)
    raised_budget = db.Column(db.Float, default=0.0)
    beneficiaries_reached = db.Column(db.Integer, default=0)
    cbo_partner = db.Column(db.String(120), default='RLDS Benevolent Welfare Department')
    status = db.Column(db.String(50), default='In Progress')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'project_id': self.project_id,
            'name': self.name,
            'description': self.description,
            'target_budget': self.target_budget,
            'raised_budget': self.raised_budget,
            'beneficiaries_reached': self.beneficiaries_reached,
            'cbo_partner': self.cbo_partner,
            'status': self.status,
            'progress_percent': min(100.0, round((self.raised_budget / self.target_budget * 100), 1)) if self.target_budget > 0 else 0
        }


class VolunteerRoster(db.Model):
    __tablename__ = 'volunteer_rosters'

    id = db.Column(db.Integer, primary_key=True)
    event_name = db.Column(db.String(150), nullable=False)
    service_role = db.Column(db.String(100), nullable=False)
    event_date = db.Column(db.DateTime, nullable=False)
    slots_needed = db.Column(db.Integer, default=5)
    
    signups = db.relationship('VolunteerSignup', backref='roster', lazy=True, cascade='all, delete-orphan')

    def to_dict(self):
        return {
            'id': self.id,
            'event_name': self.event_name,
            'service_role': self.service_role,
            'event_date': self.event_date.isoformat() if self.event_date else None,
            'slots_needed': self.slots_needed,
            'slots_filled': len(self.signups),
            'volunteers': [s.member_name for s in self.signups]
        }


class VolunteerSignup(db.Model):
    __tablename__ = 'volunteer_signups'

    id = db.Column(db.Integer, primary_key=True)
    roster_id = db.Column(db.Integer, db.ForeignKey('volunteer_rosters.id'), nullable=False)
    member_id = db.Column(db.String(50), nullable=False)
    member_name = db.Column(db.String(120), nullable=False)
    phone = db.Column(db.String(30), nullable=False)
    signed_at = db.Column(db.DateTime, default=datetime.utcnow)


class CounselingMessage(db.Model):
    """Anonymous & confidential pastoral care communication."""
    __tablename__ = 'counseling_messages'

    id = db.Column(db.Integer, primary_key=True)
    ticket_id = db.Column(db.String(50), unique=True, nullable=False)
    subject = db.Column(db.String(150), nullable=False)
    message = db.Column(db.Text, nullable=False)
    is_anonymous = db.Column(db.Boolean, default=True)
    contact_phone_or_email = db.Column(db.String(120), nullable=True)
    pastoral_response = db.Column(db.Text, nullable=True)
    status = db.Column(db.String(30), default='Under Pastoral Prayer')
    submitted_at = db.Column(db.DateTime, default=datetime.utcnow)
    responded_at = db.Column(db.DateTime, nullable=True)

    def to_dict(self):
        return {
            'id': self.id,
            'ticket_id': self.ticket_id,
            'subject': self.subject,
            'message': self.message,
            'is_anonymous': self.is_anonymous,
            'pastoral_response': self.pastoral_response,
            'status': self.status,
            'submitted_at': self.submitted_at.isoformat() if self.submitted_at else None
        }


# =========================================================================
# PHASE 5: SMART TECH, EVENTS & ACCESSIBILITY
# =========================================================================
class ChurchEvent(db.Model):
    __tablename__ = 'church_events'

    id = db.Column(db.Integer, primary_key=True)
    event_id = db.Column(db.String(50), unique=True, nullable=False)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=False)
    location = db.Column(db.String(150), nullable=False)
    event_date = db.Column(db.DateTime, nullable=False)
    category = db.Column(db.String(50), default='Sanctuary Service')
    is_major_event = db.Column(db.Boolean, default=False)
    
    rsvps = db.relationship('EventRSVP', backref='event', lazy=True, cascade='all, delete-orphan')

    def to_dict(self):
        return {
            'id': self.id,
            'event_id': self.event_id,
            'title': self.title,
            'description': self.description,
            'location': self.location,
            'event_date': self.event_date.isoformat() if self.event_date else None,
            'category': self.category,
            'is_major_event': self.is_major_event,
            'rsvp_count': len(self.rsvps)
        }


class EventRSVP(db.Model):
    __tablename__ = 'event_rsvps'

    id = db.Column(db.Integer, primary_key=True)
    event_id = db.Column(db.Integer, db.ForeignKey('church_events.id'), nullable=False)
    member_id = db.Column(db.String(50), nullable=False)
    member_name = db.Column(db.String(120), nullable=False)
    phone = db.Column(db.String(30), nullable=False)
    guests_count = db.Column(db.Integer, default=1)
    rsvp_at = db.Column(db.DateTime, default=datetime.utcnow)


class ChurchBranch(db.Model):
    """Branch locator across Kakamega & Kenya."""
    __tablename__ = 'church_branches'

    id = db.Column(db.Integer, primary_key=True)
    branch_id = db.Column(db.String(50), unique=True, nullable=False)
    name = db.Column(db.String(150), nullable=False)
    county = db.Column(db.String(80), default='Kakamega')
    pastor_in_charge = db.Column(db.String(120), nullable=False)
    contact_phone = db.Column(db.String(30), nullable=False)
    latitude = db.Column(db.Float, nullable=False)
    longitude = db.Column(db.Float, nullable=False)
    address = db.Column(db.String(255), nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'branch_id': self.branch_id,
            'name': self.name,
            'county': self.county,
            'pastor_in_charge': self.pastor_in_charge,
            'contact_phone': self.contact_phone,
            'latitude': self.latitude,
            'longitude': self.longitude,
            'address': self.address
        }


class SMSLog(db.Model):
    """Africa's Talking SMS log for feature phone fallback."""
    __tablename__ = 'sms_logs'

    id = db.Column(db.Integer, primary_key=True)
    recipient_phone = db.Column(db.String(30), nullable=False)
    message = db.Column(db.Text, nullable=False)
    provider = db.Column(db.String(50), default='AfricasTalking')
    status = db.Column(db.String(30), default='Queued')
    sent_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'recipient_phone': self.recipient_phone,
            'message': self.message,
            'status': self.status,
            'sent_at': self.sent_at.isoformat() if self.sent_at else None
        }


# =========================================================================
# ANNOUNCEMENTS & AUDIT
# =========================================================================
class Announcement(db.Model):
    __tablename__ = 'announcements'
    
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    content = db.Column(db.Text, nullable=False)
    category = db.Column(db.String(50), default='All')
    author = db.Column(db.String(120), default='Church Administration')
    is_pinned = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'content': self.content,
            'category': self.category,
            'author': self.author,
            'is_pinned': self.is_pinned,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class AuditLog(db.Model):
    __tablename__ = 'audit_logs'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.String(50), nullable=True)
    action = db.Column(db.String(100), nullable=False)
    details = db.Column(db.Text, nullable=True)
    ip_address = db.Column(db.String(50), nullable=True)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
