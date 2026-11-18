from flask import Blueprint, request, jsonify
from datetime import datetime
from app.models import db, User, TitheTransaction, LoanApplication, ChurchBranch

chatbot_bp = Blueprint('chatbot_bp', __name__, url_prefix='/api/v1/chat')

# General Knowledge base for RLDS Church Digital Assistant
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
            "• **Sunday Zion Worship Service:** 10:00 AM – 1:00 PM\n"
            "• **Sunday School & Teens:** 9:00 AM – 10:00 AM\n"
            "• **Wednesday Midweek Word & Prayer:** 6:00 PM – 7:30 PM (Zion Sanctuary & Online)\n"
            "• **Saturday Youth Ministry Fellowship:** 3:00 PM – 5:00 PM"
        )
    },
    {
        'keywords': ['scripture', 'bible', 'inspired version', 'book of mormon', 'verse', 'doctrine'],
        'response': (
            "📖 **Restoration Sacred Scriptures:**\n\n"
            "• **Inspired Version (JST):** Corrected by the Prophet Joseph Smith with restored Genesis passages, Enoch's Zion revelations, and Matthew 24.\n"
            "• **Book of Mormon (Restoration Edition):** Another witness of Jesus Christ from 1 Nephi to Moroni.\n"
            "• **Offline Availability:** All books, chapters, and verses are pre-compiled and indexed locally on your device for instant offline study."
        )
    },
    {
        'keywords': ['register', 'join', 'membership', 'account', 'sign up'],
        'response': (
            "📝 **Member Registration Guide:**\n\n"
            "1. Tap 'Register' on the app welcome screen.\n"
            "2. Provide your Full Name, Email, Mobile Phone, and select your Department (General Congregation, Youth, Women, Men, Choir).\n"
            "3. An official RLDS Member ID will be generated for your digital pass."
        )
    },
    {
        'keywords': ['leadership', 'pastor', 'elder', 'deacon', 'director', 'contact', 'office'],
        'response': (
            "🤝 **Church Leadership & Contact:**\n\n"
            "• **Pastoral Team:** Available for spiritual counsel, prayer, and home visits.\n"
            "• **Deacons Ministry:** Community welfare, benevolent needs, and ushering.\n"
            "• **Executive Directors:** Stewardship Kitty governance and financial administration.\n"
            "• **Zion Secretariat:** The Church of Jesus Christ Restoration Ministry Central Office."
        )
    }
]

@chatbot_bp.route('/message', methods=['POST'])
def send_chat_message():
    """Support & Registration Assistant chatbot endpoint with real user database context."""
    data = request.get_json() or {}
    user_message = data.get('message', '').strip()
    user_message_lower = user_message.lower()
    member_id = data.get('member_id')
    user_email = data.get('email')
    user_phone = data.get('phone')

    if not user_message:
        return jsonify({'status': 'error', 'message': 'Message cannot be empty.'}), 400

    # 1. Lookup user in database if identifiers provided
    user = None
    if member_id:
        user = User.query.filter_by(member_id=member_id).first()
    if not user and user_email:
        user = User.query.filter_by(email=user_email).first()
    if not user and user_phone:
        user = User.query.filter_by(phone_number=user_phone).first()

    # 2. Contextual dynamic user responses
    if user:
        # Check for tithe queries
        if any(kw in user_message_lower for kw in ['my tithe', 'my tithes', 'my contribution', 'how much have i given', 'giving record', 'sadaka yangu', 'my balance']):
            tithes = TitheTransaction.query.filter_by(member_id=user.member_id).all()
            total_amount = sum(t.amount for t in tithes)
            count = len(tithes)
            last_date = tithes[-1].transaction_date.strftime('%d %b %Y') if tithes and tithes[-1].transaction_date else 'N/A'
            last_amount = f"KES {tithes[-1].amount:,.2f}" if tithes else 'KES 0.00'
            return jsonify({
                'status': 'success',
                'reply': (
                    f"🙏 **Personal Tithe & Offering Record for {user.full_name} ({user.member_id}):**\n\n"
                    f"• **Total Recorded Contributions:** KES {total_amount:,.2f}\n"
                    f"• **Number of Transactions:** {count}\n"
                    f"• **Most Recent Contribution:** {last_amount} on {last_date}\n"
                    f"• **Branch Assembly:** {user.branch}\n\n"
                    "May the Lord abundantly bless your faithful stewardship in Zion!"
                ),
                'timestamp': datetime.utcnow().isoformat()
            }), 200

        # Check for loan queries
        if any(kw in user_message_lower for kw in ['my loan', 'loan status', 'kitty balance', 'stewardship balance', 'mkopo wangu']):
            loans = LoanApplication.query.filter_by(member_id=user.member_id).all()
            if loans:
                latest = loans[-1]
                return jsonify({
                    'status': 'success',
                    'reply': (
                        f"🏛️ **Stewardship Kitty Loan Record for {user.full_name}:**\n\n"
                        f"• **Application ID:** {latest.loan_id}\n"
                        f"• **Amount Requested:** KES {latest.amount_requested:,.2f}\n"
                        f"• **Current Status:** {latest.status.upper()}\n"
                        f"• **Repayment Term:** {latest.repayment_period_months} Months\n"
                        f"• **Guarantor Phone:** {latest.guarantor_phone or 'Pending'}\n\n"
                        "You can submit repayments via M-Pesa STK push in the Tithes & Kitty tab."
                    ),
                    'timestamp': datetime.utcnow().isoformat()
                }), 200
            else:
                return jsonify({
                    'status': 'success',
                    'reply': (
                        f"🏛️ **Stewardship Kitty Notice for {user.full_name}:**\n\n"
                        "You currently have no active or pending loan applications in church records. "
                        f"As an active member of **{user.branch}**, you can apply anytime through the 'Stewardship Kitty' tab."
                    ),
                    'timestamp': datetime.utcnow().isoformat()
                }), 200

        # Check for credit score / eligibility
        if any(kw in user_message_lower for kw in ['am i eligible', 'eligibility', 'credit score', 'qualification', 'qualify']):
            tithes = TitheTransaction.query.filter_by(member_id=user.member_id).all()
            score = min(850, 480 + (len(tithes) * 35))
            eligible = len(tithes) >= 3 or score >= 600
            return jsonify({
                'status': 'success',
                'reply': (
                    f"📊 **Stewardship Kitty Eligibility for {user.full_name}:**\n\n"
                    f"• **Member ID:** {user.member_id}\n"
                    f"• **Tithe Consistency:** {len(tithes)} recorded contributions\n"
                    f"• **Calculated Credit Score:** {score}/850 ({'High Confidence' if score >= 700 else 'Moderate'})\n"
                    f"• **Loan Eligibility:** {'✅ Approved for Kitty loans up to KES 60,000' if eligible else '⚠️ Pending: Requires 3 consecutive months of recorded tithes'}\n"
                    f"• **Branch Assembly:** {user.branch}"
                ),
                'timestamp': datetime.utcnow().isoformat()
            }), 200

        # Check for member profile
        if any(kw in user_message_lower for kw in ['who am i', 'my profile', 'my details', 'my id', 'my branch', 'my department']):
            return jsonify({
                'status': 'success',
                'reply': (
                    f"👤 **Church Member Identity Profile:**\n\n"
                    f"• **Full Name:** {user.full_name}\n"
                    f"• **Member ID:** {user.member_id}\n"
                    f"• **Ecclesiastical Role:** {user.role}\n"
                    f"• **Department:** {user.department}\n"
                    f"• **Home Assembly:** {user.branch}\n"
                    f"• **Contact:** {user.phone_number} / {user.email}\n"
                    f"• **Status:** Active Member in Zion"
                ),
                'timestamp': datetime.utcnow().isoformat()
            }), 200

    # 3. Knowledge base fallback
    reply = None
    for item in CHURCH_KB:
        if any(kw in user_message_lower for kw in item['keywords']):
            reply = item['response']
            break

    if not reply:
        greeting_name = f", {user.full_name}" if user else ""
        reply = (
            f"Greetings in Christ{greeting_name}! Welcome to **The Church of Jesus Christ Restoration Ministry (RLDS Church)** assistant. "
            "I can assist you with:\n"
            "1. 💰 Stewardship Kitty Loan status, balances & eligibility\n"
            "2. 🙏 Giving Tithes, Offerings & checking personal records\n"
            "3. ⛪ Worship service schedules & branch locations\n"
            "4. 📖 Restoration Scriptures (Inspired Version & Book of Mormon)\n"
            "5. 📝 Member registration & account management\n\n"
            "How may I serve you today?"
        )

    return jsonify({
        'status': 'success',
        'reply': reply,
        'timestamp': datetime.utcnow().isoformat()
    }), 200
