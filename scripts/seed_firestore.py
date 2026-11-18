import json
import os
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timezone

def seed_firestore():
    print("=== Seeding RLDS Cloud Firestore Collections ===")
    
    cred = credentials.Certificate('serviceAccountKey.json')
    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred, {'projectId': 'rlds-89374'})

    db = firestore.client()
    now_iso = datetime.now(timezone.utc).isoformat()

    # 1. Seed Branches
    print("Seeding Branches collection...")
    branches = [
        {
            "id": "RLDS-BR-01",
            "name": "Kakamega Central Cathedral",
            "county": "Kakamega",
            "pastor_in_charge": "Pastor Samuel Makokha",
            "contact_phone": "+254712000001",
            "address": "Cathedral Way, Kakamega CBD, near Muliro Gardens",
            "latitude": 0.2827,
            "longitude": 34.7519,
            "created_at": now_iso
        },
        {
            "id": "RLDS-BR-02",
            "name": "Lurambi Assembly",
            "county": "Kakamega",
            "pastor_in_charge": "Elder Josephat Barasa",
            "contact_phone": "+254712000002",
            "address": "Lurambi Junction, Kakamega-Webuye Highway",
            "latitude": 0.3012,
            "longitude": 34.7380,
            "created_at": now_iso
        },
        {
            "id": "RLDS-BR-03",
            "name": "Malava Assembly & Outreach Centre",
            "county": "Kakamega",
            "pastor_in_charge": "Pastor Timothy Wekesa",
            "contact_phone": "+254712000003",
            "address": "Malava Market Plaza, Kakamega North",
            "latitude": 0.4483,
            "longitude": 34.8569,
            "created_at": now_iso
        },
        {
            "id": "RLDS-BR-04",
            "name": "Nairobi Metropolitan Fellowship",
            "county": "Nairobi",
            "pastor_in_charge": "Elder David Otieno",
            "contact_phone": "+254712000004",
            "address": "Upper Hill Sanctuary, Nairobi",
            "latitude": -1.286389,
            "longitude": 36.817223,
            "created_at": now_iso
        }
    ]
    for b in branches:
        db.collection("branches").document(b["id"]).set(b, merge=True)
    print(f"-> Seeded {len(branches)} branches.")

    # 2. Seed Channels
    print("Seeding Communication Channels collection...")
    channels = [
        {"id": "general", "name": "Sanctuary General Fellowship", "type": "public", "description": "General fellowship board for all congregation members."},
        {"id": "announcements", "name": "Sacred Announcements & Bulletins", "type": "broadcast", "description": "Official weekly announcements and liturgical schedules."},
        {"id": "youth", "name": "Restoration Youth Ministry", "type": "category", "description": "Youth discussions, youth camps, and sports ministries."},
        {"id": "pastors_elders", "name": "Pastors & Elders Quorum", "type": "restricted", "description": "Restricted ministerial governance and pastoral counseling caucus."},
        {"id": "deacons", "name": "Deacons & Welfare Board", "type": "restricted", "description": "Physical sanctuary inventory, communion logistics, and benevolence."},
        {"id": "women_dorkas", "name": "Women of Zion (Dorkas Ministry)", "type": "category", "description": "Mothers and sisters fellowship, benevolence, and home visitations."},
        {"id": "choir", "name": "Restoration Sanctuary Choir", "type": "category", "description": "Liturgical music, hymn study, and Sunday service song rehearsals."}
    ]
    for c in channels:
        db.collection("channels").document(c["id"]).set(c, merge=True)
    print(f"-> Seeded {len(channels)} channels.")

    # 3. Seed Announcements
    print("Seeding Announcements collection...")
    announcements = [
        {
            "id": "ANN-001",
            "title": "Sabbath Worship & Sacrament of the Lord's Supper",
            "content": "Join us this Sunday at 9:00 AM for spiritual study of the Inspired Version followed by Holy Communion at 10:30 AM.",
            "category": "Liturgy",
            "target_role": "All",
            "priority": "High",
            "author": "Secretariat - Bishop's Office",
            "created_at": now_iso
        },
        {
            "id": "ANN-002",
            "title": "Stewardship Kitty Loan Applications Open (Q4 Cycle)",
            "content": "Members in good standing can apply for micro-enterprise and emergency loans directly in the mobile app. Digital guarantor sign-off required.",
            "category": "Financials",
            "target_role": "Member",
            "priority": "Normal",
            "author": "Stewardship Board",
            "created_at": now_iso
        }
    ]
    for a in announcements:
        db.collection("announcements").document(a["id"]).set(a, merge=True)
    print(f"-> Seeded {len(announcements)} announcements.")

    # 4. Seed Community Projects (FARD CBO)
    print("Seeding Community Outreach Projects collection...")
    projects = [
        {
            "id": "FARD-AGRI-01",
            "title": "FARD CBO Sustainable Agricultural Cooperative",
            "partner_cbo": "FARD CBO Kenya",
            "description": "Providing certified high-yield seeds and organic fertilizers to Kakamega farming families.",
            "beneficiaries": 350,
            "status": "Active",
            "target_budget_kes": 500000.0,
            "raised_budget_kes": 320000.0,
            "created_at": now_iso
        },
        {
            "id": "FARD-YOUTH-02",
            "title": "Youth Digital Literacy & Tech Hub",
            "partner_cbo": "RLDS Youth Ministry & Benevolent Board",
            "description": "Equipping youth with mobile development, graphic design, and ethical AI skills.",
            "beneficiaries": 120,
            "status": "Recruiting",
            "target_budget_kes": 300000.0,
            "raised_budget_kes": 185000.0,
            "created_at": now_iso
        }
    ]
    for p in projects:
        db.collection("community_projects").document(p["id"]).set(p, merge=True)
    print(f"-> Seeded {len(projects)} community projects.")

    print("\n>>> FIRESTORE DATABASE SEEDED SUCCESSFULLY! <<<")

if __name__ == "__main__":
    seed_firestore()
