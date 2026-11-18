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


# =========================================================================
# 20 HIGH-IMPACT FEATURES FOR DEEPER CHURCH CONNECTION & RECORDS
# =========================================================================

class PriesthoodLineage(db.Model):
    """1. Digital Ordination & Priesthood Lineage Tracker."""
    __tablename__ = 'priesthood_lineages'

    id = db.Column(db.Integer, primary_key=True)
    member_id = db.Column(db.String(50), nullable=False, index=True)
    minister_name = db.Column(db.String(120), nullable=False)
    priesthood_office = db.Column(db.String(60), nullable=False) # Deacon, Teacher, Priest, Elder, High Priest, Bishop, Apostle
    ordained_by = db.Column(db.String(120), nullable=False)
    ordination_date = db.Column(db.Date, nullable=False)
    quorum = db.Column(db.String(80), default='Elders Quorum')
    certificate_number = db.Column(db.String(60), unique=True, nullable=False)
    lineage_notes = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'member_id': self.member_id,
            'minister_name': self.minister_name,
            'priesthood_office': self.priesthood_office,
            'ordained_by': self.ordained_by,
            'ordination_date': self.ordination_date.isoformat() if self.ordination_date else None,
            'quorum': self.quorum,
            'certificate_number': self.certificate_number,
            'lineage_notes': self.lineage_notes
        }


class SacramentVisitation(db.Model):
    """2. Sacrament Service Attendance & Sick Visitation Roster."""
    __tablename__ = 'sacrament_visitations'

    id = db.Column(db.Integer, primary_key=True)
    member_id = db.Column(db.String(50), nullable=False)
    member_name = db.Column(db.String(120), nullable=False)
    home_address = db.Column(db.String(255), nullable=False)
    visiting_deacon_or_elder = db.Column(db.String(120), nullable=False)
    visit_date = db.Column(db.DateTime, default=datetime.utcnow)
    sacrament_administered = db.Column(db.Boolean, default=True)
    welfare_needs = db.Column(db.Text, nullable=True)
    prayer_requests = db.Column(db.Text, nullable=True)
    status = db.Column(db.String(30), default='Completed')

    def to_dict(self):
        return {
            'id': self.id,
            'member_id': self.member_id,
            'member_name': self.member_name,
            'home_address': self.home_address,
            'visiting_deacon_or_elder': self.visiting_deacon_or_elder,
            'visit_date': self.visit_date.isoformat() if self.visit_date else None,
            'sacrament_administered': self.sacrament_administered,
            'welfare_needs': self.welfare_needs,
            'prayer_requests': self.prayer_requests,
            'status': self.status
        }


class AnniversaryBlessing(db.Model):
    """3. Automated Birthday & Baptism Anniversary Blessings."""
    __tablename__ = 'anniversary_blessings'

    id = db.Column(db.Integer, primary_key=True)
    member_id = db.Column(db.String(50), nullable=False)
    member_name = db.Column(db.String(120), nullable=False)
    phone_number = db.Column(db.String(30), nullable=False)
    anniversary_type = db.Column(db.String(30), nullable=False) # Birthday, Baptism, Ordination, Wedding
    milestone_date = db.Column(db.Date, nullable=False)
    blessing_scripture = db.Column(db.String(150), default='Numbers 6:24-26 (IV)')
    custom_pastoral_message = db.Column(db.Text, nullable=False)
    sms_status = db.Column(db.String(30), default='Sent')
    sent_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'member_id': self.member_id,
            'member_name': self.member_name,
            'phone_number': self.phone_number,
            'anniversary_type': self.anniversary_type,
            'milestone_date': self.milestone_date.isoformat() if self.milestone_date else None,
            'blessing_scripture': self.blessing_scripture,
            'custom_pastoral_message': self.custom_pastoral_message,
            'sms_status': self.sms_status
        }


class HymnalSong(db.Model):
    """4. Restoration Hymnal with Offline Audio Accompaniment."""
    __tablename__ = 'hymnal_songs'

    id = db.Column(db.Integer, primary_key=True)
    hymn_number = db.Column(db.Integer, unique=True, nullable=False)
    title_en = db.Column(db.String(150), nullable=False)
    title_sw = db.Column(db.String(150), nullable=False)
    lyrics_en = db.Column(db.Text, nullable=False)
    lyrics_sw = db.Column(db.Text, nullable=False)
    key_signature = db.Column(db.String(20), default='G Major')
    category = db.Column(db.String(60), default='Zion & Gathering')
    midi_audio_asset = db.Column(db.String(200), default='assets/audio/hymn_default.mp3')

    def to_dict(self):
        return {
            'id': self.id,
            'hymn_number': self.hymn_number,
            'title_en': self.title_en,
            'title_sw': self.title_sw,
            'lyrics_en': self.lyrics_en,
            'lyrics_sw': self.lyrics_sw,
            'key_signature': self.key_signature,
            'category': self.category,
            'midi_audio_asset': self.midi_audio_asset
        }


class MarriageRegistry(db.Model):
    """6. Sacred Vows & Marriage Registry."""
    __tablename__ = 'marriage_registry'

    id = db.Column(db.Integer, primary_key=True)
    certificate_number = db.Column(db.String(60), unique=True, nullable=False)
    groom_name = db.Column(db.String(120), nullable=False)
    bride_name = db.Column(db.String(120), nullable=False)
    matrimony_date = db.Column(db.Date, nullable=False)
    branch_name = db.Column(db.String(100), default='Kakamega Central Cathedral')
    officiant_elder = db.Column(db.String(120), nullable=False)
    witness_1 = db.Column(db.String(120), nullable=False)
    witness_2 = db.Column(db.String(120), nullable=False)
    counseling_completed = db.Column(db.Boolean, default=True)

    def to_dict(self):
        return {
            'id': self.id,
            'certificate_number': self.certificate_number,
            'groom_name': self.groom_name,
            'bride_name': self.bride_name,
            'matrimony_date': self.matrimony_date.isoformat() if self.matrimony_date else None,
            'branch_name': self.branch_name,
            'officiant_elder': self.officiant_elder,
            'witness_1': self.witness_1,
            'witness_2': self.witness_2,
            'counseling_completed': self.counseling_completed
        }


class SundaySchoolBadge(db.Model):
    """7. Sunday School Scripture Memorization Badge System."""
    __tablename__ = 'sunday_school_badges'

    id = db.Column(db.Integer, primary_key=True)
    child_name = db.Column(db.String(120), nullable=False)
    parent_id = db.Column(db.String(50), nullable=False)
    badge_title = db.Column(db.String(100), nullable=False) # e.g. "Enoch's Zion Pioneer", "Nephi's Courage"
    scripture_verse = db.Column(db.String(150), nullable=False)
    stars_awarded = db.Column(db.Integer, default=5)
    awarded_date = db.Column(db.Date, default=datetime.utcnow)
    teacher_name = db.Column(db.String(120), default='Teacher Dorcas Atieno')

    def to_dict(self):
        return {
            'id': self.id,
            'child_name': self.child_name,
            'parent_id': self.parent_id,
            'badge_title': self.badge_title,
            'scripture_verse': self.scripture_verse,
            'stars_awarded': self.stars_awarded,
            'awarded_date': self.awarded_date.isoformat() if self.awarded_date else None,
            'teacher_name': self.teacher_name
        }


class PrayerRequestWall(db.Model):
    """8. Direct-to-Pastor Prayer Request Wall (Private & Congregational)."""
    __tablename__ = 'prayer_requests_wall'

    id = db.Column(db.Integer, primary_key=True)
    member_id = db.Column(db.String(50), nullable=False)
    requester_name = db.Column(db.String(120), default='Faithful Believer')
    is_confidential = db.Column(db.Boolean, default=False) # True = Pastors/Elders only, False = Church Wall
    title = db.Column(db.String(150), nullable=False)
    request_text = db.Column(db.Text, nullable=False)
    prayer_count = db.Column(db.Integer, default=1)
    answered_testimony = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'member_id': self.member_id,
            'requester_name': 'Anonymous' if self.is_confidential else self.requester_name,
            'is_confidential': self.is_confidential,
            'title': self.title,
            'request_text': self.request_text,
            'prayer_count': self.prayer_count,
            'answered_testimony': self.answered_testimony,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class FinancialTransparencyReport(db.Model):
    """9. Quarterly Ministry Stewardship Financial Transparency Reports."""
    __tablename__ = 'financial_transparency_reports'

    id = db.Column(db.Integer, primary_key=True)
    quarter = db.Column(db.String(20), nullable=False) # e.g. "Q3 2026"
    total_tithes = db.Column(db.Float, nullable=False)
    benevolence_spent = db.Column(db.Float, nullable=False)
    evangelism_spent = db.Column(db.Float, nullable=False)
    sanctuary_building_spent = db.Column(db.Float, nullable=False)
    stewardship_kitty_reserve = db.Column(db.Float, nullable=False)
    summary_notes = db.Column(db.Text, nullable=False)
    published_by = db.Column(db.String(120), default='Presiding Bishopric & Treasury Council')
    published_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'quarter': self.quarter,
            'total_tithes': self.total_tithes,
            'benevolence_spent': self.benevolence_spent,
            'evangelism_spent': self.evangelism_spent,
            'sanctuary_building_spent': self.sanctuary_building_spent,
            'stewardship_kitty_reserve': self.stewardship_kitty_reserve,
            'summary_notes': self.summary_notes,
            'published_by': self.published_by,
            'published_at': self.published_at.isoformat() if self.published_at else None
        }


class EmergencyBenevolenceAlert(db.Model):
    """10. Emergency Medical & Bereavement Assistance Fund Alerts."""
    __tablename__ = 'emergency_benevolence_alerts'

    id = db.Column(db.Integer, primary_key=True)
    case_code = db.Column(db.String(50), unique=True, nullable=False)
    title = db.Column(db.String(150), nullable=False)
    cause_type = db.Column(db.String(50), default='Medical Emergency') # Medical, Bereavement, Disaster
    target_amount = db.Column(db.Float, nullable=False)
    raised_amount = db.Column(db.Float, default=0.0)
    description = db.Column(db.Text, nullable=False)
    deacon_signoff = db.Column(db.String(120), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'case_code': self.case_code,
            'title': self.title,
            'cause_type': self.cause_type,
            'target_amount': self.target_amount,
            'raised_amount': self.raised_amount,
            'description': self.description,
            'deacon_signoff': self.deacon_signoff,
            'is_active': self.is_active,
            'progress_percent': round((self.raised_amount / self.target_amount) * 100, 1) if self.target_amount > 0 else 0
        }


class DevotionalPlan(db.Model):
    """11. Push-Notification Devotional & Daily Fasting Reminders."""
    __tablename__ = 'devotional_plans'

    id = db.Column(db.Integer, primary_key=True)
    day_date = db.Column(db.Date, nullable=False, unique=True)
    title = db.Column(db.String(150), nullable=False)
    iv_scripture_reference = db.Column(db.String(100), nullable=False)
    bom_reference = db.Column(db.String(100), nullable=False)
    pastoral_reflection = db.Column(db.Text, nullable=False)
    fasting_guideline = db.Column(db.String(255), nullable=True) # e.g. "Wednesday Restoration Fast until 3 PM"

    def to_dict(self):
        return {
            'id': self.id,
            'day_date': self.day_date.isoformat() if self.day_date else None,
            'title': self.title,
            'iv_scripture_reference': self.iv_scripture_reference,
            'bom_reference': self.bom_reference,
            'pastoral_reflection': self.pastoral_reflection,
            'fasting_guideline': self.fasting_guideline
        }


class AssetInventoryTag(db.Model):
    """12. Church Assets & Sacred Communion Inventory QR Tagging."""
    __tablename__ = 'asset_inventory_tags'

    id = db.Column(db.Integer, primary_key=True)
    tag_code = db.Column(db.String(60), unique=True, nullable=False) # QR Code Content
    item_name = db.Column(db.String(120), nullable=False)
    category = db.Column(db.String(60), default='Sacred Communion Trays') # Communion, Sound, Instruments, Tents
    branch_location = db.Column(db.String(100), default='Kakamega Central Cathedral')
    condition = db.Column(db.String(40), default='Excellent') # Excellent, Good, Service Required
    last_audited_by = db.Column(db.String(120), default='Deacon Board')
    last_audited_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'tag_code': self.tag_code,
            'item_name': self.item_name,
            'category': self.category,
            'branch_location': self.branch_location,
            'condition': self.condition,
            'last_audited_by': self.last_audited_by,
            'last_audited_at': self.last_audited_at.isoformat() if self.last_audited_at else None
        }


class BaptismalCertificate(db.Model):
    """13. Digital Covenant & Baptismal Certificate Generator."""
    __tablename__ = 'baptismal_certificates'

    id = db.Column(db.Integer, primary_key=True)
    certificate_hash = db.Column(db.String(80), unique=True, nullable=False)
    member_id = db.Column(db.String(50), nullable=False)
    candidate_name = db.Column(db.String(120), nullable=False)
    baptism_date = db.Column(db.Date, nullable=False)
    baptizing_elder = db.Column(db.String(120), nullable=False)
    confirming_elder = db.Column(db.String(120), nullable=False)
    presiding_bishop = db.Column(db.String(120), default='Presiding Bishopric')
    digital_signature_stamp = db.Column(db.String(120), default='VERIFIED-RLDS-SACRED-SEAL')

    def to_dict(self):
        return {
            'id': self.id,
            'certificate_hash': self.certificate_hash,
            'member_id': self.member_id,
            'candidate_name': self.candidate_name,
            'baptism_date': self.baptism_date.isoformat() if self.baptism_date else None,
            'baptizing_elder': self.baptizing_elder,
            'confirming_elder': self.confirming_elder,
            'presiding_bishop': self.presiding_bishop,
            'digital_signature_stamp': self.digital_signature_stamp
        }


class CellGroup(db.Model):
    """14. Small-Group / Fellowship Cell Group Portal."""
    __tablename__ = 'cell_groups'

    id = db.Column(db.Integer, primary_key=True)
    group_name = db.Column(db.String(120), nullable=False) # e.g. "Lurambi Shalom Cell"
    neighborhood_area = db.Column(db.String(120), nullable=False)
    host_family = db.Column(db.String(120), nullable=False)
    meeting_day_time = db.Column(db.String(80), default='Tuesdays 5:30 PM')
    leader_elder = db.Column(db.String(120), nullable=False)
    contact_phone = db.Column(db.String(30), nullable=False)
    active_members_count = db.Column(db.Integer, default=18)

    def to_dict(self):
        return {
            'id': self.id,
            'group_name': self.group_name,
            'neighborhood_area': self.neighborhood_area,
            'host_family': self.host_family,
            'meeting_day_time': self.meeting_day_time,
            'leader_elder': self.leader_elder,
            'contact_phone': self.contact_phone,
            'active_members_count': self.active_members_count
        }


class AudioSermon(db.Model):
    """15. Offline Voice Sermon Recorder & Podcast Archive."""
    __tablename__ = 'audio_sermons'

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    preacher = db.Column(db.String(120), nullable=False)
    scripture_reference = db.Column(db.String(120), nullable=False)
    preach_date = db.Column(db.Date, nullable=False)
    duration_minutes = db.Column(db.Integer, default=45)
    audio_file_url = db.Column(db.String(255), nullable=False)
    summary_notes = db.Column(db.Text, nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'preacher': self.preacher,
            'scripture_reference': self.scripture_reference,
            'preach_date': self.preach_date.isoformat() if self.preach_date else None,
            'duration_minutes': self.duration_minutes,
            'audio_file_url': self.audio_file_url,
            'summary_notes': self.summary_notes
        }


class YouthMentorshipProfile(db.Model):
    """16. Youth Mentorship & Career Empowerment Directory."""
    __tablename__ = 'youth_mentorship_profiles'

    id = db.Column(db.Integer, primary_key=True)
    mentor_name = db.Column(db.String(120), nullable=False)
    profession = db.Column(db.String(120), nullable=False) # Software, Agriculture, Medicine, Law
    organization = db.Column(db.String(120), nullable=False)
    phone_contact = db.Column(db.String(30), nullable=False)
    email = db.Column(db.String(120), nullable=False)
    available_mentee_slots = db.Column(db.Integer, default=3)
    bio = db.Column(db.Text, nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'mentor_name': self.mentor_name,
            'profession': self.profession,
            'organization': self.organization,
            'phone_contact': self.phone_contact,
            'email': self.email,
            'available_mentee_slots': self.available_mentee_slots,
            'bio': self.bio
        }


class ChildPickupSecurity(db.Model):
    """17. Parent-Child Secure Pickup Verification System (QR & One-Time PIN)."""
    __tablename__ = 'child_pickup_securities'

    id = db.Column(db.Integer, primary_key=True)
    child_name = db.Column(db.String(120), nullable=False)
    parent_member_id = db.Column(db.String(50), nullable=False)
    one_time_pin = db.Column(db.String(10), nullable=False)
    qr_verification_token = db.Column(db.String(80), unique=True, nullable=False)
    service_date = db.Column(db.Date, default=datetime.utcnow)
    is_released = db.Column(db.Boolean, default=False)
    verified_by_teacher = db.Column(db.String(120), nullable=True)
    released_at = db.Column(db.DateTime, nullable=True)

    def to_dict(self):
        return {
            'id': self.id,
            'child_name': self.child_name,
            'parent_member_id': self.parent_member_id,
            'one_time_pin': self.one_time_pin,
            'qr_verification_token': self.qr_verification_token,
            'is_released': self.is_released,
            'verified_by_teacher': self.verified_by_teacher
        }


class PledgeCampaign(db.Model):
    """18. Multi-Pledge Project Tracker (Land Acquisition & Sanctuary Building)."""
    __tablename__ = 'pledge_campaigns'

    id = db.Column(db.Integer, primary_key=True)
    campaign_name = db.Column(db.String(150), nullable=False)
    target_amount = db.Column(db.Float, nullable=False)
    raised_amount = db.Column(db.Float, default=0.0)
    deadline_date = db.Column(db.Date, nullable=False)
    description = db.Column(db.Text, nullable=False)
    total_pledgers = db.Column(db.Integer, default=0)

    def to_dict(self):
        return {
            'id': self.id,
            'campaign_name': self.campaign_name,
            'target_amount': self.target_amount,
            'raised_amount': self.raised_amount,
            'deadline_date': self.deadline_date.isoformat() if self.deadline_date else None,
            'description': self.description,
            'total_pledgers': self.total_pledgers,
            'progress_percent': round((self.raised_amount / self.target_amount) * 100, 1) if self.target_amount > 0 else 0
        }


class CounselingAppointment(db.Model):
    """19. Digital Pastoral Counseling Appointment Scheduler."""
    __tablename__ = 'counseling_appointments'

    id = db.Column(db.Integer, primary_key=True)
    member_id = db.Column(db.String(50), nullable=False)
    member_name = db.Column(db.String(120), nullable=False)
    minister_name = db.Column(db.String(120), default='Pastor Samuel Makokha')
    appointment_time = db.Column(db.DateTime, nullable=False)
    session_mode = db.Column(db.String(30), default='In-Person Sanctuary') # In-Person Sanctuary, Phone Call
    counseling_topic = db.Column(db.String(150), nullable=False)
    status = db.Column(db.String(30), default='Scheduled') # Scheduled, Completed, Rescheduled

    def to_dict(self):
        return {
            'id': self.id,
            'member_id': self.member_id,
            'member_name': self.member_name,
            'minister_name': self.minister_name,
            'appointment_time': self.appointment_time.isoformat() if self.appointment_time else None,
            'session_mode': self.session_mode,
            'counseling_topic': self.counseling_topic,
            'status': self.status
        }


class CouncilElection(db.Model):
    """20. Church Council Voting & Deliberative Governance System."""
    __tablename__ = 'council_elections'

    id = db.Column(db.Integer, primary_key=True)
    election_title = db.Column(db.String(150), nullable=False)
    resolution_details = db.Column(db.Text, nullable=False)
    start_date = db.Column(db.DateTime, default=datetime.utcnow)
    end_date = db.Column(db.DateTime, nullable=False)
    total_votes = db.Column(db.Integer, default=0)
    yes_votes = db.Column(db.Integer, default=0)
    no_votes = db.Column(db.Integer, default=0)
    status = db.Column(db.String(30), default='Open') # Open, Concluded

    def to_dict(self):
        return {
            'id': self.id,
            'election_title': self.election_title,
            'resolution_details': self.resolution_details,
            'start_date': self.start_date.isoformat() if self.start_date else None,
            'end_date': self.end_date.isoformat() if self.end_date else None,
            'total_votes': self.total_votes,
            'yes_votes': self.yes_votes,
            'no_votes': self.no_votes,
            'status': self.status
        }
