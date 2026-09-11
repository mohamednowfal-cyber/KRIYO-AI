"""
Email Service for KRIYO.
Provides secure SMTP email dispatch for Customer OTP verification.
Handles TLS/SSL connections, robust error management, and graceful dev-mode fallback.
"""

import smtplib
import ssl
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Any, Dict, Optional

from app.config.settings import settings
from app.utils.logger import logger


def mask_email(email: str) -> str:
    """Mask email for privacy in logs: c***r@example.com"""
    if not email or "@" not in email:
        return email or ""
    parts = email.split("@")
    name = parts[0]
    domain = parts[1]
    if len(name) <= 2:
        masked_name = name[0] + "*"
    else:
        masked_name = name[0] + "*" * (len(name) - 2) + name[-1]
    return f"{masked_name}@{domain}"


class EmailService:
    """
    SMTP-based email delivery service for KRIYO.
    Loads credentials strictly from settings (environment variables).
    """

    def __init__(
        self,
        smtp_host: Optional[str] = None,
        smtp_port: Optional[int] = None,
        smtp_username: Optional[str] = None,
        smtp_password: Optional[str] = None,
        from_email: Optional[str] = None,
        from_name: Optional[str] = None,
        use_tls: Optional[bool] = None,
        use_ssl: Optional[bool] = None,
    ):
        self._smtp_host = smtp_host
        self._smtp_port = smtp_port
        self._smtp_username = smtp_username
        self._smtp_password = smtp_password
        self._from_email = from_email
        self._from_name = from_name
        self._use_tls = use_tls
        self._use_ssl = use_ssl

    @property
    def smtp_host(self) -> str:
        return self._smtp_host or settings.SMTP_HOST

    @property
    def smtp_port(self) -> int:
        return self._smtp_port or settings.SMTP_PORT

    @property
    def smtp_username(self) -> str:
        return self._smtp_username or settings.SMTP_USERNAME or settings.SMTP_USER

    @property
    def smtp_password(self) -> str:
        return self._smtp_password or settings.SMTP_PASSWORD

    @property
    def from_email(self) -> str:
        return self._from_email or settings.SMTP_FROM_EMAIL

    @property
    def from_name(self) -> str:
        return self._from_name or settings.SMTP_FROM_NAME

    @property
    def use_tls(self) -> bool:
        if self._use_tls is not None:
            return self._use_tls
        return getattr(settings, "SMTP_USE_TLS", True)

    @property
    def use_ssl(self) -> bool:
        if self._use_ssl is not None:
            return self._use_ssl
        return getattr(settings, "SMTP_USE_SSL", False)

    @property
    def is_smtp_configured(self) -> bool:
        return bool(self.smtp_host and self.smtp_host.strip())

    def _build_plain_text(self, otp_code: str, expiry_minutes: int = 5) -> str:
        return (
            f"Hello,\n\n"
            f"Your KRIYO verification code is:\n\n"
            f"{otp_code}\n\n"
            f"This code expires in {expiry_minutes} minutes.\n\n"
            f"If you did not request this verification, you can safely ignore this email.\n\n"
            f"Regards,\n"
            f"{self.from_name}\n"
        )

    def _build_html(self, otp_code: str, expiry_minutes: int = 5) -> str:
        return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>KRIYO Email Verification Code</title>
</head>
<body style="margin: 0; padding: 0; background-color: #FAF7F2; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
        <tr>
            <td align="center" style="padding: 40px 12px;">
                <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 520px; background-color: #FFFFFF; border-radius: 16px; border: 1px solid #EAD8C7; overflow: hidden; box-shadow: 0 4px 20px rgba(74, 44, 42, 0.06);">
                    <!-- Header Banner -->
                    <tr>
                        <td align="center" style="background-color: #3E2723; padding: 28px 24px;">
                            <h1 style="margin: 0; color: #FFFFFF; font-size: 26px; font-weight: 800; letter-spacing: 2px;">KRIYO</h1>
                            <p style="margin: 6px 0 0 0; color: #D7CCC8; font-size: 13px; font-weight: 400; letter-spacing: 0.5px;">Authentic Handmade Heritage</p>
                        </td>
                    </tr>
                    <!-- Main Body -->
                    <tr>
                        <td style="padding: 36px 32px 28px 32px; text-align: center;">
                            <h2 style="margin: 0 0 12px 0; color: #2E1B10; font-size: 20px; font-weight: 700;">Email Verification Code</h2>
                            <p style="margin: 0 0 24px 0; color: #6D4C41; font-size: 15px; line-height: 1.5;">
                                Hello,
                            </p>
                            <p style="margin: 0 0 24px 0; color: #6D4C41; font-size: 15px; line-height: 1.5;">
                                Your KRIYO verification code is:
                            </p>
                            <!-- OTP Box -->
                            <div style="background-color: #F5EBE1; border: 2px dashed #C88A58; border-radius: 12px; padding: 18px 28px; display: inline-block; margin-bottom: 24px;">
                                <span style="font-family: 'Courier New', Courier, monospace; font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #8D4004;">
                                    {otp_code}
                                </span>
                            </div>
                            <p style="margin: 0 0 16px 0; color: #8D6E63; font-size: 14px; line-height: 1.5;">
                                This code expires in <strong>{expiry_minutes} minutes</strong>.
                            </p>
                            <p style="margin: 0; color: #A1887F; font-size: 13px; line-height: 1.4;">
                                If you did not request this verification, you can safely ignore this email.
                            </p>
                        </td>
                    </tr>
                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #FAF7F2; padding: 18px 24px; text-align: center; border-top: 1px solid #EAD8C7;">
                            <p style="margin: 0; color: #A1887F; font-size: 12px;">
                                Regards,<br><strong>{self.from_name}</strong>
                            </p>
                            <p style="margin: 8px 0 0 0; color: #BCAAA4; font-size: 11px;">
                                &copy; 2026 KRIYO &bull; Empowering Traditional Indian Artisans &amp; Conscious Buyers
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>"""

    async def send_otp_email(
        self,
        to_email: str,
        otp_code: str,
        expiry_minutes: int = 5,
    ) -> Dict[str, Any]:
        """
        Send OTP verification email securely through SMTP.
        Returns dict with status, without exposing sensitive credentials.
        """
        masked = mask_email(to_email)
        subject = "KRIYO Email Verification Code"

        if not self.is_smtp_configured:
            # Development/local fallback when SMTP is not yet configured in .env
            logger.info(
                f"[EMAIL SERVICE] SMTP not configured. Simulating email OTP delivery to {masked}."
            )
            return {
                "success": True,
                "provider": "mock",
                "message": f"Verification code sent to {to_email}",
            }

        try:
            msg = MIMEMultipart("alternative")
            msg["Subject"] = subject
            msg["From"] = f"{self.from_name} <{self.from_email}>"
            msg["To"] = to_email

            plain_body = self._build_plain_text(otp_code, expiry_minutes)
            html_body = self._build_html(otp_code, expiry_minutes)

            msg.attach(MIMEText(plain_body, "plain", "utf-8"))
            msg.attach(MIMEText(html_body, "html", "utf-8"))

            clean_username = self.smtp_username.strip() if self.smtp_username else ""
            clean_password = self.smtp_password.replace(" ", "").strip() if self.smtp_password else ""

            if self.use_ssl:
                context = ssl.create_default_context()
                with smtplib.SMTP_SSL(self.smtp_host, self.smtp_port, context=context, timeout=12.0) as server:
                    if clean_username and clean_password:
                        server.login(clean_username, clean_password)
                    server.sendmail(self.from_email, [to_email], msg.as_string())
            else:
                with smtplib.SMTP(self.smtp_host, self.smtp_port, timeout=12.0) as server:
                    if self.use_tls:
                        context = ssl.create_default_context()
                        server.starttls(context=context)
                    if clean_username and clean_password:
                        server.login(clean_username, clean_password)
                    server.sendmail(self.from_email, [to_email], msg.as_string())

            logger.info(f"[EMAIL SERVICE] OTP email successfully delivered via SMTP to {masked}")
            return {
                "success": True,
                "provider": "smtp",
                "message": f"Verification code sent to {to_email}",
            }
        except smtplib.SMTPAuthenticationError as e:
            err_msg = e.smtp_error.decode("utf-8", errors="ignore") if isinstance(e.smtp_error, bytes) else (e.smtp_error or str(e))
            logger.error(f"[EMAIL SERVICE] Google SMTP Authentication Failed for {masked}: {err_msg}")
            raise RuntimeError(f"Email service authentication failed: {err_msg}") from e
        except (smtplib.SMTPConnectError, smtplib.SMTPServerDisconnected, TimeoutError) as e:
            logger.error(f"[EMAIL SERVICE] SMTP Connection Error for {masked}: {e}")
            raise RuntimeError("Email delivery service is currently unreachable.") from e
        except smtplib.SMTPException as e:
            logger.error(f"[EMAIL SERVICE] SMTP Protocol Error for {masked}: {e}")
            raise RuntimeError("Failed to transmit email through SMTP server.") from e
        except Exception as e:
            logger.error(f"[EMAIL SERVICE] Unexpected Error sending to {masked}: {e}")
            raise RuntimeError("An unexpected error occurred while sending verification email.") from e


email_service = EmailService()
