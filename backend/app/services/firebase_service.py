import os
import json
import logging
from datetime import datetime, timezone

logger = logging.getLogger('rlds_church.firebase')

_firestore_client = None
_firebase_initialized = False

def init_firebase():
    global _firestore_client, _firebase_initialized
    if _firebase_initialized:
        return _firestore_client

    try:
        import firebase_admin
        from firebase_admin import credentials, firestore

        cred = None
        # 1. Check for serviceAccountKey.json in workspace or backend directory
        possible_paths = [
            'serviceAccountKey.json',
            os.path.join(os.path.dirname(__file__), '..', '..', '..', 'serviceAccountKey.json'),
            os.path.join(os.path.dirname(__file__), '..', '..', 'serviceAccountKey.json'),
            os.path.join(os.getcwd(), 'serviceAccountKey.json')
        ]

        for path in possible_paths:
            if os.path.exists(path):
                logger.info(f"Loading Firebase credentials from file: {path}")
                cred = credentials.Certificate(path)
                break

        # 2. Check for environment variable
        if cred is None and os.environ.get('FIREBASE_SERVICE_ACCOUNT_JSON'):
            sa_info = json.loads(os.environ['FIREBASE_SERVICE_ACCOUNT_JSON'])
            cred = credentials.Certificate(sa_info)

        # 3. Check for default credentials
        if cred is None:
            try:
                cred = credentials.ApplicationDefault()
            except Exception:
                pass

        if cred:
            if not firebase_admin._apps:
                firebase_admin.initialize_app(cred, {
                    'projectId': 'rlds-89374'
                })
            _firestore_client = firestore.client()
            _firebase_initialized = True
            logger.info("Firebase Admin & Firestore successfully initialized for project rlds-89374")
        else:
            logger.warning("No Firebase credentials located. Firestore syncing disabled.")

    except Exception as e:
        logger.error(f"Failed to initialize Firebase Admin: {e}")
        _firestore_client = None

    return _firestore_client

def get_firestore_client():
    if not _firebase_initialized:
        return init_firebase()
    return _firestore_client

def sync_tithe_to_firestore(tithe_dict):
    """Dual-writes a tithe payment or pledge record to Cloud Firestore."""
    client = get_firestore_client()
    if not client:
        return False
    try:
        doc_id = str(tithe_dict.get('receipt_number') or tithe_dict.get('id') or f"tithe_{int(datetime.now(timezone.utc).timestamp())}")
        payload = {
            'user_id': str(tithe_dict.get('user_id', '')),
            'member_id': tithe_dict.get('member_id', ''),
            'amount': float(tithe_dict.get('amount', 0.0)),
            'category': tithe_dict.get('category', 'Tithe'),
            'payment_method': tithe_dict.get('payment_method', 'M-Pesa'),
            'receipt_number': tithe_dict.get('receipt_number', ''),
            'mpesa_transaction_id': tithe_dict.get('mpesa_transaction_id', ''),
            'is_anonymous': bool(tithe_dict.get('is_anonymous', False)),
            'status': tithe_dict.get('status', 'completed'),
            'updated_at': datetime.now(timezone.utc).isoformat()
        }
        client.collection('tithes').document(doc_id).set(payload, merge=True)
        return True
    except Exception as e:
        logger.error(f"Error syncing tithe to Firestore: {e}")
        return False

def sync_loan_to_firestore(loan_dict):
    """Dual-writes a Stewardship Kitty loan record to Cloud Firestore."""
    client = get_firestore_client()
    if not client:
        return False
    try:
        doc_id = f"loan_{loan_dict.get('id') or loan_dict.get('loan_id', 'new')}"
        payload = {
            'user_id': str(loan_dict.get('user_id', '')),
            'member_id': loan_dict.get('member_id', ''),
            'amount': float(loan_dict.get('amount', 0.0)),
            'purpose': loan_dict.get('purpose', ''),
            'guarantor_uid': str(loan_dict.get('guarantor_uid', '')),
            'guarantor_phone': loan_dict.get('guarantor_phone', ''),
            'guarantor_status': loan_dict.get('guarantor_status', 'pending'),
            'status': loan_dict.get('status', 'pending'),
            'ai_credit_score': loan_dict.get('ai_credit_score'),
            'updated_at': datetime.now(timezone.utc).isoformat()
        }
        client.collection('loans').document(doc_id).set(payload, merge=True)
        return True
    except Exception as e:
        logger.error(f"Error syncing loan to Firestore: {e}")
        return False

def sync_announcement_to_firestore(announcement_dict):
    """Dual-writes a church announcement to Cloud Firestore."""
    client = get_firestore_client()
    if not client:
        return False
    try:
        doc_id = f"announcement_{announcement_dict.get('id', 'item')}"
        payload = {
            'title': announcement_dict.get('title', ''),
            'content': announcement_dict.get('content', ''),
            'category': announcement_dict.get('category', 'General'),
            'target_role': announcement_dict.get('target_role', 'All'),
            'priority': announcement_dict.get('priority', 'Normal'),
            'author': announcement_dict.get('author', 'Church Secretariat'),
            'updated_at': datetime.now(timezone.utc).isoformat()
        }
        client.collection('announcements').document(doc_id).set(payload, merge=True)
        return True
    except Exception as e:
        logger.error(f"Error syncing announcement to Firestore: {e}")
        return False
