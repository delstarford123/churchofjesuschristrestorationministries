import uuid
from datetime import datetime
from flask import Blueprint, request, jsonify
from app.models import db, TitheTransaction, User
from app.services.auth_service import token_required, roles_required
from app.services.email_service import EmailService
from app.services.mpesa_service import MpesaService

tithes_bp = Blueprint('tithes_bp', __name__, url_prefix='/api/v1/tithes')

@tithes_bp.route('/sync', methods=['POST'])
def sync_offline_tithes():
    """
    Receives an array of offline-queued tithe transactions from the Flutter app
    when internet connection is restored.
    Prevents duplicate entries using client_transaction_id idempotency.
    """
    data = request.get_json()
    if not data or 'transactions' not in data:
        return jsonify({
            "status": "error",
            "message": "Invalid payload format. Expected 'transactions' array."
        }), 400

    incoming_transactions = data['transactions']
    synced_count = 0
    duplicate_count = 0
    error_count = 0
    synced_records = []

    for tx in incoming_transactions:
        try:
            tx_id = tx.get('client_transaction_id') or f"TX-{uuid.uuid4()}"
            
            # Idempotency check: prevent duplicate insertion
            existing = TitheTransaction.query.filter_by(client_transaction_id=tx_id).first()
            if existing:
                duplicate_count += 1
                continue

            # Parse transaction date if provided
            tx_date_raw = tx.get('transaction_date')
            tx_date = datetime.utcnow()
            if tx_date_raw:
                try:
                    tx_date = datetime.fromisoformat(tx_date_raw.replace('Z', '+00:00'))
                except Exception:
                    pass

            record = TitheTransaction(
                client_transaction_id=tx_id,
                member_id=tx.get('member_id'),
                member_name=tx.get('member_name', 'Anonymous Giver'),
                member_email=tx.get('member_email'),
                amount=float(tx.get('amount', 0)),
                currency=tx.get('currency', 'KES'),
                category=tx.get('category', 'Tithe'),
                mpesa_receipt=tx.get('mpesa_receipt'),
                payment_method=tx.get('payment_method', 'M-Pesa'),
                status='Confirmed',
                transaction_date=tx_date,
                synced_at=datetime.utcnow()
            )

            db.session.add(record)
            synced_records.append(record)
            synced_count += 1
        except Exception:
            error_count += 1

    if synced_count > 0:
        db.session.commit()

        # Dispatch confirmation receipts
        for rec in synced_records:
            if rec.member_email:
                try:
                    EmailService.send_tithe_receipt_email(
                        rec.member_email,
                        rec.member_name,
                        rec.amount,
                        rec.currency,
                        rec.category,
                        rec.mpesa_receipt,
                        rec.client_transaction_id
                    )
                except Exception:
                    pass

    return jsonify({
        "status": "success",
        "message": "Offline tithe queue synchronized successfully.",
        "synced": synced_count,
        "duplicates_skipped": duplicate_count,
        "errors": error_count
    }), 200


@tithes_bp.route('/submit', methods=['POST'])
def submit_single_tithe():
    """Submit a single tithe/offering contribution directly online."""
    data = request.get_json() or {}
    
    required = ['member_name', 'amount', 'category']
    missing = [f for f in required if not data.get(f)]
    if missing:
        return jsonify({'status': 'error', 'message': f"Missing fields: {', '.join(missing)}"}), 400

    tx_id = data.get('client_transaction_id') or f"TX-{int(datetime.utcnow().timestamp()*1000)}"
    
    record = TitheTransaction(
        client_transaction_id=tx_id,
        member_id=data.get('member_id'),
        member_name=data['member_name'],
        member_email=data.get('member_email'),
        amount=float(data['amount']),
        currency=data.get('currency', 'KES'),
        category=data['category'],
        mpesa_receipt=data.get('mpesa_receipt'),
        payment_method=data.get('payment_method', 'M-Pesa'),
        status='Confirmed'
    )
    
    db.session.add(record)
    db.session.commit()

    if record.member_email:
        EmailService.send_tithe_receipt_email(
            record.member_email,
            record.member_name,
            record.amount,
            record.currency,
            record.category,
            record.mpesa_receipt,
            record.client_transaction_id
        )

    return jsonify({
        'status': 'success',
        'message': 'Contribution submitted successfully.',
        'transaction': record.to_dict()
    }), 201


@tithes_bp.route('/history', methods=['GET'])
@token_required
def get_tithe_history(current_user):
    """
    Get contribution records.
    Normal Members see their own contributions.
    Deacons, Pastors, Elders, Executive Directors and Super Admins see church-wide records.
    """
    privileged_roles = ['Deacon', 'Pastor', 'Elder', 'Executive Director', 'Super Admin']
    
    if current_user.role in privileged_roles:
        member_id_filter = request.args.get('member_id')
        query = TitheTransaction.query
        if member_id_filter:
            query = query.filter_by(member_id=member_id_filter)
    else:
        query = TitheTransaction.query.filter_by(member_id=current_user.member_id)

    category = request.args.get('category')
    if category:
        query = query.filter_by(category=category)

    records = query.order_by(TitheTransaction.transaction_date.desc()).limit(100).all()
    total_amount = sum(r.amount for r in records)

    return jsonify({
        'status': 'success',
        'count': len(records),
        'total_amount': total_amount,
        'transactions': [r.to_dict() for r in records]
    }), 200


@tithes_bp.route('/mpesa/stkpush', methods=['POST'])
def initiate_tithe_stk_push():
    """Trigger Daraja M-Pesa STK Push payment to member phone."""
    data = request.get_json() or {}
    phone = data.get('phone_number')
    amount = data.get('amount')
    category = data.get('category', 'Tithe')
    member_name = data.get('member_name', 'Church Member')

    if not phone or not amount:
        return jsonify({'status': 'error', 'message': 'Phone number and amount are required.'}), 400

    ref = f"{category[:4].upper()}-{int(datetime.utcnow().timestamp())%10000}"
    response = MpesaService.initiate_stk_push(phone, float(amount), account_reference=ref, description=f"RLDS {category}")

    return jsonify({
        'status': 'success',
        'mpesa_response': response
    }), 200


@tithes_bp.route('/mpesa/callback', methods=['POST'])
def mpesa_callback():
    """Safaricom Daraja STK Push asynchronous callback webhook."""
    data = request.get_json() or {}
    stk_callback = data.get('Body', {}).get('stkCallback', {})
    
    result_code = stk_callback.get('ResultCode')
    result_desc = stk_callback.get('ResultDesc')
    checkout_id = stk_callback.get('CheckoutRequestID')

    if result_code == 0:
        items = stk_callback.get('CallbackMetadata', {}).get('Item', [])
        receipt = next((i.get('Value') for i in items if i.get('Name') == 'MpesaReceiptNumber'), None)
        amount = next((i.get('Value') for i in items if i.get('Name') == 'Amount'), None)
        phone = next((i.get('Value') for i in items if i.get('Name') == 'PhoneNumber'), None)
        
        # Log successful transaction
        # Match transaction if client registered it
        tx = TitheTransaction.query.filter_by(client_transaction_id=checkout_id).first()
        if tx:
            tx.mpesa_receipt = receipt
            tx.status = 'Confirmed'
            db.session.commit()

    return jsonify({"ResultCode": 0, "ResultDesc": "Callback received successfully"}), 200
