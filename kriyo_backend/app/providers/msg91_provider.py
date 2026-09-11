"""
MSG91 SMS and OTP Provider integration with Mock/Sandbox fallback.
Supports MSG91 v5 OTP API and resilient HTTP transport.
"""

from typing import Any, Dict, Optional
import httpx

from app.config.settings import settings
from app.utils.logger import logger
from app.utils.phone import mask_phone_number


class Msg91Provider:
    BASE_URL = "https://control.msg91.com/api/v5/otp"
    WIDGET_URL = "https://control.msg91.com/api/v5/widget"

    def __init__(
        self,
        auth_key: Optional[str] = None,
        template_id: Optional[str] = None,
        widget_id: Optional[str] = None,
        mock_mode: Optional[bool] = None,
    ):
        self.auth_key = auth_key or settings.MSG91_AUTH_KEY
        self.template_id = template_id or settings.MSG91_TEMPLATE_ID
        self.widget_id = widget_id or getattr(settings, "MSG91_WIDGET_ID", "")
        self.mock_mode = (
            mock_mode
            if mock_mode is not None
            else (settings.MSG91_MOCK_MODE or "your_msg91" in self.auth_key)
        )

    async def send_otp(self, phone_number: str, otp_code: str) -> Dict[str, Any]:
        """
        Send an OTP via MSG91 OTP Widget (free tier) or v5 OTP API.
        If mock_mode is active, logs the OTP locally and simulates success.
        """
        masked = mask_phone_number(phone_number)

        if self.mock_mode:
            logger.info(
                f"[MSG91 MOCK] Sending OTP '{otp_code}' to {masked} (Dev Mode Active)"
            )
            return {
                "type": "success",
                "message": f"MOCK OTP sent successfully to {masked}",
                "mock_otp": otp_code,
                "provider": "msg91_mock",
            }

        formatted_mobile = phone_number.lstrip("+")

        # 1. If MSG91 OTP Widget is configured, dispatch through the free OTP Widget API
        if self.widget_id and "your_msg91" not in self.widget_id:
            url = f"{self.WIDGET_URL}/sendOtp"
            payload = {
                "widgetId": self.widget_id,
                "identifier": formatted_mobile,
            }
            headers = {
                "authkey": self.auth_key,
                "Content-Type": "application/json",
            }
            try:
                async with httpx.AsyncClient(timeout=10.0) as client:
                    response = await client.post(url, json=payload, headers=headers)
                    data = response.json()
                    if response.status_code == 200 and data.get("type") != "error":
                        req_id = str(data.get("message") or data.get("reqId") or "")
                        masked_req_id = (req_id[:6] + "******") if len(req_id) > 6 else req_id
                        logger.info(
                            f"[MSG91 WIDGET LIVE] Dispatched free OTP to {masked} | req_id: {masked_req_id}"
                        )
                        return {
                            "type": "success",
                            "message": "Free OTP delivered successfully via SMS",
                            "request_id": req_id,
                            "provider": "msg91_widget",
                        }
                    else:
                        err_msg = str(data.get("message", "MSG91 Widget returned an error"))
                        logger.warning(f"[MSG91 WIDGET ERROR] Response for {masked}: {err_msg}")
                        if "Captcha" in err_msg:
                            err_msg = (
                                "MSG91 Widget has 'Captcha' enabled. Please open MSG91 Dashboard -> "
                                "OTP Widget (SendOTP) -> Edit Settings -> Turn OFF 'Captcha / Bot Protection' "
                                "so your app backend can dispatch the free SMS."
                            )
                        return {
                            "type": "error",
                            "message": err_msg,
                            "code": str(data.get("code", response.status_code)),
                            "provider": "msg91_widget",
                        }
            except Exception as e:
                logger.error(f"[MSG91 WIDGET EXCEPTION] {str(e)}")
                # Fall through to legacy endpoint

        # 2. Fallback to standard MSG91 v5 OTP API
        url = f"{self.BASE_URL}"
        params: Dict[str, Any] = {
            "mobile": formatted_mobile,
            "authkey": self.auth_key,
            "otp": otp_code,
            "otp_expiry": settings.MSG91_OTP_EXPIRY_MINUTES,
        }
        if self.template_id and "your_msg91" not in self.template_id:
            params["template_id"] = self.template_id

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(url, params=params)
                data = response.json()
                is_success = (
                    response.status_code == 200
                    and data.get("type") != "error"
                )
                if is_success:
                    request_id = str(data.get("request_id") or data.get("message") or "")
                    masked_req_id = (request_id[:6] + "******") if len(request_id) > 6 else request_id
                    logger.info(
                        f"[MSG91 LIVE] Dispatched OTP to {masked} | req_id: {masked_req_id} | Status: 200"
                    )
                    return {
                        "type": "success",
                        "message": "OTP delivered successfully via SMS",
                        "request_id": request_id,
                        "provider": "msg91",
                    }
                else:
                    err_msg = str(data.get("message", "MSG91 returned an error"))
                    err_code = str(data.get("code", response.status_code))
                    logger.error(f"[MSG91 ERROR] Failed sending OTP to {masked}: [{err_code}] {err_msg}")
                    return {
                        "type": "error",
                        "message": err_msg,
                        "code": err_code,
                        "provider": "msg91",
                    }
        except Exception as e:
            logger.exception(f"[MSG91 EXCEPTION] Connection failure to MSG91: {str(e)}")
            return {
                "type": "error",
                "message": f"SMS provider connection failure: {str(e)}",
                "code": "PROVIDER_UNAVAILABLE",
                "provider": "msg91",
            }

    async def verify_otp(self, phone_number: str, otp_code: str) -> Dict[str, Any]:
        """Verify OTP with MSG91 OTP verification API."""
        masked = mask_phone_number(phone_number)
        if self.mock_mode:
            logger.info(f"[MSG91 MOCK] Verifying OTP for {masked}")
            return {"type": "success", "message": "MOCK OTP verified successfully"}

        formatted_mobile = phone_number.lstrip("+")
        url = f"{self.BASE_URL}/verify"
        params = {
            "authkey": self.auth_key,
            "mobile": formatted_mobile,
            "otp": otp_code.strip(),
        }

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(url, params=params)
                data = response.json()
                msg = str(data.get("message", ""))
                is_success = (
                    response.status_code == 200
                    and data.get("type") == "success"
                )
                if is_success:
                    logger.info(f"[MSG91 LIVE] OTP verified for {masked}")
                    return {"type": "success", "message": "OTP verified successfully"}
                else:
                    err_code = str(data.get("code", response.status_code))
                    logger.warning(f"[MSG91 VERIFY] Response for {masked}: [{err_code}] {msg}")
                    return {
                        "type": "error",
                        "message": msg or "OTP verification failed",
                        "code": err_code,
                    }
        except Exception as e:
            logger.error(f"[MSG91 VERIFY EXCEPTION] {str(e)}")
            return {"type": "error", "message": str(e), "code": "NETWORK_ERROR"}

    async def resend_otp(self, phone_number: str, retry_type: str = "text") -> Dict[str, Any]:
        """Retry sending the OTP via SMS or Voice."""
        masked = mask_phone_number(phone_number)
        if self.mock_mode:
            logger.info(f"[MSG91 MOCK] Resent OTP to {masked}")
            return {"type": "success", "message": "MOCK OTP resent successfully"}

        formatted_mobile = phone_number.lstrip("+")
        url = f"{self.BASE_URL}/retry"
        params = {
            "authkey": self.auth_key,
            "mobile": formatted_mobile,
            "retrytype": retry_type,
        }

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(url, params=params)
                data = response.json()
                if response.status_code == 200 and data.get("type") != "error":
                    req_id = str(data.get("request_id") or data.get("message") or "")
                    return {
                        "type": "success",
                        "message": "OTP resent successfully",
                        "request_id": req_id,
                    }
                else:
                    err_msg = str(data.get("message", "Failed to resend OTP"))
                    return {"type": "error", "message": err_msg, "code": data.get("code")}
        except Exception as e:
            logger.error(f"[MSG91 RETRY ERROR] {str(e)}")
            return {"type": "error", "message": str(e)}


# Singleton instance
msg91_provider = Msg91Provider()
