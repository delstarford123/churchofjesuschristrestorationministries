from flask import Blueprint, request, jsonify
from datetime import datetime, date, timedelta
import uuid
from app.models import (
    db, PriesthoodLineage, SacramentVisitation, AnniversaryBlessing,
    HymnalSong, MarriageRegistry, SundaySchoolBadge, PrayerRequestWall,
    FinancialTransparencyReport, EmergencyBenevolenceAlert, DevotionalPlan,
    AssetInventoryTag, BaptismalCertificate, CellGroup, AudioSermon,
    YouthMentorshipProfile, ChildPickupSecurity, PledgeCampaign,
    CounselingAppointment, CouncilElection
)

ministry_bp = Blueprint('ministry_bp', __name__, url_prefix='/api/v1/ministry')

@ministry_bp.before_request
def ensure_tables():
    try:
        db.create_all()
    except Exception:
        pass

# 1. PRIESTHOOD LINEAGE
@ministry_bp.route('/priesthood/lineage', methods=['GET'])
def get_priesthood_lineages():
    records = PriesthoodLineage.query.all()
    if not records:
        # Seed initial sample for Kakamega elders
        sample = PriesthoodLineage(
            member_id='RLDS-2026-1001',
            minister_name='Pastor Samuel Makokha',
            priesthood_office='Elder & Pastor',
            ordained_by='High Priest Josephat Barasa',
            ordination_date=date(2018, 5, 12),
            quorum='Pastors & Elders Quorum',
            certificate_number='RLDS-ORD-2018-042',
            lineage_notes='Ordained under the hands of the Presiding Quorum of High Priests.'
        )
        db.session.add(sample)
        db.session.commit()
        records = [sample]
    return jsonify({'status': 'success', 'records': [r.to_dict() for r in records]}), 200

# 2. SACRAMENT SICK VISITATION
@ministry_bp.route('/visitations', methods=['GET'])
def get_visitations():
    records = SacramentVisitation.query.order_by(SacramentVisitation.visit_date.desc()).all()
    if not records:
        sample_v = SacramentVisitation(
            member_id='RLDS-2026-1092',
            member_name='Sister Martha Nakhumicha (Lurambi)',
            home_address='Lurambi Sub-county',
            visiting_deacon_or_elder='Deaconess Mary Namalwa',
            welfare_needs='Food basket delivered and prescription assistance',
            prayer_requests='Healing, fellowship & Holy Communion administered'
        )
        db.session.add(sample_v)
        db.session.commit()
        records = [sample_v]
    return jsonify({'status': 'success', 'records': [r.to_dict() for r in records]}), 200

@ministry_bp.route('/visitations', methods=['POST'])
def add_visitation():
    data = request.get_json() or {}
    record = SacramentVisitation(
        member_id=data.get('member_id', 'RLDS-MEM-GEN'),
        member_name=data.get('member_name', 'Elderly Church Member'),
        home_address=data.get('home_address', 'Lurambi Sub-county'),
        visiting_deacon_or_elder=data.get('visiting_minister', 'Deacon Board'),
        welfare_needs=data.get('welfare_needs', 'Food basket & prescription assistance'),
        prayer_requests=data.get('prayer_requests', 'Healing & peace')
    )
    db.session.add(record)
    db.session.commit()
    return jsonify({'status': 'success', 'record': record.to_dict()}), 201

# 3. ANNIVERSARY BLESSINGS
@ministry_bp.route('/anniversaries', methods=['GET'])
def get_anniversaries():
    records = AnniversaryBlessing.query.all()
    return jsonify({'status': 'success', 'anniversaries': [r.to_dict() for r in records]}), 200

# 4. RESTORATION HYMNAL
@ministry_bp.route('/hymnal', methods=['GET'])
def get_hymnal():
    hymns = HymnalSong.query.order_by(HymnalSong.hymn_number.asc()).all()
    if not hymns:
        sample_hymns = [
            HymnalSong(
                hymn_number=1,
                title_en='The Spirit of God Like a Fire Is Burning',
                title_sw='Roho wa Mungu Kama Moto Unawaka',
                lyrics_en='The Spirit of God like a fire is burning! The latter-day glory begins to come forth.',
                lyrics_sw='Roho wa Mungu kama moto unawaka! Utukufu wa siku za mwisho umeanza kuja.',
                key_signature='B Flat Major',
                category='Restoration & Pentecost'
            ),
            HymnalSong(
                hymn_number=2,
                title_en='Redeemer of Israel',
                title_sw='Mkombozi wa Israeli',
                lyrics_en='Redeemer of Israel, our only delight, on whom for a blessing we call.',
                lyrics_sw='Mkombozi wa Israeli, furaha yetu pekee, ambaye kwake twaita baraka.',
                key_signature='E Flat Major',
                category='Gathering of Zion'
            ),
            HymnalSong(
                hymn_number=3,
                title_en='Now Let Us Rejoice',
                title_sw='Sasa Tufurahi',
                lyrics_en='Now let us rejoice in the day of salvation; No longer as strangers on earth need we roam.',
                lyrics_sw='Sasa tufurahi katika siku ya wokovu; Si wageni tena duniani twazurura.',
                key_signature='G Major',
                category='Praise & Consecration'
            )
        ]
        for h in sample_hymns:
            db.session.add(h)
        db.session.commit()
        hymns = sample_hymns
    return jsonify({'status': 'success', 'hymns': [h.to_dict() for h in hymns]}), 200

# 6. MARRIAGE REGISTRY
@ministry_bp.route('/marriage-registry', methods=['GET'])
def get_marriage_records():
    records = MarriageRegistry.query.order_by(MarriageRegistry.wedding_date.desc()).all()
    if not records:
        sample_m = MarriageRegistry(
            certificate_number='RLDS-MAR-2026-08',
            groom_name='Brother David Omondi',
            bride_name='Sister Grace Auma',
            wedding_date=date(2026, 4, 18),
            officiant_elder='Pastor Samuel Makokha',
            assembly_location='Kakamega Central Cathedral',
            premarital_counseling_completed=True
        )
        db.session.add(sample_m)
        db.session.commit()
        records = [sample_m]
    return jsonify({'status': 'success', 'marriages': [r.to_dict() for r in records]}), 200

@ministry_bp.route('/marriage-registry', methods=['POST'])
def add_marriage_record():
    data = request.get_json() or {}
    record = MarriageRegistry(
        certificate_number=f"RLDS-MAR-{uuid.uuid4().hex[:6].upper()}",
        groom_name=data.get('groom_name', ''),
        bride_name=data.get('bride_name', ''),
        wedding_date=date.today(),
        officiant_elder=data.get('officiant_elder', 'Pastor Samuel Makokha'),
        assembly_location=data.get('assembly_location', 'Kakamega Central Cathedral'),
        premarital_counseling_completed=True
    )
    db.session.add(record)
    db.session.commit()
    return jsonify({'status': 'success', 'record': record.to_dict()}), 201

# 7. SUNDAY SCHOOL BADGES
@ministry_bp.route('/sunday-school/badges', methods=['GET'])
def get_badges():
    badges = SundaySchoolBadge.query.all()
    return jsonify({'status': 'success', 'badges': [b.to_dict() for b in badges]}), 200

# 8. PRAYER REQUEST WALL
@ministry_bp.route('/prayer-wall', methods=['GET'])
def get_prayer_wall():
    is_pastor = request.args.get('is_pastor', 'false').lower() == 'true'
    if is_pastor:
        prayers = PrayerRequestWall.query.order_by(PrayerRequestWall.created_at.desc()).all()
    else:
        prayers = PrayerRequestWall.query.filter_by(is_confidential=False).order_by(PrayerRequestWall.created_at.desc()).all()
    if not prayers:
        sample_p = PrayerRequestWall(
            member_id='RLDS-2026-1044',
            requester_name='Sister Mary Nakhumicha',
            is_confidential=False,
            title='Healing & Divine Protection',
            request_text='Praying for divine health and strength upon all mothers and children in Malava and Lurambi assemblies.'
        )
        db.session.add(sample_p)
        db.session.commit()
        prayers = [sample_p]
    return jsonify({'status': 'success', 'prayers': [p.to_dict() for p in prayers]}), 200

@ministry_bp.route('/prayer-wall', methods=['POST'])
def submit_prayer():
    data = request.get_json() or {}
    prayer = PrayerRequestWall(
        member_id=data.get('member_id', 'RLDS-MEM-GEN'),
        requester_name=data.get('name', 'Anonymous Believer'),
        is_confidential=bool(data.get('is_confidential', False)),
        title=data.get('title', 'Prayer Request'),
        request_text=data.get('request_text', '')
    )
    db.session.add(prayer)
    db.session.commit()
    return jsonify({'status': 'success', 'prayer': prayer.to_dict()}), 201

# 9. FINANCIAL TRANSPARENCY REPORTS
@ministry_bp.route('/transparency-reports', methods=['GET'])
def get_transparency_reports():
    reports = FinancialTransparencyReport.query.order_by(FinancialTransparencyReport.published_at.desc()).all()
    if not reports:
        sample_report = FinancialTransparencyReport(
            quarter='Q3 2026',
            total_tithes=3450000.0,
            benevolence_spent=680000.0,
            evangelism_spent=520000.0,
            sanctuary_building_spent=1250000.0,
            stewardship_kitty_reserve=1000000.0,
            summary_notes='Approved by the General Bishopric. 100% of benevolence funds were directed toward widows, hospital benevolence, and Sunday school support.'
        )
        db.session.add(sample_report)
        db.session.commit()
        reports = [sample_report]
    return jsonify({'status': 'success', 'reports': [r.to_dict() for r in reports]}), 200

# 10. EMERGENCY BENEVOLENCE ALERTS
@ministry_bp.route('/emergency-alerts', methods=['GET'])
def get_emergency_alerts():
    alerts = EmergencyBenevolenceAlert.query.filter_by(is_active=True).all()
    return jsonify({'status': 'success', 'alerts': [a.to_dict() for a in alerts]}), 200

# 11. DAILY DEVOTIONALS & FASTING
@ministry_bp.route('/devotionals/daily', methods=['GET'])
def get_daily_devotional():
    today = date.today()
    devotional = DevotionalPlan.query.filter_by(day_date=today).first()
    if not devotional:
        devotional = DevotionalPlan(
            day_date=today,
            title='Building Zion: One Heart, One Mind',
            iv_scripture_reference='Genesis 7:23 (IV)',
            bom_reference='Mosiah 4:16',
            pastoral_reflection='True discipleship is measured by our readiness to succor those in need. In Zion, no one suffers alone; our stewardship joins us in divine fellowship.',
            fasting_guideline='Wednesday Restoration Fast: Abstain until 3:00 PM for the sick and widows.'
        )
        db.session.add(devotional)
        db.session.commit()
    return jsonify({'status': 'success', 'devotional': devotional.to_dict()}), 200

# 12. ASSET INVENTORY TAGS
@ministry_bp.route('/assets/tags', methods=['GET'])
def get_asset_tags():
    tags = AssetInventoryTag.query.all()
    return jsonify({'status': 'success', 'assets': [t.to_dict() for t in tags]}), 200

# 13. BAPTISMAL CERTIFICATES
@ministry_bp.route('/baptism-certificates/<member_id>', methods=['GET'])
def get_baptism_certificate(member_id):
    cert = BaptismalCertificate.query.filter_by(member_id=member_id).first()
    if not cert:
        cert = BaptismalCertificate(
            certificate_hash=f"RLDS-BAP-{member_id[-4:]}",
            member_id=member_id,
            candidate_name='Member of the Restoration',
            baptism_date=date(2026, 1, 15),
            baptizing_elder='Elder Josephat Barasa',
            confirming_elder='Pastor Samuel Makokha'
        )
        db.session.add(cert)
        db.session.commit()
    return jsonify({'status': 'success', 'certificate': cert.to_dict()}), 200

# 14. CELL GROUPS
@ministry_bp.route('/cell-groups', methods=['GET'])
def get_cell_groups():
    groups = CellGroup.query.all()
    if not groups:
        sample_groups = [
            CellGroup(group_name='Kakamega Central Shalom Cell', neighborhood_area='Kakamega Town / Amalemba', host_family='Brother & Sister Makokha', meeting_day_time='Tuesdays 5:30 PM', leader_elder='Elder Josephat Barasa', contact_phone='+254712000001', active_members_count=24),
            CellGroup(group_name='Lurambi Ebenezer Fellowship', neighborhood_area='Lurambi Sub-county', host_family='Brother Timothy Shikuku', meeting_day_time='Thursdays 6:00 PM', leader_elder='Pastor Timothy Wekesa', contact_phone='+254712000002', active_members_count=18),
            CellGroup(group_name='Malava Zion Fellowship', neighborhood_area='Malava Market', host_family='Sister Grace Auma', meeting_day_time='Tuesdays 5:00 PM', leader_elder='Elder David Otieno', contact_phone='+254712000003', active_members_count=15)
        ]
        for g in sample_groups:
            db.session.add(g)
        db.session.commit()
        groups = sample_groups
    return jsonify({'status': 'success', 'cell_groups': [g.to_dict() for g in groups]}), 200

# 15. AUDIO SERMONS
@ministry_bp.route('/sermons', methods=['GET'])
def get_sermons():
    sermons = AudioSermon.query.order_by(AudioSermon.preach_date.desc()).all()
    if not sermons:
        sample_sermon = AudioSermon(
            title='The Law of Consecration and Divine Stewardship',
            preacher='Pastor Samuel Makokha',
            scripture_reference='Mosiah 4:16-24 & IV Genesis 7',
            preach_date=date.today() - timedelta(days=3),
            duration_minutes=42,
            audio_file_url='https://rlds-church-backend.vercel.app/static/sermons/sermon_01.mp3',
            summary_notes='A profound doctrinal sermon addressing the biblical mandate of the Stewardship Kitty, consecration of surplus, and the spiritual joy of joyful giving.'
        )
        db.session.add(sample_sermon)
        db.session.commit()
        sermons = [sample_sermon]
    return jsonify({'status': 'success', 'sermons': [s.to_dict() for s in sermons]}), 200

# 16. YOUTH MENTORSHIP
@ministry_bp.route('/youth-mentorship', methods=['GET'])
def get_mentors():
    mentors = YouthMentorshipProfile.query.all()
    if not mentors:
        sample_mentors = [
            YouthMentorshipProfile(mentor_name='Eng. Derrick Ochieng', profession='Civil & Structural Engineering', organization='National Infrastructure Council', phone_contact='+254700111222', email='derrick@rldschurch.org', available_mentee_slots=2, bio='Passionate about guiding youth into engineering and ethical technology.'),
            YouthMentorshipProfile(mentor_name='Dr. Grace Wanjiku', profession='Medicine & Public Health', organization='Kakamega General Hospital', phone_contact='+254700333444', email='grace.wanjiku@rldschurch.org', available_mentee_slots=3, bio='Mentoring young men and women pursuing nursing, pharmacy, and medicine.')
        ]
        for m in sample_mentors:
            db.session.add(m)
        db.session.commit()
        mentors = sample_mentors
    return jsonify({'status': 'success', 'mentors': [m.to_dict() for m in mentors]}), 200

# 17. CHILD PICKUP SECURITY
@ministry_bp.route('/child-pickup/verify', methods=['POST'])
def verify_child_pickup():
    data = request.get_json() or {}
    pin = data.get('pin')
    token = data.get('token')
    child = ChildPickupSecurity.query.filter_by(one_time_pin=pin).first()
    if child:
        child.is_released = True
        child.released_at = datetime.utcnow()
        child.verified_by_teacher = data.get('teacher_name', 'Presiding Sunday School Teacher')
        db.session.commit()
        return jsonify({'status': 'verified', 'child_name': child.child_name, 'message': 'Pickup authorized'}), 200
    return jsonify({'status': 'denied', 'message': 'Invalid pickup code. Child security lock active.'}), 403

# 18. MULTI-PLEDGE CAMPAIGNS
@ministry_bp.route('/pledge-campaigns', methods=['GET'])
def get_pledge_campaigns():
    campaigns = PledgeCampaign.query.all()
    if not campaigns:
        sample_c = [
            PledgeCampaign(campaign_name='Kakamega Central Cathedral Expansion', target_amount=5000000.0, raised_amount=3200000.0, deadline_date=date(2026, 12, 31), description='Expanding the sanctuary seating capacity to 1,200 seats.', total_pledgers=142),
            PledgeCampaign(campaign_name='Malava Outreach Center Sanctuary Land', target_amount=1500000.0, raised_amount=850000.0, deadline_date=date(2027, 3, 31), description='Acquiring 2 acres of land for church building and community agricultural training.', total_pledgers=78)
        ]
        for c in sample_c:
            db.session.add(c)
        db.session.commit()
        campaigns = sample_c
    return jsonify({'status': 'success', 'campaigns': [c.to_dict() for c in campaigns]}), 200

# 19. COUNSELING APPOINTMENTS
@ministry_bp.route('/counseling/appointments', methods=['POST'])
def book_counseling_appointment():
    data = request.get_json() or {}
    apt = CounselingAppointment(
        member_id=data.get('member_id', 'RLDS-MEM-GEN'),
        member_name=data.get('member_name', 'Church Member'),
        minister_name=data.get('minister_name', 'Pastor Samuel Makokha'),
        appointment_time=datetime.utcnow() + timedelta(days=2),
        session_mode=data.get('session_mode', 'In-Person Sanctuary'),
        counseling_topic=data.get('topic', 'General Pastoral Care & Guidance')
    )
    db.session.add(apt)
    db.session.commit()
    return jsonify({'status': 'success', 'appointment': apt.to_dict()}), 201

# 20. COUNCIL ELECTIONS
@ministry_bp.route('/council/elections', methods=['GET'])
def get_council_elections():
    elections = CouncilElection.query.all()
    if not elections:
        sample_e = CouncilElection(
            election_title='2026 Deacons Board & Welfare Committee Confirmation',
            resolution_details='Approval of Brother Timothy Shikuku and Sister Dorcas Atieno to the Deacons and Welfare Oversight Board for the 2026-2028 term.',
            end_date=datetime.utcnow() + timedelta(days=14),
            total_votes=156,
            yes_votes=148,
            no_votes=8
        )
        db.session.add(sample_e)
        db.session.commit()
        elections = [sample_e]
    return jsonify({'status': 'success', 'elections': [e.to_dict() for e in elections]}), 200
