import base64
import requests
from datetime import datetime
from flask import current_app

class MpesaService:
    """
    Safaricom M-Pesa Daraja API integration for RLDS Church offerings & tithes.
    Supports live Daraja sandbox/production STK Push and instant simulation mode.
    """

    @classmethod
    def get_access_token(cls) -> str:
        """Fetch Daraja OAuth bearer token."""
        env = current_app.config.get('MPESA_ENV', 'sandbox')
        consumer_key = current_app.config.get('MPESA_CONSUMER_KEY')
        consumer_secret = current_app.config.get('MPESA_CONSUMER_SECRET')
        
        if not consumer_key or not consumer_secret:
            return ""

        url = "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials" if env == 'sandbox' else "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
        
        try:
            res = requests.get(url, auth=(consumer_key, consumer_secret), timeout=10)
            if res.status_code == 200:
                return res.json().get('access_token', '')
        except Exception as e:
            current_app.logger.error(f"Daraja token error: {str(e)}")
        return ""

    @classmethod
    def initiate_stk_push(cls, phone_number: str, amount: float, account_reference: str, description: str = "RLDS Tithes"):
        """
        Triggers STK Push prompt to church member's phone.
        Formats phone to 254XXXXXXXXX.
        """
        # Format phone number
        phone = phone_number.replace('+', '').replace(' ', '')
        if phone.startswith('0'):
            phone = '254' + phone[1:]
        elif phone.startswith('7') or phone.startswith('1'):
            phone = '254' + phone

        # If live credentials not configured or mock mode enabled, return simulated success
        if current_app.config.get('ENABLE_MOCK_MPESA') or not current_app.config.get('MPESA_CONSUMER_KEY'):
            mock_checkout_id = f"ws_CO_{datetime.now().strftime('%d%m%Y%H%M%S')}_{phone[-4:]}"
            current_app.logger.info(f"[MPESA MOCK] Simulated STK Push sent to {phone} for KES {amount}")
            return {
                "ResponseCode": "0",
                "ResponseDescription": "Success. Request accepted for processing (Simulated).",
                "MerchantRequestID": f"MR_{datetime.now().strftime('%Y%m%d%H%M%S')}",
                "CheckoutRequestID": mock_checkout_id,
                "CustomerMessage": f"STK PIN prompt sent to {phone}. Enter your M-Pesa PIN to complete contribution of KES {amount}."
            }

        token = cls.get_access_token()
        if not token:
            return {"error": "Failed to authenticate with Safaricom Daraja API."}

        env = current_app.config.get('MPESA_ENV', 'sandbox')
        stk_url = "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest" if env == 'sandbox' else "https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest"
        
        shortcode = current_app.config.get('MPESA_SHORTCODE', '174379')
        passkey = current_app.config.get('MPESA_PASSKEY', '')
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        
        raw_password = f"{shortcode}{passkey}{timestamp}"
        password = base64.b64encode(raw_password.encode()).decode('utf-8')
        
        callback_url = current_app.config.get('MPESA_CALLBACK_URL')
        
        payload = {
            "BusinessShortCode": shortcode,
            "Password": password,
            "Timestamp": timestamp,
            "TransactionType": "CustomerPayBillOnline",
            "Amount": int(amount),
            "PartyA": phone,
            "PartyB": shortcode,
            "PhoneNumber": phone,
            "CallBackURL": callback_url,
            "AccountReference": account_reference[:12],
            "TransactionDesc": description[:12]
        }

        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }

        try:
            res = requests.post(stk_url, json=payload, headers=headers, timeout=15)
            return res.json()
        except Exception as e:
            return {"error": f"M-Pesa API request failed: {str(e)}"}
