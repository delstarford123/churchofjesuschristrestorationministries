import uuid
from datetime import datetime
from flask import Blueprint, request, jsonify
from app.models import db, LoanApplication, LoanRepayment, User
from app.services.auth_service import token_required, roles_required
from app.services.email_service import EmailService

loans_bp = Blueprint('loans_bp', __name__, url_prefix='/api/v1/loans')

@loans_bp.route('/apply', methods=['POST'])
def apply_stewardship_loan():
    """
    Apply for a Stewardship Kitty loan.
    Can be called directly online or flushed from the Flutter offline queue.
    Prevents duplicates using client_loan_id.
    """
    data = request.get_json() or {}
    
    required = ['member_id', 'member_name', 'amount_requested', 'repayment_period_months', 'guarantor_phone']
    missing = [f for f in required if not data.get(f)]
    if missing:
        return jsonify({
            'status': 'error',
            'message': f"Missing required loan application fields: {', '.join(missing)}"
        }), 400

    client_loan_id = data.get('client_loan_id')
    if client_loan_id:
        existing = LoanApplication.query.filter_by(client_loan_id=client_loan_id).first()
        if existing:
            return jsonify({
                'status': 'success',
                'message': 'Loan application already recorded (idempotent sync).',
                'loan_id': existing.loan_id,
                'data': existing.to_dict()
            }), 200

    loan_id = f"SK-{str(uuid.uuid4())[:8].upper()}"

    applied_at = datetime.utcnow()
    raw_applied = data.get('applied_at')
    if raw_applied:
        try:
            applied_at = datetime.fromisoformat(raw_applied.replace('Z', '+00:00'))
        except Exception:
            pass

    loan_app = LoanApplication(
        loan_id=loan_id,
        client_loan_id=client_loan_id,
        member_id=data['member_id'],
        member_name=data['member_name'],
        member_email=data.get('member_email'),
        member_phone=data.get('member_phone'),
        amount_requested=float(data['amount_requested']),
        amount_approved=None,
        repayment_period_months=int(data['repayment_period_months']),
        guarantor_name=data.get('guarantor_name'),
        guarantor_phone=data['guarantor_phone'],
        purpose=data.get('purpose', 'General Development'),
        status='Pending_Executive_Review',
        applied_at=applied_at
    )

    db.session.add(loan_app)
    db.session.commit()

    # Send confirmation notice if email provided
    if loan_app.member_email:
        try:
            EmailService.send_loan_submission_notice(
                loan_app.member_email,
                loan_app.member_name,
                loan_id,
                loan_app.amount_requested,
                loan_app.repayment_period_months
            )
        except Exception:
            pass

    return jsonify({
        'status': 'success',
        'message': 'Stewardship Kitty loan application submitted successfully.',
        'loan_id': loan_id,
        'data': loan_app.to_dict()
    }), 201


@loans_bp.route('/pending', methods=['GET'])
@token_required
@roles_required('Executive Director', 'Super Admin')
def get_pending_loans(current_user):
    """
    Executive Directors endpoint to monitor and review applications awaiting approval.
    """
    pending = LoanApplication.query.filter_by(status='Pending_Executive_Review')\
        .order_by(LoanApplication.applied_at.desc()).all()
    
    return jsonify({
        'status': 'success',
        'count': len(pending),
        'loans': [loan.to_dict() for loan in pending]
    }), 200


@loans_bp.route('/all', methods=['GET'])
@token_required
@roles_required('Executive Director', 'Super Admin', 'Elder')
def get_all_loans(current_user):
    """List all loans across the church portfolio."""
    status_filter = request.args.get('status')
    query = LoanApplication.query
    if status_filter:
        query = query.filter_by(status=status_filter)

    loans = query.order_by(LoanApplication.applied_at.desc()).all()
    return jsonify({
        'status': 'success',
        'count': len(loans),
        'loans': [loan.to_dict() for loan in loans]
    }), 200


@loans_bp.route('/my-loans', methods=['GET'])
@token_required
def get_my_loans(current_user):
    """View loan applications and repayment status for the current user."""
    loans = LoanApplication.query.filter_by(member_id=current_user.member_id)\
        .order_by(LoanApplication.applied_at.desc()).all()

    return jsonify({
        'status': 'success',
        'count': len(loans),
        'loans': [l.to_dict() for l in loans]
    }), 200


@loans_bp.route('/<string:loan_id>', methods=['GET'])
@token_required
def get_loan_detail(current_user, loan_id):
    """Fetch loan details along with repayment history."""
    loan = LoanApplication.query.filter_by(loan_id=loan_id).first()
    if not loan:
        return jsonify({'status': 'error', 'message': 'Loan application not found.'}), 404

    # Authorization: only loan owner, Executive Director, or Super Admin can view
    if loan.member_id != current_user.member_id and current_user.role not in ['Executive Director', 'Super Admin']:
        return jsonify({'status': 'error', 'message': 'Unauthorized to view this loan application.'}), 403

    repayments = [r.to_dict() for r in loan.repayments]
    loan_dict = loan.to_dict()
    loan_dict['repayments'] = repayments

    return jsonify({
        'status': 'success',
        'loan': loan_dict
    }), 200


@loans_bp.route('/<string:loan_id>/review', methods=['PUT'])
@token_required
@roles_required('Executive Director', 'Super Admin')
def review_loan_application(current_user, loan_id):
    """
    Executive Director endpoint to approve or reject a loan application 
    and trigger automated email notification to member.
    """
    data = request.get_json() or {}
    action = data.get('action') # 'approve' or 'reject'
    director_name = data.get('director_name') or current_user.full_name
    notes = data.get('notes', '')
    approved_amount = data.get('amount_approved')

    if action not in ['approve', 'reject']:
        return jsonify({'status': 'error', 'message': "Invalid action. Must be 'approve' or 'reject'."}), 400

    loan = LoanApplication.query.filter_by(loan_id=loan_id).first()
    if not loan:
        return jsonify({'status': 'error', 'message': 'Loan application not found.'}), 404

    loan.status = 'Approved' if action == 'approve' else 'Rejected'
    loan.reviewed_by = director_name
    loan.review_notes = notes
    loan.reviewed_at = datetime.utcnow()
    
    if action == 'approve':
        loan.amount_approved = float(approved_amount) if approved_amount else loan.amount_requested

    db.session.commit()

    # Trigger email notification
    target_email = loan.member_email
    if not target_email:
        # Check user table by member_id
        user = User.query.filter_by(member_id=loan.member_id).first()
        if user:
            target_email = user.email

    if target_email:
        try:
            EmailService.send_loan_status_email(
                member_email=target_email,
                member_name=loan.member_name,
                loan_id=loan.loan_id,
                status=loan.status,
                director_name=director_name,
                review_notes=notes
            )
        except Exception:
            pass

    return jsonify({
        'status': 'success',
        'message': f"Loan {loan_id} has been {loan.status.lower()}.",
        'loan': loan.to_dict()
    }), 200


@loans_bp.route('/<string:loan_id>/repay', methods=['POST'])
@token_required
def record_loan_repayment(current_user, loan_id):
    """Record a repayment installment towards an approved loan."""
    loan = LoanApplication.query.filter_by(loan_id=loan_id).first()
    if not loan:
        return jsonify({'status': 'error', 'message': 'Loan not found.'}), 404

    if loan.status != 'Approved':
        return jsonify({'status': 'error', 'message': f"Cannot repay loan in '{loan.status}' status."}), 400

    data = request.get_json() or {}
    amount = float(data.get('amount', 0))
    if amount <= 0:
        return jsonify({'status': 'error', 'message': 'Repayment amount must be greater than zero.'}), 400

    repay_id = f"REP-{uuid.uuid4().hex[:8].upper()}"
    repayment = LoanRepayment(
        repayment_id=repay_id,
        loan_application_id=loan.id,
        loan_id=loan.loan_id,
        amount=amount,
        mpesa_receipt=data.get('mpesa_receipt'),
        paid_by=current_user.full_name,
        notes=data.get('notes')
    )

    loan.total_repaid = (loan.total_repaid or 0.0) + amount
    principal = loan.amount_approved or loan.amount_requested
    if loan.total_repaid >= principal:
        loan.status = 'Repaid'

    db.session.add(repayment)
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': f"Repayment of KES {amount:,.2f} recorded.",
        'repayment': repayment.to_dict(),
        'remaining_balance': max(0.0, principal - loan.total_repaid),
        'loan_status': loan.status
    }), 201
