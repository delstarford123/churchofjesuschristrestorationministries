import os
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from flask import current_app

class EmailService:
    """
    Handles automated transactional emails for RLDS Church Restoration Ministry.
    Works seamlessly in serverless environments (Vercel) with SMTP / Gmail / SendGrid / SES.
    Gracefully falls back to mock logging if SMTP credentials are omitted.
    """

    @classmethod
    def _is_configured(cls) -> bool:
        user = current_app.config.get('MAIL_USERNAME')
        pw = current_app.config.get('MAIL_PASSWORD')
        return bool(user and pw)

    @classmethod
    def send_html_email(cls, recipient: str, subject: str, html_body: str) -> bool:
        if not recipient:
            return False

        if not cls._is_configured():
            current_app.logger.info(
                f"[EMAIL MOCK DISPATCH] Recipient: {recipient} | Subject: {subject}\n"
                f"SMTP not configured. Message simulated successfully in logs."
            )
            return True

        try:
            msg = MIMEMultipart('alternative')
            msg['Subject'] = subject
            msg['From'] = current_app.config.get('MAIL_DEFAULT_SENDER', 'RLDS Church Restoration Ministry')
            msg['To'] = recipient

            part = MIMEText(html_body, 'html')
            msg.attach(part)

            server_host = current_app.config.get('MAIL_SERVER', 'smtp.gmail.com')
            server_port = current_app.config.get('MAIL_PORT', 587)
            use_tls = current_app.config.get('MAIL_USE_TLS', True)
            use_ssl = current_app.config.get('MAIL_USE_SSL', False)
            username = current_app.config.get('MAIL_USERNAME')
            password = current_app.config.get('MAIL_PASSWORD')

            if use_ssl:
                server = smtplib.SMTP_SSL(server_host, server_port, timeout=10)
            else:
                server = smtplib.SMTP(server_host, server_port, timeout=10)
                if use_tls:
                    server.starttls()

            server.login(username, password)
            server.sendmail(msg['From'], [recipient], msg.as_string())
            server.quit()
            current_app.logger.info(f"Email successfully sent to {recipient}")
            return True
        except Exception as e:
            current_app.logger.error(f"Failed to send email to {recipient}: {str(e)}")
            return False

    @classmethod
    def send_tithe_receipt_email(cls, member_email: str, member_name: str, amount: float,
                                  currency: str, category: str, mpesa_receipt: str, tx_id: str):
        subject = f"Official Receipt: {category} Contribution - RLDS Church"
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f3f4f6; margin: 0; padding: 20px; }}
            .card {{ max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }}
            .header {{ background-color: #1E3A8A; color: #ffffff; padding: 30px 24px; text-align: center; }}
            .header h1 {{ margin: 0; font-size: 22px; letter-spacing: 0.5px; }}
            .header p {{ margin: 6px 0 0; font-size: 13px; opacity: 0.9; color: #fbbf24; }}
            .content {{ padding: 28px 24px; color: #374151; }}
            .receipt-box {{ background-color: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 8px; padding: 20px; margin: 20px 0; }}
            .row {{ display: flex; justify-content: space-between; margin-bottom: 10px; font-size: 14px; }}
            .label {{ color: #64748b; font-weight: 500; }}
            .val {{ color: #0f172a; font-weight: 600; }}
            .amount {{ font-size: 24px; font-weight: bold; color: #1E3A8A; text-align: center; margin: 15px 0; }}
            .scripture {{ font-style: italic; background-color: #eff6ff; border-left: 4px solid #1E3A8A; padding: 12px 16px; margin: 20px 0; font-size: 13px; color: #1e3a8a; }}
            .footer {{ background-color: #f8fafc; border-top: 1px solid #e2e8f0; padding: 16px 24px; text-align: center; font-size: 12px; color: #94a3b8; }}
          </style>
        </head>
        <body>
          <div class="card">
            <div class="header">
              <h1>The Church of Jesus Christ Restoration Ministry</h1>
              <p>RLDS Church &bull; Digital Sanctuary & Stewardship</p>
            </div>
            <div class="content">
              <p>Dear <strong>{member_name}</strong>,</p>
              <p>We gratefully acknowledge receipt of your kingdom offering. May the Lord bless and multiply your seeds sown.</p>
              
              <div class="receipt-box">
                <div class="amount">{currency} {amount:,.2f}</div>
                <div class="row"><span class="label">Contribution Category:</span><span class="val">{category}</span></div>
                <div class="row"><span class="label">M-Pesa Reference / Code:</span><span class="val">{mpesa_receipt or 'N/A'}</span></div>
                <div class="row"><span class="label">Transaction Reference:</span><span class="val">{tx_id}</span></div>
                <div class="row"><span class="label">Status:</span><span class="val" style="color: #16a34a;">Recorded & Synchronized</span></div>
              </div>

              <div class="scripture">
                &ldquo;Bring all the tithes into the storehouse, that there may be food in My house, and try Me now in this,&rdquo; says the Lord of hosts. &mdash; <em>Malachi 3:10</em>
              </div>

              <p style="font-size: 13px; color: #64748b;">This is an automated digital receipt generated by RLDS Church Management System powered by Delstarford Works.</p>
            </div>
            <div class="footer">
              RLDS Church Restoration Ministry &bull; Delstarford Works System
            </div>
          </div>
        </body>
        </html>
        """
        return cls.send_html_email(member_email, subject, html)

    @classmethod
    def send_loan_status_email(cls, member_email: str, member_name: str, loan_id: str,
                                status: str, director_name: str, review_notes: str):
        is_approved = status.lower() == 'approved'
        badge_color = "#16a34a" if is_approved else "#dc2626"
        status_text = "APPROVED" if is_approved else "REJECTED"
        
        subject = f"Stewardship Kitty Loan Application {status_text} - Ref: {loan_id}"
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f3f4f6; margin: 0; padding: 20px; }}
            .card {{ max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }}
            .header {{ background-color: #1E3A8A; color: #ffffff; padding: 28px 24px; text-align: center; }}
            .content {{ padding: 28px 24px; color: #374151; }}
            .badge {{ display: inline-block; padding: 8px 18px; border-radius: 9999px; font-weight: bold; font-size: 14px; color: #ffffff; background-color: {badge_color}; margin: 15px 0; }}
            .details-box {{ background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 18px; margin: 18px 0; }}
            .footer {{ background-color: #f8fafc; border-top: 1px solid #e2e8f0; padding: 16px 24px; text-align: center; font-size: 12px; color: #94a3b8; }}
          </style>
        </head>
        <body>
          <div class="card">
            <div class="header">
              <h2 style="margin: 0; font-size: 20px;">RLDS Stewardship Kitty Fund</h2>
              <p style="margin: 4px 0 0; color: #fbbf24; font-size: 13px;">Executive Board Application Review</p>
            </div>
            <div class="content">
              <p>Dear <strong>{member_name}</strong>,</p>
              <p>Your Stewardship Kitty loan application (Ref: <strong>{loan_id}</strong>) has been reviewed by the Executive Board.</p>
              
              <div style="text-align: center;">
                <span class="badge">{status_text}</span>
              </div>

              <div class="details-box">
                <p style="margin: 6px 0;"><strong>Reviewed By:</strong> {director_name or 'Executive Director Board'}</p>
                <p style="margin: 6px 0;"><strong>Review Notes / Next Steps:</strong></p>
                <p style="margin: 6px 0; font-style: italic; color: #475569;">{review_notes or 'No additional remarks provided.'}</p>
              </div>

              {'<p>Our Treasury desk will reach out regarding fund disbursement and repayment schedule tracking.</p>' if is_approved else '<p>You may consult your Deacon or the Executive Board for further clarification or re-application guidance.</p>'}
            </div>
            <div class="footer">
              The Church of Jesus Christ Restoration Ministry &bull; Powered by Delstarford Works
            </div>
          </div>
        </body>
        </html>
        """
        return cls.send_html_email(member_email, subject, html)

    @classmethod
    def send_loan_submission_notice(cls, member_email: str, member_name: str, loan_id: str,
                                    amount: float, period: int):
        subject = f"Loan Application Queued - Stewardship Kitty ({loan_id})"
        html = f"""
        <div style="font-family: sans-serif; padding: 20px; color: #1e293b;">
          <h2 style="color: #1e3a8a;">RLDS Stewardship Kitty</h2>
          <p>Hello <strong>{member_name}</strong>,</p>
          <p>Your loan request of <strong>KES {amount:,.2f}</strong> for a duration of <strong>{period} months</strong> has been received into the queue (Loan ID: <strong>{loan_id}</strong>).</p>
          <p>It is currently awaiting review by the Executive Directors. You will receive an update once a decision is made.</p>
          <hr style="border: 0; border-top: 1px solid #e2e8f0; margin: 20px 0;">
          <small style="color: #64748b;">The Church of Jesus Christ Restoration Ministry &bull; Delstarford Works</small>
        </div>
        """
        return cls.send_html_email(member_email, subject, html)
