"""
Main API v1 router aggregator.
"""

from fastapi import APIRouter

from app.api.v1.endpoints import auth, customer_auth, profiles, users, rag

api_router = APIRouter()

api_router.include_router(customer_auth.router)
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(profiles.router)
api_router.include_router(rag.router)
