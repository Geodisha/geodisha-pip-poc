"""
GeoDisha API Gateway - Main Application
FastAPI-based API Gateway for GeoDisha Political Intelligence Platform
"""

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import logging
import time

from config import settings

# Try to import services, but make them optional for minimal setup
try:
    from core.database import init_db, close_db
    DATABASE_AVAILABLE = True
except ImportError:
    DATABASE_AVAILABLE = False
    async def init_db(): pass
    async def close_db(): pass
    
try:
    from core.firebase import initialize_firebase
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False
    def initialize_firebase(): pass

try:
    from core.pubsub import initialize_pubsub
    PUBSUB_AVAILABLE = True
except ImportError:
    PUBSUB_AVAILABLE = False
    def initialize_pubsub(): pass

try:
    from middleware.logging import LoggingMiddleware
    LOGGING_MIDDLEWARE_AVAILABLE = True
except ImportError:
    LOGGING_MIDDLEWARE_AVAILABLE = False
    
try:
    from middleware.auth import AuthMiddleware
    AUTH_MIDDLEWARE_AVAILABLE = True
except ImportError:
    AUTH_MIDDLEWARE_AVAILABLE = False

# Import routers - some may require database
from api.v1 import constituencies, visits

# Optional routers that require database/firebase
try:
    from api.v1 import auth, grievances, users
    DATABASE_ROUTERS_AVAILABLE = True
except (ImportError, AssertionError):
    DATABASE_ROUTERS_AVAILABLE = False
    auth = grievances = users = None

# BigQuery-powered module routers (NEW)
try:
    from api.v1 import (
        command_center,
        ai_intelligence,
        ground_reality,
        election_war_room,
        promises,
        alerts_crisis
    )
    BIGQUERY_ROUTERS_AVAILABLE = True
except (ImportError, ModuleNotFoundError) as e:
    BIGQUERY_ROUTERS_AVAILABLE = False
    command_center = ai_intelligence = ground_reality = None
    election_war_room = promises = alerts_crisis = None
    logger.warning(f"BigQuery routers not available: {e}")

# Placeholder routers (not yet implemented)
try:
    from api.v1 import intelligence, analytics, notifications
    EXTRA_ROUTERS_AVAILABLE = True
except (ImportError, ModuleNotFoundError):
    EXTRA_ROUTERS_AVAILABLE = False
    intelligence = analytics = notifications = None

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    # Startup
    logger.info("Starting GeoDisha API Gateway")
    
    # Initialize services (make them optional for development)
    if DATABASE_AVAILABLE:
        try:
            await init_db()
            logger.info("✅ Database initialized")
        except Exception as e:
            logger.warning(f"⚠️  Database initialization skipped: {e}")
    
    if FIREBASE_AVAILABLE:
        try:
            initialize_firebase()
            logger.info("✅ Firebase initialized")
        except Exception as e:
            logger.warning(f"⚠️  Firebase initialization skipped: {e}")
    
    if PUBSUB_AVAILABLE:
        try:
            initialize_pubsub()
            logger.info("✅ Pub/Sub initialized")
        except Exception as e:
            logger.warning(f"⚠️  Pub/Sub initialization skipped: {e}")
    
    logger.info("🚀 API Gateway ready!")
    
    yield
    
    # Shutdown
    logger.info("Shutting down GeoDisha API Gateway")
    if DATABASE_AVAILABLE:
        try:
            await close_db()
        except Exception as e:
            logger.warning(f"Database close skipped: {e}")


# Create FastAPI app
app = FastAPI(
    title="GeoDisha Political Intelligence API",
    description="API Gateway for GeoDisha Mobile Platform",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/api/docs" if settings.ENVIRONMENT != "production" else None,
    redoc_url="/api/redoc" if settings.ENVIRONMENT != "production" else None,
)

# CORS Configuration - Wide open for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Compression
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Custom Middleware (only if available)
if LOGGING_MIDDLEWARE_AVAILABLE:
    app.add_middleware(LoggingMiddleware)
if AUTH_MIDDLEWARE_AVAILABLE:
    app.add_middleware(AuthMiddleware)


# Health check endpoints
@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint for load balancer"""
    return {
        "status": "healthy",
        "service": "geodisha-api-gateway",
        "version": "1.0.0"
    }


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint"""
    return {
        "message": "GeoDisha Political Intelligence API",
        "version": "1.0.0",
        "docs": "/api/docs"
    }


# API v1 Routers - Only register available routers
# Always available (BigQuery-based)
app.include_router(constituencies.router, prefix="/api/v1/constituencies", tags=["Constituencies"])
app.include_router(visits.router, prefix="/api/v1/visits", tags=["Visits"])

# BigQuery-powered module routers (NEW - All 6 Modules)
if BIGQUERY_ROUTERS_AVAILABLE:
    if command_center:
        app.include_router(command_center.router, prefix="/api/v1/command-center", tags=["Command Center"])
    if ai_intelligence:
        app.include_router(ai_intelligence.router, prefix="/api/v1/ai-intelligence", tags=["AI Intelligence"])
    if ground_reality:
        app.include_router(ground_reality.router, prefix="/api/v1/ground-reality", tags=["Ground Reality"])
    if election_war_room:
        app.include_router(election_war_room.router, prefix="/api/v1/election-war-room", tags=["Election War Room"])
    if promises:
        app.include_router(promises.router, prefix="/api/v1/promises", tags=["Promises"])
    if alerts_crisis:
        app.include_router(alerts_crisis.router, prefix="/api/v1/alerts", tags=["Alerts & Crisis"])

# Database-dependent routers (optional)
if DATABASE_ROUTERS_AVAILABLE:
    app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
    app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])
    app.include_router(grievances.router, prefix="/api/v1/grievances", tags=["Grievances"])

# Additional routers (to be implemented)
if EXTRA_ROUTERS_AVAILABLE:
    if intelligence:
        app.include_router(intelligence.router, prefix="/api/v1/intelligence", tags=["Intelligence"])
    if analytics:
        app.include_router(analytics.router, prefix="/api/v1/analytics", tags=["Analytics"])
    if notifications:
        app.include_router(notifications.router, prefix="/api/v1/notifications", tags=["Notifications"])


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler"""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "Internal server error",
            "message": str(exc) if settings.ENVIRONMENT != "production" else "An error occurred"
        }
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8080,
        reload=settings.ENVIRONMENT == "development"
    )
