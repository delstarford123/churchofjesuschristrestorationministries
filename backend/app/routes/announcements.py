from flask import Blueprint, request, jsonify
from app.models import db, Announcement
from app.services.auth_service import token_required, roles_required

announcements_bp = Blueprint('announcements_bp', __name__, url_prefix='/api/v1/announcements')

@announcements_bp.route('', methods=['GET'])
def get_announcements():
    """Fetch church notices and category-based bulletins."""
    category = request.args.get('category')
    query = Announcement.query

    if category and category.lower() != 'all':
        query = query.filter((Announcement.category == category) | (Announcement.category == 'All'))

    items = query.order_by(Announcement.is_pinned.desc(), Announcement.created_at.desc()).limit(50).all()

    return jsonify({
        'status': 'success',
        'count': len(items),
        'announcements': [item.to_dict() for item in items]
    }), 200


@announcements_bp.route('', methods=['POST'])
@token_required
@roles_required('Pastor', 'Elder', 'Executive Director', 'Super Admin')
def create_announcement(current_user):
    """Publish a new church notice or devotional bulletin."""
    data = request.get_json() or {}
    
    title = data.get('title')
    content = data.get('content')
    if not title or not content:
        return jsonify({'status': 'error', 'message': 'Title and content are required.'}), 400

    announcement = Announcement(
        title=title,
        content=content,
        category=data.get('category', 'All'),
        author=current_user.full_name,
        is_pinned=bool(data.get('is_pinned', False))
    )

    db.session.add(announcement)
    db.session.commit()

    return jsonify({
        'status': 'success',
        'message': 'Announcement published.',
        'announcement': announcement.to_dict()
    }), 201


@announcements_bp.route('/<int:announcement_id>', methods=['DELETE'])
@token_required
@roles_required('Super Admin', 'Pastor')
def delete_announcement(current_user, announcement_id):
    """Delete an announcement."""
    item = Announcement.query.get(announcement_id)
    if not item:
        return jsonify({'status': 'error', 'message': 'Announcement not found.'}), 404

    db.session.delete(item)
    db.session.commit()

    return jsonify({'status': 'success', 'message': 'Announcement deleted.'}), 200
