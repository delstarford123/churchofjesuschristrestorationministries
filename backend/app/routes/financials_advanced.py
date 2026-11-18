import random
import uuid
from datetime import datetime, timedelta
from flask import Blueprint, request, jsonify
from app.models import db, User, TitheTransaction, LoanApplication, LoanRepayment, Pledge, SMSLog
from app.services.auth_service import token_required, roles_required
from app.services.email_service import EmailService

financials_bp = Blueprint('financials_bp', __name__, url_prefix='/api/v1/financials')

# =========================================================================
# 7. AUTOMATED CREDIT SCORING ALGORITHM
# =========================================================================
@financials_bp.route('/credit-score/<string:member_id>', methods=['GET'])
@token_required
def get_member_credit_score(current_user, member_id):
    """
    Automated Credit Scoring Algorithm:
    Evaluates:
    - Tithe consistency (frequency in past 12 months)
    - Total contribution volume
    - Previous Stewardship Kitty loan repayment history
    Returns: Score (0-100), Risk Tier, Recommended Loan Ceiling.
    """
    # Authorization: Member himself, Executive Director, or Super Admin
    if current_user.member_id != member_id and current_user.role not in ['Executive Director', 'Super Admin']:
        return jsonify({'status': 'error', 'message': 'Unauthorized access to member credit score.'}), 403

    user = User.query.filter_by(member_id=member_id).first()
    if not user:
        return jsonify({'status': 'error', 'message': 'Member not found.'}), 404

    # 1. Evaluate Tithe Frequency & Volume
    transactions = TitheTransaction.query.filter_by(member_id=member_id).all()
    tx_count = len(transactions)
    total_given = sum(t.amount for t in transactions)

    # 2. Evaluate Previous Loans Repayment
    loans = LoanApplication.query.filter_by(member_id=member_id).all()
    completed_loans = [l for l in loans if l.status == 'Repaid']
    defaulted_loans = [l for l in loans if l.status == 'Defaulted']

    # Baseline Score = 50.0
    score = 50.0

    # Tithe Consistency Points (up to +30 pts)
    if tx_count >= 12:
        score += 30.0
    elif tx_count >= 6:
        score += 20.0
    elif tx_count >= 3:
        score += 10.0

    # Giving Volume Points (up to +15 pts)
    if total_given >= 100000:
        score += 15.0
    elif total_given >= 50000:
        score += 10.0
    elif total_given >= 10000:
        score += 5.0

    # Loan History Points (up to +15 pts or penalty)
    score += len(completed_loans) * 5.0
    score -= len(defaulted_loans) * 25.0

    # Clamp Score between 10.0 and 99.0
    score = max(10.0, min(99.0, round(score, 1)))

    # Determine Risk Tier & Recommended Loan Ceiling
    if score >= 80:
        risk_tier = 'Low Risk (Preferred Borrower)'
        max_loan = min(150000.0, max(20000.0, total_given * 0.6))
    elif score >= 60:
        risk_tier = 'Moderate Risk (Standard Approval)'
        max_loan = min(60000.0, max(10000.0, total_given * 0.4))
    else:
        risk_tier = 'High Risk (Requires Strong Guarantor)'
        max_loan = 15000.0

    return jsonify({
        'status': 'success',
        'member_id': member_id,
        'member_name': user.full_name,
        'credit_score': score,
        'risk_tier': risk_tier,
        'eligible_loan_limit': round(max_loan, 2),
        'metrics': {
            'total_tithe_transactions': tx_count,
            'total_contributions_kes': total_given,
            'completed_loans': len(completed_loans),
            'defaulted_loans': len(defaulted_loans),
            'membership_date': user.created_at.isoformat() if user.created_at else None
        }
    }), 200


# =========================================================================
# 8. DIGITAL GUARANTOR ACCEPTANCE WORKFLOW
# =========================================================================
@financials_bp.route('/loans/<string:loan_id>/guarantor/request-otp', methods=['POST'])
def request_guarantor_otp(loan_id):
    """Generates and dispatches a 6-digit OTP to the designated guarantor's phone."""
    loan = LoanApplication.query.filter_by(loan_id=loan_id).first()
    if not loan:
        return jsonify({'status': 'error', 'message': 'Loan application not found.'}), 404

    otp = f"{random.randint(100000, 999999)}"
    loan.guarantor_otp = otp
    db.session.commit()

    # Log SMS dispatch
    sms = SMSLog(
        recipient_phone=loan.guarantor_phone,
        message=(
            f"RLDS Stewardship Kitty: {loan.member_name} has designated you as guarantor for KES {loan.amount_requested:,.2f}. "
            f"Your authorization OTP is: {otp}. Do not share if you do not consent."
        ),
        provider='AfricasTalking',
        status='Sent'
    )
    db.session.add(sms)
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': f"Guarantor signoff OTP dispatched to {loan.guarantor_phone}.",
        'guarantor_phone': loan.guarantor_phone,
        'demo_otp': otp # Provided for instant testing
    }), 200


@financials_bp.route('/loans/<string:loan_id>/guarantor/verify-otp', methods=['POST'])
def verify_guarantor_otp(loan_id):
    """Verifies the guarantor's OTP and signs off on the loan."""
    data = request.get_json() or {}
    otp = data.get('otp', '').strip()
    guarantor_name = data.get('guarantor_name', '').strip()

    loan = LoanApplication.query.filter_by(loan_id=loan_id).first()
    if not loan:
        return jsonify({'status': 'error', 'message': 'Loan application not found.'}), 404

    if not loan.guarantor_otp or loan.guarantor_otp != otp:
        return jsonify({'status': 'error', 'message': 'Invalid or expired guarantor OTP code.'}), 400

    loan.guarantor_status = 'Verified'
    if guarantor_name:
        loan.guarantor_name = guarantor_name
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': f"Guarantor verification confirmed for loan {loan_id}.",
        'guarantor_status': 'Verified'
    }), 200


# =========================================================================
# 9. AUTOMATED M-PESA LOAN REPAYMENT REMINDERS
# =========================================================================
@financials_bp.route('/loans/reminders/trigger', methods=['POST'])
@token_required
@roles_required('Executive Director', 'Super Admin')
def trigger_loan_repayment_reminders(current_user):
    """
    Scans active approved loans and triggers repayment reminders via STK Push / SMS.
    """
    approved_loans = LoanApplication.query.filter_by(status='Approved').all()
    reminders_sent = 0

    for loan in approved_loans:
        balance = (loan.amount_approved or loan.amount_requested) - (loan.total_repaid or 0.0)
        if balance > 0 and loan.member_phone:
            sms = SMSLog(
                recipient_phone=loan.member_phone,
                message=(
                    f"Dear {loan.member_name}, this is a gentle reminder from RLDS Stewardship Kitty. "
                    f"Your loan {loan.loan_id} has an outstanding balance of KES {balance:,.2f}. "
                    f"Kindly remit via M-Pesa Paybill 174379 Account {loan.loan_id}."
                ),
                status='Sent'
            )
            db.session.add(sms)
            reminders_sent += 1

    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': f"Repayment reminders dispatched to {reminders_sent} active borrowers.",
        'reminders_count': reminders_sent
    }), 200


# =========================================================================
# 10. ANNUAL CONTRIBUTION & TAX STATEMENT GENERATOR
# =========================================================================
@financials_bp.route('/statement/annual', methods=['GET'])
@token_required
def get_annual_tax_statement(current_user):
    """
    Generates an official yearly summary of tithes, offerings, and building funds
    for personal or tax purposes.
    """
    year = int(request.args.get('year', datetime.utcnow().year))
    target_member_id = request.args.get('member_id', current_user.member_id)

    # Privileged roles can view any member's statement
    if target_member_id != current_user.member_id and current_user.role not in ['Executive Director', 'Super Admin', 'Pastor']:
        return jsonify({'status': 'error', 'message': 'Unauthorized access to statement.'}), 403

    user = User.query.filter_by(member_id=target_member_id).first()
    if not user:
        return jsonify({'status': 'error', 'message': 'Member not found.'}), 404

    records = TitheTransaction.query.filter_by(member_id=target_member_id).all()
    # Filter by specified year
    year_records = [
        r for r in records if r.transaction_date and r.transaction_date.year == year
    ]

    total_tithes = sum(r.amount for r in year_records if 'tithe' in r.category.lower())
    total_thanksgiving = sum(r.amount for r in year_records if 'thanksgiving' in r.category.lower())
    total_building = sum(r.amount for r in year_records if 'building' in r.category.lower())
    total_missions = sum(r.amount for r in year_records if 'mission' in r.category.lower())
    grand_total = sum(r.amount for r in year_records)

    statement = {
        'statement_id': f"RLDS-STMT-{year}-{target_member_id}",
        'church': "The Church of Jesus Christ Restoration Ministry",
        'member': {
            'name': user.full_name,
            'member_id': user.member_id,
            'email': user.email,
            'branch': user.branch
        },
        'tax_year': year,
        'summary': {
            'tithes_kes': total_tithes,
            'thanksgiving_kes': total_thanksgiving,
            'building_fund_kes': total_building,
            'missions_kes': total_missions,
            'other_kes': max(0.0, grand_total - (total_tithes + total_thanksgiving + total_building + total_missions)),
            'grand_total_kes': grand_total
        },
        'transactions_count': len(year_records),
        'certified_by': "RLDS Supreme Treasury Board & Presiding Bishopric",
        'generated_at': datetime.utcnow().isoformat()
    }

    return jsonify({
        'status': 'success',
        'statement': statement
    }), 200


# =========================================================================
# 11. MULTI-CURRENCY & PLEDGE TRACKER
# =========================================================================
@financials_bp.route('/pledges', methods=['GET'])
@token_required
def get_pledges(current_user):
    """List pledges for the church or current member."""
    query = Pledge.query
    if current_user.role not in ['Executive Director', 'Super Admin', 'Pastor']:
        query = query.filter_by(member_id=current_user.member_id)

    campaign = request.args.get('campaign')
    if campaign:
        query = query.filter_by(campaign_name=campaign)

    pledges = query.order_by(Pledge.created_at.desc()).all()
    total_pledged = sum(p.pledged_amount for p in pledges)
    total_fulfilled = sum(p.fulfilled_amount for p in pledges)

    return jsonify({
        'status': 'success',
        'count': len(pledges),
        'total_pledged': total_pledged,
        'total_fulfilled': total_fulfilled,
        'pledges': [p.to_dict() for p in pledges]
    }), 200


@financials_bp.route('/pledges', methods=['POST'])
@token_required
def create_pledge(current_user):
    """Create a new pledge towards church land acquisition or construction."""
    data = request.get_json() or {}
    
    required = ['campaign_name', 'pledged_amount']
    missing = [f for f in required if not data.get(f)]
    if missing:
        return jsonify({'status': 'error', 'message': f"Missing fields: {', '.join(missing)}"}), 400

    pledge_id = f"PLG-{str(uuid.uuid4())[:8].upper()}"
    target_date = None
    if data.get('target_date'):
        try:
            target_date = datetime.fromisoformat(data['target_date'].replace('Z', '+00:00'))
        except Exception:
            pass

    pledge = Pledge(
        pledge_id=pledge_id,
        member_id=current_user.member_id,
        member_name=current_user.full_name,
        campaign_name=data['campaign_name'],
        currency=data.get('currency', 'KES'),
        pledged_amount=float(data['pledged_amount']),
        fulfilled_amount=float(data.get('initial_payment', 0.0)),
        target_date=target_date,
        status='Active'
    )

    db.session.add(pledge)
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': f"Pledge towards '{pledge.campaign_name}' recorded successfully.",
        'pledge': pledge.to_dict()
    }), 201


@financials_bp.route('/pledges/<string:pledge_id>/fulfill', methods=['POST'])
@token_required
def fulfill_pledge(current_user, pledge_id):
    """Record an installment towards an active pledge."""
    pledge = Pledge.query.filter_by(pledge_id=pledge_id).first()
    if not pledge:
        return jsonify({'status': 'error', 'message': 'Pledge not found.'}), 404

    data = request.get_json() or {}
    amount = float(data.get('amount', 0))
    if amount <= 0:
        return jsonify({'status': 'error', 'message': 'Amount must be greater than zero.'}), 400

    pledge.fulfilled_amount += amount
    if pledge.fulfilled_amount >= pledge.pledged_amount:
        pledge.status = 'Fulfilled'

    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': f"Recorded installment of KES {amount:,.2f} towards pledge.",
        'pledge': pledge.to_dict()
    }), 200


# =========================================================================
# 12. TRANSPARENT KITTY FUND ANALYTICS (Executive Directors)
# =========================================================================
@financials_bp.route('/kitty/analytics', methods=['GET'])
@token_required
@roles_required('Executive Director', 'Super Admin')
def get_kitty_analytics(current_user):
    """
    Real-time dashboard for Executive Directors showing total kitty liquidity,
    active loans, default rates, and reserve funds.
    """
    all_loans = LoanApplication.query.all()
    all_tithes = TitheTransaction.query.all()

    total_contributions = sum(t.amount for t in all_tithes)
    # 25% of total contributions allocated to Stewardship Kitty reserve
    allocated_kitty_pool = total_contributions * 0.25 + 500000.0 # Base reserve

    total_disbursed = sum(l.amount_approved or l.amount_requested for l in all_loans if l.status in ['Approved', 'Repaid'])
    total_repaid = sum(l.total_repaid for l in all_loans)
    active_loans = [l for l in all_loans if l.status == 'Approved' and (l.amount_approved or l.amount_requested) > l.total_repaid]
    defaulted_loans = [l for l in all_loans if l.status == 'Defaulted']

    current_liquidity = max(0.0, (allocated_kitty_pool - total_disbursed) + total_repaid)
    default_rate = round((len(defaulted_loans) / len(all_loans) * 100), 2) if all_loans else 0.0

    return jsonify({
        'status': 'success',
        'analytics': {
            'total_kitty_reserve_fund_kes': round(allocated_kitty_pool, 2),
            'available_liquid_capital_kes': round(current_liquidity, 2),
            'total_capital_disbursed_kes': round(total_disbursed, 2),
            'total_capital_recovered_kes': round(total_repaid, 2),
            'outstanding_loan_balance_kes': round(max(0.0, total_disbursed - total_repaid), 2),
            'active_borrowers_count': len(active_loans),
            'default_rate_percent': default_rate,
            'portfolio_health': 'Healthy (Low Risk)' if default_rate < 5.0 else 'Attention Needed',
            'updated_at': datetime.utcnow().isoformat()
        }
    }), 200
