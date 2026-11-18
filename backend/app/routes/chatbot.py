from flask import Blueprint, request, jsonify
from datetime import datetime

chatbot_bp = Blueprint('chatbot_bp', __name__, url_prefix='/api/v1/chat')

# Knowledge base for RLDS Church Digital Assistant
CHURCH_KB = [
    {
        'keywords': ['loan', 'stewardship kitty', 'borrow', 'kitty', 'apply loan', 'interest', 'guarantor'],
        'response': (
            "🏛️ **RLDS Stewardship Kitty Guidelines:**\n\n"
            "• **Eligibility:** Open to active church members in good standing for at least 3 months.\n"
            "• **Application:** Apply directly in the app (even offline!). Once online, it syncs to the Executive Board.\n"
            "• **Guarantor:** A valid church member phone number is required as a guarantor.\n"
            "• **Approval Workflow:** Reviewed and approved exclusively by the Executive Directors.\n"
            "• **Repayment:** Track your remaining balance and log repayments via M-Pesa."
        )
    },
    {
        'keywords': ['tithe', 'offering', 'give', 'sadaka', 'mpesa', 'paybill', 'payment'],
        'response': (
            "🙏 **Tithes & Offerings Information:**\n\n"
            "• **M-Pesa Contribution:** You can give via STK Push or manual M-Pesa receipt entry.\n"
            "• **Offline-First Giving:** If you have no internet at church, enter your contribution details. The app queues your receipt offline and syncs automatically when connection returns.\n"
            "• **Categories:** Tithes (10%), Thanksgiving, Building Fund, Missions, Sunday School.\n"
            "• **Official Receipts:** Automated digital receipts are dispatched to your registered email immediately upon sync."
        )
    },
    {
        'keywords': ['service', 'time', 'program', 'sunday', 'fellowship', 'wednesday', 'youth'],
        'response': (
            "⛪ **Worship Service Schedule:**\n\n"
            "• **Sunday Sanctuary Service:** 10:00 AM – 1:00 PM\n"
            "• **Sunday School & Teens:** 9:00 AM – 10:00 AM\n"
            "• **Wednesday Midweek Word & Prayer:** 6:00 PM – 7:30 PM (Sanctuary & Online)\n"
            "• **Saturday Youth Ministry Fellowship:** 3:00 PM – 5:00 PM"
        )
    },
    {
        'keywords': ['register', 'join', 'membership', 'account', 'sign up'],
        'response': (
            "📝 **Member Registration Guide:**\n\n"
            "1. Tap 'Register' on the app welcome screen.\n"
            "2. Provide your Full Name, Email, Mobile Phone, and select your Department (General Congregation, Youth, Women, Men, Choir).\n"
            "3. An official RLDS Member ID will be generated for your digital sanctuary pass."
        )
    },
    {
        'keywords': ['leadership', 'pastor', 'elder', 'deacon', 'director', 'contact'],
        'response': (
            "🤝 **Church Leadership & Contact:**\n\n"
            "• **Pastoral Team:** Available for spiritual counsel, prayer, and home visits.\n"
            "• **Deacons Ministry:** Community welfare, benevolent needs, and ushering.\n"
            "• **Executive Directors:** Stewardship Kitty governance and financial administration.\n"
            "• **Sanctuary Secretariat:** The Church of Jesus Christ Restoration Ministry Digital Office."
        )
    }
]

@chatbot_bp.route('/message', methods=['POST'])
def send_chat_message():
    """Support & Registration Assistant chatbot endpoint."""
    data = request.get_json() or {}
    user_message = data.get('message', '').strip().lower()

    if not user_message:
        return jsonify({'status': 'error', 'message': 'Message cannot be empty.'}), 400

    reply = None
    for item in CHURCH_KB:
        if any(kw in user_message for kw in item['keywords']):
            reply = item['response']
            break

    if not reply:
        reply = (
            "Welcome to **The Church of Jesus Christ Restoration Ministry (RLDS Church)** assistant. "
            "I can assist you with:\n"
            "1. 💰 Stewardship Kitty Loan applications & eligibility\n"
            "2. 🙏 Giving Tithes, Offerings & Offline Sync\n"
            "3. ⛪ Service schedules & fellowships\n"
            "4. 📝 Member registration & department assignment\n\n"
            "How can I help you today?"
        )

    return jsonify({
        'status': 'success',
        'reply': reply,
        'timestamp': datetime.utcnow().isoformat()
    }), 200
