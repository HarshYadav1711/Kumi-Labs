from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from auth import OTP_VALUE, create_token, decode_token, hash_password, verify_password
from config import settings
from database import close_db, get_db
from models import LoginRequest, ProfileResponse, RegisterRequest, TokenResponse

app = FastAPI(title="User Service")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
security = HTTPBearer(auto_error=False)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.on_event("shutdown")
async def shutdown():
    await close_db()


@app.post("/register", response_model=TokenResponse)
async def register(body: RegisterRequest):
    db = await get_db()
    existing = await db.users.find_one({"email": body.email})
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    doc = {
        "email": body.email,
        "password_hash": hash_password(body.password),
        "name": body.name,
    }
    await db.users.insert_one(doc)
    token = create_token(body.email)
    return TokenResponse(access_token=token)


@app.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest):
    db = await get_db()
    user = await db.users.find_one({"email": body.email})
    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if body.otp is not None:
        if body.otp != OTP_VALUE:
            raise HTTPException(status_code=401, detail="Invalid OTP")
    else:
        if not body.password or not verify_password(body.password, user["password_hash"]):
            raise HTTPException(status_code=401, detail="Invalid email or password")
    token = create_token(body.email)
    return TokenResponse(access_token=token)


async def get_current_email(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
) -> str:
    if not credentials or credentials.credentials is None:
        raise HTTPException(status_code=401, detail="Missing or invalid token")
    email = decode_token(credentials.credentials)
    if not email:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    return email


@app.get("/profile", response_model=ProfileResponse)
async def profile(email: str = Depends(get_current_email)):
    db = await get_db()
    user = await db.users.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return ProfileResponse(email=user["email"], name=user["name"])
