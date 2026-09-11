# KRIYO Backend Service

Production-ready FastAPI backend service powering the **KRIYO** Artisan & Customer mobile platforms.

---

## Architecture Overview

```text
kriyo_backend/
├── app/
│   ├── main.py                     # FastAPI application setup & lifecycle
│   │
│   ├── config/                     # Settings, environment & security constants
│   │   ├── settings.py
│   │   └── security.py
│   │
│   ├── api/v1/                     # Versioned API routes & endpoints
│   │   ├── router.py               # Combined API v1 router
│   │   └── endpoints/
│   │       ├── auth.py             # OTP request, verify, refresh, logout
│   │       ├── users.py            # User profile management
│   │       └── profiles.py         # Artisan & Customer profile endpoints
│   │
│   ├── auth/                       # Authentication business logic & dependencies
│   │   ├── otp_service.py          # OTP generation, storage, and rate-limiting
│   │   ├── token_service.py        # JWT access & refresh token management
│   │   ├── session_service.py      # Session lifecycle & token revocation
│   │   └── dependencies.py         # FastAPI security dependencies (current_user)
│   │
│   ├── providers/                  # External 3rd party providers
│   │   └── msg91_provider.py       # MSG91 SMS & OTP integration (with Sandbox/Mock)
│   │
│   ├── models/                     # SQLAlchemy ORM Models
│   │   ├── user.py                 # User account model (Artisan/Customer)
│   │   ├── otp_session.py          # OTP attempts & verification sessions
│   │   └── artisan_profile.py      # Heritage & craft profile details
│   │
│   ├── schemas/                    # Pydantic v2 Request & Response schemas
│   │   ├── auth.py                 # OTP send/verify, token response schemas
│   │   ├── user.py                 # User creation & response schemas
│   │   └── profile.py              # Artisan & customer profile schemas
│   │
│   ├── database/                   # Database engine & session injection
│   │   ├── database.py             # SQLAlchemy Engine & Base
│   │   └── session.py              # `get_db` dependency
│   │
│   ├── middleware/                 # Custom HTTP middlewares
│   │   ├── rate_limit.py           # SlowAPI rate limiter
│   │   └── security.py             # Security headers & request logging
│   │
│   └── utils/                      # Helper utilities
│       ├── phone.py                # Phone normalization & formatting (+91 E.164)
│       ├── logger.py               # Configured structured logger
│       └── validators.py           # Aadhaar, name, and input validators
│
├── .env                            # Local environment variables
├── requirements.txt                # Python dependencies
└── README.md                       # Documentation
```

---

## Getting Started

### 1. Create and Activate a Virtual Environment
```bash
# Windows PowerShell
python -m venv venv
.\venv\Scripts\Activate.ps1

# Linux / macOS
python3 -m venv venv
source venv/bin/activate
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Configure Environment Variables
Copy `.env` and verify configuration:
- `MSG91_MOCK_MODE=True` allows local development and testing without spending SMS credits. When mock mode is active, generated OTPs are printed to terminal logs and returned in the API response.
- Update `DATABASE_URL` if connecting to PostgreSQL (`postgresql://user:password@localhost:5432/kriyo_db`). Defaults to SQLite (`sqlite:///./kriyo_dev.db`).

### 4. Run the Development Server
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

---

## Interactive API Documentation

Once the server is running:
- **Swagger UI**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **ReDoc**: [http://localhost:8000/redoc](http://localhost:8000/redoc)
- **Health Check**: [http://localhost:8000/health](http://localhost:8000/health)

---

## Key Authentication Flow

1. **Send OTP**:
   `POST /api/v1/auth/send-otp`
   ```json
   {
     "phone_number": "9876543210",
     "role": "artisan"
   }
   ```
2. **Verify OTP**:
   `POST /api/v1/auth/verify-otp`
   ```json
   {
     "phone_number": "9876543210",
     "otp_code": "123456",
     "role": "artisan"
   }
   ```
   *Returns JWT access token, refresh token, and user profile.*

3. **Authenticated Requests**:
   Pass header `Authorization: Bearer <access_token>`.
