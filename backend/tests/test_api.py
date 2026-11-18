import unittest
import json
import os
import sys

# Add backend directory to sys.path
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from app import create_app
from app.models import db, User, TitheTransaction, LoanApplication

class RLDSChurchBackendTestCase(unittest.TestCase):
    def setUp(self):
        # Configure app for testing with in-memory SQLite
        self.app = create_app()
        self.app.config.update({
            'TESTING': True,
            'SQLALCHEMY_DATABASE_URI': 'sqlite:///:memory:',
            'ENABLE_MOCK_MPESA': True
        })
        self.client = self.app.test_client()

        with self.app.app_context():
            db.create_all()
            
            # Create Executive Director
            director = User(
                member_id="RLDS-DIR-001",
                full_name="Elder John - Executive Director",
                email="director@rldschurch.org",
                phone_number="254711111111",
                role="Executive Director",
                department="Executive Board"
            )
            director.set_password("DirectorPass2026!")
            db.session.add(director)

            # Create Normal Member
            member = User(
                member_id="RLDS-MEM-001",
                full_name="Grace Wanjiku",
                email="grace@example.com",
                phone_number="254722222222",
                role="Normal Member",
                department="Youth"
            )
            member.set_password("MemberPass2026!")
            db.session.add(member)

            db.session.commit()

    def tearDown(self):
        with self.app.app_context():
            db.session.remove()
            db.drop_all()

    def _login(self, email, password):
        res = self.client.post('/api/v1/auth/login', json={
            'email': email,
            'password': password
        })
        return res.get_json()

    def test_health_check(self):
        res = self.client.get('/health')
        self.assertEqual(res.status_code, 200)
        data = res.get_json()
        self.assertEqual(data['status'], 'healthy')
        self.assertIn('Restoration Ministry', data['developer'])

    def test_api_root(self):
        res = self.client.get('/')
        self.assertEqual(res.status_code, 200)
        data = res.get_json()
        self.assertIn('endpoints', data)

    def test_member_registration_and_login(self):
        # Register new member
        reg_res = self.client.post('/api/v1/auth/register', json={
            'full_name': 'Samuel Ochieng',
            'email': 'samuel@example.com',
            'phone_number': '254733333333',
            'password': 'Password123!',
            'department': 'Men'
        })
        self.assertEqual(reg_res.status_code, 201)
        reg_data = reg_res.get_json()
        self.assertEqual(reg_data['status'], 'success')
        self.assertIn('token', reg_data)

        # Login
        login_res = self.client.post('/api/v1/auth/login', json={
            'email': 'samuel@example.com',
            'password': 'Password123!'
        })
        self.assertEqual(login_res.status_code, 200)
        login_data = login_res.get_json()
        self.assertEqual(login_data['user']['role'], 'Normal Member')

    def test_offline_tithes_sync(self):
        # Batch of offline transactions from Flutter app
        payload = {
            'transactions': [
                {
                    'client_transaction_id': 'TX-TEST-001',
                    'member_id': 'RLDS-MEM-001',
                    'member_name': 'Grace Wanjiku',
                    'member_email': 'grace@example.com',
                    'amount': 2500.0,
                    'category': 'Tithe',
                    'mpesa_receipt': 'QWE123RTY',
                    'transaction_date': '2026-11-18T08:00:00Z'
                },
                {
                    'client_transaction_id': 'TX-TEST-002',
                    'member_id': 'RLDS-MEM-001',
                    'member_name': 'Grace Wanjiku',
                    'amount': 1000.0,
                    'category': 'Building Fund',
                    'mpesa_receipt': 'QWE124RTY'
                }
            ]
        }
        res = self.client.post('/api/v1/tithes/sync', json=payload)
        self.assertEqual(res.status_code, 200)
        data = res.get_json()
        self.assertEqual(data['synced'], 2)
        self.assertEqual(data['duplicates_skipped'], 0)

        # Re-syncing same batch should test idempotency
        res_dup = self.client.post('/api/v1/tithes/sync', json=payload)
        self.assertEqual(res_dup.status_code, 200)
        data_dup = res_dup.get_json()
        self.assertEqual(data_dup['synced'], 0)
        self.assertEqual(data_dup['duplicates_skipped'], 2)

    def test_stewardship_kitty_loan_workflow(self):
        # 1. Member applies for loan
        loan_payload = {
            'client_loan_id': 'LOAN-CLIENT-001',
            'member_id': 'RLDS-MEM-001',
            'member_name': 'Grace Wanjiku',
            'member_email': 'grace@example.com',
            'amount_requested': 50000.0,
            'repayment_period_months': 6,
            'guarantor_phone': '254711111111',
            'purpose': 'Small Business Poultry Farm'
        }
        apply_res = self.client.post('/api/v1/loans/apply', json=loan_payload)
        self.assertEqual(apply_res.status_code, 201)
        loan_data = apply_res.get_json()
        loan_id = loan_data['loan_id']
        self.assertEqual(loan_data['data']['status'], 'Pending_Executive_Review')

        # 2. Normal Member tries to access pending loans -> Should get 403 Forbidden
        mem_login = self._login('grace@example.com', 'MemberPass2026!')
        mem_token = mem_login['token']
        mem_view = self.client.get('/api/v1/loans/pending', headers={'Authorization': f'Bearer {mem_token}'})
        self.assertEqual(mem_view.status_code, 403)

        # 3. Executive Director views pending loans -> Should succeed
        dir_login = self._login('director@rldschurch.org', 'DirectorPass2026!')
        dir_token = dir_login['token']
        dir_view = self.client.get('/api/v1/loans/pending', headers={'Authorization': f'Bearer {dir_token}'})
        self.assertEqual(dir_view.status_code, 200)
        self.assertEqual(dir_view.get_json()['count'], 1)

        # 4. Executive Director approves loan
        review_res = self.client.put(f'/api/v1/loans/{loan_id}/review', 
            headers={'Authorization': f'Bearer {dir_token}'},
            json={
                'action': 'approve',
                'director_name': 'Elder John',
                'notes': 'Verified with guarantor. Approved for disbursement.',
                'amount_approved': 50000.0
            }
        )
        self.assertEqual(review_res.status_code, 200)
        review_data = review_res.get_json()
        self.assertEqual(review_data['loan']['status'], 'Approved')
        self.assertEqual(review_data['loan']['remaining_balance'], 50000.0)

        # 5. Member records repayment installment
        repay_res = self.client.post(f'/api/v1/loans/{loan_id}/repay',
            headers={'Authorization': f'Bearer {mem_token}'},
            json={
                'amount': 25000.0,
                'mpesa_receipt': 'REP998877XX',
                'notes': 'First monthly installment'
            }
        )
        self.assertEqual(repay_res.status_code, 201)
        repay_data = repay_res.get_json()
        self.assertEqual(repay_data['remaining_balance'], 25000.0)

    def test_chatbot_inquiry(self):
        res = self.client.post('/api/v1/chat/message', json={'message': 'How can I apply for a loan from stewardship kitty?'})
        self.assertEqual(res.status_code, 200)
        data = res.get_json()
        self.assertIn('Stewardship Kitty', data['reply'])

    def test_phase2_credit_score_and_pledges(self):
        mem_login = self._login('grace@example.com', 'MemberPass2026!')
        mem_token = mem_login['token']

        # Credit Score calculation
        score_res = self.client.get('/api/v1/financials/credit-score/RLDS-MEM-001',
            headers={'Authorization': f'Bearer {mem_token}'})
        self.assertEqual(score_res.status_code, 200)
        score_data = score_res.get_json()
        self.assertIn('credit_score', score_data)
        self.assertIn('eligible_loan_limit', score_data)

        # Pledge creation & fulfillment
        pledge_res = self.client.post('/api/v1/financials/pledges',
            headers={'Authorization': f'Bearer {mem_token}'},
            json={
                'campaign_name': 'Cathedral Land Acquisition',
                'pledged_amount': 20000.0,
                'initial_payment': 5000.0
            }
        )
        self.assertEqual(pledge_res.status_code, 201)
        pledge_data = pledge_res.get_json()
        pledge_id = pledge_data['pledge']['pledge_id']
        self.assertEqual(pledge_data['pledge']['progress_percent'], 25.0)

        # Annual tax statement
        stmt_res = self.client.get('/api/v1/financials/statement/annual',
            headers={'Authorization': f'Bearer {mem_token}'})
        self.assertEqual(stmt_res.status_code, 200)
        self.assertIn('statement', stmt_res.get_json())

        # Kitty analytics for director
        dir_login = self._login('director@rldschurch.org', 'DirectorPass2026!')
        dir_token = dir_login['token']
        analytics_res = self.client.get('/api/v1/financials/kitty/analytics',
            headers={'Authorization': f'Bearer {dir_token}'})
        self.assertEqual(analytics_res.status_code, 200)
        self.assertIn('available_liquid_capital_kes', analytics_res.get_json()['analytics'])

    def test_phase3_governance_and_smart_attendance(self):
        mem_login = self._login('grace@example.com', 'MemberPass2026!')
        mem_token = mem_login['token']

        # Digital Membership Card
        card_res = self.client.get('/api/v1/governance/card/RLDS-MEM-001',
            headers={'Authorization': f'Bearer {mem_token}'})
        self.assertEqual(card_res.status_code, 200)
        self.assertIn('qr_data_string', card_res.get_json()['card'])

        # Smart Attendance NFC/QR check-in
        checkin_res = self.client.post('/api/v1/governance/attendance/checkin', json={
            'member_id': 'RLDS-MEM-001',
            'service_type': 'Sunday Sanctuary Service',
            'verification_method': 'NFC_TAG'
        })
        self.assertEqual(checkin_res.status_code, 201)

        # Re-checkin today should detect existing check-in
        checkin_dup = self.client.post('/api/v1/governance/attendance/checkin', json={
            'member_id': 'RLDS-MEM-001'
        })
        self.assertEqual(checkin_dup.status_code, 200)

    def test_phase4_community_and_education(self):
        mem_login = self._login('grace@example.com', 'MemberPass2026!')
        mem_token = mem_login['token']

        # Sunday School pickup code generator
        pickup_res = self.client.post('/api/v1/community/sundayschool/pickup/generate',
            headers={'Authorization': f'Bearer {mem_token}'},
            json={'child_name': 'David Omondi'}
        )
        self.assertEqual(pickup_res.status_code, 201)
        self.assertIn('pickup_code', pickup_res.get_json())

        # Anonymous Counseling prayer request
        counsel_res = self.client.post('/api/v1/community/counseling/submit', json={
            'subject': 'Healing & Family Prayer',
            'message': 'Please pray for my mother in Kakamega Hospital.',
            'is_anonymous': True
        })
        self.assertEqual(counsel_res.status_code, 201)
        self.assertIn('ticket_id', counsel_res.get_json())

    def test_phase5_smart_tech_and_branches(self):
        # Multi-language dictionary
        trans_res = self.client.get('/api/v1/tech/translations?lang=sw')
        self.assertEqual(trans_res.status_code, 200)
        self.assertIn('Fungu la Kumi', trans_res.get_json()['translations']['tithes_and_offerings'])

        # Branch Locator
        branches_res = self.client.get('/api/v1/tech/branches')
        self.assertEqual(branches_res.status_code, 200)
        branches = branches_res.get_json()['branches']
        self.assertTrue(any('Kakamega' in b['name'] for b in branches))

        # Digital Weekly Bulletin
        bulletin_res = self.client.get('/api/v1/tech/bulletin/current')
        self.assertEqual(bulletin_res.status_code, 200)
        self.assertIn('order_of_service', bulletin_res.get_json()['bulletin'])

if __name__ == '__main__':
    unittest.main()
