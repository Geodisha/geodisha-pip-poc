"""
Database models for GeoDisha Platform
"""

from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, Float, ForeignKey, Enum, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
import enum

from core.database import Base


class UserRole(str, enum.Enum):
    """User roles"""
    MLA = "MLA"
    MP = "MP"
    MINISTER = "MINISTER"
    STAFF = "STAFF"
    ADMIN = "ADMIN"


class GrievanceStatus(str, enum.Enum):
    """Grievance status"""
    SUBMITTED = "SUBMITTED"
    IN_PROGRESS = "IN_PROGRESS"
    ESCALATED = "ESCALATED"
    RESOLVED = "RESOLVED"
    CLOSED = "CLOSED"


class PromiseStatus(str, enum.Enum):
    """Promise status"""
    PENDING = "PENDING"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    DELAYED = "DELAYED"
    CANCELLED = "CANCELLED"


class User(Base):
    """User model"""
    __tablename__ = "users"
    
    id = Column(String(255), primary_key=True)  # Firebase UID
    email = Column(String(255), unique=True, nullable=False, index=True)
    phone = Column(String(20), unique=True, index=True)
    full_name = Column(String(255), nullable=False)
    role = Column(Enum(UserRole), nullable=False)
    profile_image_url = Column(String(500))
    
    # Political info
    party = Column(String(100))
    constituency_id = Column(String(100), index=True)
    constituency_name = Column(String(255))
    state = Column(String(100))
    
    # Metadata
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_login = Column(DateTime(timezone=True))
    
    # Relationships
    grievances = relationship("Grievance", back_populates="assigned_to_user")
    visits = relationship("Visit", back_populates="user")
    promises = relationship("Promise", back_populates="user")


class Constituency(Base):
    """Constituency model"""
    __tablename__ = "constituencies"
    
    id = Column(String(100), primary_key=True)
    name = Column(String(255), nullable=False)
    type = Column(String(50))  # LOK_SABHA, VIDHAN_SABHA
    state = Column(String(100), nullable=False, index=True)
    district = Column(String(100))
    
    # Geographic data
    latitude = Column(Float)
    longitude = Column(Float)
    geo_boundary = Column(JSON)  # GeoJSON polygon
    
    # Demographics
    total_population = Column(Integer)
    total_voters = Column(Integer)
    total_booths = Column(Integer)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class Grievance(Base):
    """Grievance model"""
    __tablename__ = "grievances"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    grievance_id = Column(String(50), unique=True, nullable=False, index=True)
    
    # Citizen info
    citizen_name = Column(String(255), nullable=False)
    citizen_phone = Column(String(20), nullable=False)
    citizen_email = Column(String(255))
    citizen_address = Column(Text)
    
    # Grievance details
    title = Column(String(500), nullable=False)
    description = Column(Text, nullable=False)
    category = Column(String(100), nullable=False, index=True)
    subcategory = Column(String(100))
    priority = Column(String(50), default="MEDIUM")
    
    # Location
    latitude = Column(Float)
    longitude = Column(Float)
    location_name = Column(String(255))
    constituency_id = Column(String(100), index=True)
    
    # Status
    status = Column(Enum(GrievanceStatus), default=GrievanceStatus.SUBMITTED, index=True)
    department = Column(String(100))
    
    # Assignment
    assigned_to = Column(String(255), ForeignKey("users.id"), index=True)
    assigned_at = Column(DateTime(timezone=True))
    
    # Resolution
    resolution_notes = Column(Text)
    resolved_at = Column(DateTime(timezone=True))
    resolution_images = Column(JSON)  # Array of image URLs
    
    # Attachments
    attachments = Column(JSON)  # Array of file URLs
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    assigned_to_user = relationship("User", back_populates="grievances")


class Visit(Base):
    """Visit tracking model"""
    __tablename__ = "visits"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    visit_id = Column(String(50), unique=True, nullable=False, index=True)
    
    # User
    user_id = Column(String(255), ForeignKey("users.id"), nullable=False, index=True)
    
    # Visit details
    title = Column(String(500), nullable=False)
    description = Column(Text)
    visit_type = Column(String(100))  # PUBLIC_MEETING, SITE_VISIT, etc.
    
    # Location
    location_name = Column(String(255), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    constituency_id = Column(String(100), index=True)
    
    # Schedule
    scheduled_date = Column(DateTime(timezone=True), nullable=False, index=True)
    start_time = Column(DateTime(timezone=True))
    end_time = Column(DateTime(timezone=True))
    
    # Promises made during visit
    promises_made = Column(JSON)  # Array of promise IDs
    
    # Attendance
    estimated_attendance = Column(Integer)
    actual_attendance = Column(Integer)
    
    # Media
    images = Column(JSON)  # Array of image URLs
    videos = Column(JSON)  # Array of video URLs
    
    # Status
    status = Column(String(50), default="SCHEDULED")  # SCHEDULED, COMPLETED, CANCELLED
    
    # Notes
    notes = Column(Text)
    key_takeaways = Column(JSON)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="visits")


class Promise(Base):
    """Promise tracking model"""
    __tablename__ = "promises"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    promise_id = Column(String(50), unique=True, nullable=False, index=True)
    
    # User
    user_id = Column(String(255), ForeignKey("users.id"), nullable=False, index=True)
    
    # Promise details
    title = Column(String(500), nullable=False)
    description = Column(Text, nullable=False)
    category = Column(String(100), nullable=False, index=True)
    promise_type = Column(String(100))  # MANIFESTO, VISIT, SPEECH, etc.
    
    # Location
    constituency_id = Column(String(100), index=True)
    location_specific = Column(Boolean, default=False)
    location_name = Column(String(255))
    
    # Timeline
    promised_date = Column(DateTime(timezone=True), nullable=False)
    target_completion_date = Column(DateTime(timezone=True))
    actual_completion_date = Column(DateTime(timezone=True))
    
    # Status
    status = Column(Enum(PromiseStatus), default=PromiseStatus.PENDING, index=True)
    completion_percentage = Column(Integer, default=0)
    
    # Risk assessment
    risk_score = Column(Float, default=0.0)
    risk_factors = Column(JSON)
    
    # Budget
    estimated_budget = Column(Float)
    allocated_budget = Column(Float)
    spent_amount = Column(Float)
    
    # Dependencies
    department = Column(String(100))
    stakeholders = Column(JSON)
    
    # Updates
    updates = Column(JSON)  # Array of status updates
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="promises")


class BoothScore(Base):
    """Booth scoring model"""
    __tablename__ = "booth_scores"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    
    # Booth info
    booth_id = Column(String(100), nullable=False, index=True)
    booth_name = Column(String(255), nullable=False)
    constituency_id = Column(String(100), nullable=False, index=True)
    
    # Location
    latitude = Column(Float)
    longitude = Column(Float)
    
    # Voting data
    total_voters = Column(Integer)
    last_election_turnout = Column(Integer)
    last_election_votes_received = Column(Integer)
    
    # Scores
    loyalty_score = Column(Float, default=0.0)  # 0-100
    risk_score = Column(Float, default=0.0)  # 0-100
    influence_score = Column(Float, default=0.0)  # 0-100
    overall_score = Column(Float, default=0.0)  # 0-100
    
    # Sentiment
    sentiment_score = Column(Float, default=0.0)  # -1 to 1
    sentiment_trend = Column(String(50))  # POSITIVE, NEGATIVE, NEUTRAL
    
    # Influencers
    key_influencers = Column(JSON)
    
    # Metadata
    last_calculated = Column(DateTime(timezone=True), server_default=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
