import os
from flask import Flask, jsonify
from flask_cors import CORS
from app.config import Config
from app.models import db, User

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Enable CORS for Flutter mobile clients & web portals
    CORS(app, resources={r"/*": {"origins": "*"}})

    # Initialize extensions
    db.init_app(app)

    # Register API Blueprints
    from app.routes.health import health_bp
    from app.routes.auth import auth_bp
    from app.routes.tithes import tithes_bp
    from app.routes.loans import loans_bp
    from app.routes.announcements import announcements_bp
    from app.routes.chatbot import chatbot_bp
    from app.routes.financials_advanced import financials_bp
    from app.routes.governance_admin import governance_bp
    from app.routes.community_education import community_bp
    from app.routes.smart_tech_events import smart_tech_bp
    from app.routes.ministry_connection import ministry_bp

    app.register_blueprint(health_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(tithes_bp)
    app.register_blueprint(loans_bp)
    app.register_blueprint(announcements_bp)
    app.register_blueprint(chatbot_bp)
    app.register_blueprint(financials_bp)
    app.register_blueprint(governance_bp)
    app.register_blueprint(community_bp)
    app.register_blueprint(smart_tech_bp)
    app.register_blueprint(ministry_bp)

    # Global Error Handlers
    @app.errorhandler(404)
    def resource_not_found(e):
        return jsonify({
            'status': 'error',
            'message': 'Requested API endpoint not found. Refer to GET / for documentation.'
        }), 404

    @app.errorhandler(500)
    def internal_server_error(e):
        return jsonify({
            'status': 'error',
            'message': 'Internal server error occurred. Please try again later.'
        }), 500

    # Auto-create tables and seed initial administrator on first launch
    with app.app_context():
        try:
            db.create_all()
            _seed_initial_admin()
        except Exception as e:
            app.logger.warning(f"Database initialization warning: {str(e)}")

    return app


def _seed_initial_admin():
    """Seed initial Super Admin account if database is fresh."""
    admin_email = os.getenv('INITIAL_ADMIN_EMAIL', 'admin@rldschurch.org')
    if not User.query.filter_by(email=admin_email).first():
        super_admin = User(
            member_id="RLDS-ADM-001",
            full_name="RLDS Executive Administrator",
            email=admin_email,
            phone_number="254700000000",
            role="Super Admin",
            department="Executive Board"
        )
        initial_pw = os.getenv('INITIAL_ADMIN_PASSWORD', 'Restoration2026!')
        super_admin.set_password(initial_pw)
        db.session.add(super_admin)
        db.session.commit()
