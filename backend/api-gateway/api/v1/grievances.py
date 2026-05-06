"""
Grievances API endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from pydantic import BaseModel, validator
from typing import Optional, List
from datetime import datetime
import uuid

# Optional imports for database functionality
try:
    from sqlalchemy import select, func, and_, or_
    from sqlalchemy.ext.asyncio import AsyncSession
    from core.database import get_db
    from models.database import Grievance, GrievanceStatus
    DATABASE_AVAILABLE = True
except ImportError:
    DATABASE_AVAILABLE = False
    select = func = and_ = or_ = None
    AsyncSession = None
    get_db = None
    Grievance = GrievanceStatus = None

try:
    from core.pubsub import PubSubService
    PUBSUB_AVAILABLE = True
except ImportError:
    PUBSUB_AVAILABLE = False
    PubSubService = None

from middleware.auth import get_current_user

router = APIRouter()
if PUBSUB_AVAILABLE:
    pubsub = PubSubService()
else:
    pubsub = None


class GrievanceCreate(BaseModel):
    """Grievance creation model"""
    citizen_name: str
    citizen_phone: str
    citizen_email: Optional[str] = None
    citizen_address: Optional[str] = None
    title: str
    description: str
    category: str
    subcategory: Optional[str] = None
    priority: str = "MEDIUM"
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    location_name: Optional[str] = None
    constituency_id: Optional[str] = None
    attachments: Optional[List[str]] = []


class GrievanceUpdate(BaseModel):
    """Grievance update model"""
    status: Optional[GrievanceStatus] = None
    department: Optional[str] = None
    assigned_to: Optional[str] = None
    resolution_notes: Optional[str] = None
    resolution_images: Optional[List[str]] = None


class GrievanceResponse(BaseModel):
    """Grievance response model"""
    id: int
    grievance_id: str
    citizen_name: str
    citizen_phone: str
    title: str
    description: str
    category: str
    status: str
    priority: str
    location_name: Optional[str]
    constituency_id: Optional[str]
    created_at: datetime
    updated_at: Optional[datetime]
    
    class Config:
        from_attributes = True


@router.post("/", response_model=GrievanceResponse, status_code=status.HTTP_201_CREATED)
async def create_grievance(
    grievance_data: GrievanceCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Create a new grievance
    """
    try:
        # Generate unique grievance ID
        grievance_id = f"GRV-{uuid.uuid4().hex[:8].upper()}"
        
        # Create grievance
        new_grievance = Grievance(
            grievance_id=grievance_id,
            citizen_name=grievance_data.citizen_name,
            citizen_phone=grievance_data.citizen_phone,
            citizen_email=grievance_data.citizen_email,
            citizen_address=grievance_data.citizen_address,
            title=grievance_data.title,
            description=grievance_data.description,
            category=grievance_data.category,
            subcategory=grievance_data.subcategory,
            priority=grievance_data.priority,
            latitude=grievance_data.latitude,
            longitude=grievance_data.longitude,
            location_name=grievance_data.location_name,
            constituency_id=grievance_data.constituency_id or current_user.get("constituency_id"),
            status=GrievanceStatus.SUBMITTED,
            attachments=grievance_data.attachments
        )
        
        db.add(new_grievance)
        await db.commit()
        await db.refresh(new_grievance)
        
        # Publish event to Pub/Sub
        await pubsub.publish_grievance_event(
            "grievance.created",
            {
                "grievance_id": grievance_id,
                "category": grievance_data.category,
                "constituency_id": new_grievance.constituency_id,
                "priority": grievance_data.priority,
                "created_at": new_grievance.created_at.isoformat()
            }
        )
        
        return new_grievance
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create grievance: {str(e)}"
        )


@router.get("/", response_model=List[GrievanceResponse])
async def get_grievances(
    constituency_id: Optional[str] = None,
    status_filter: Optional[GrievanceStatus] = None,
    category: Optional[str] = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Get grievances with filters
    """
    try:
        query = select(Grievance)
        
        # Apply filters
        filters = []
        
        if constituency_id:
            filters.append(Grievance.constituency_id == constituency_id)
        elif current_user.get("constituency_id"):
            # If user has a constituency, filter by it
            filters.append(Grievance.constituency_id == current_user["constituency_id"])
        
        if status_filter:
            filters.append(Grievance.status == status_filter)
        
        if category:
            filters.append(Grievance.category == category)
        
        if filters:
            query = query.where(and_(*filters))
        
        # Order by creation date (newest first)
        query = query.order_by(Grievance.created_at.desc())
        
        # Pagination
        query = query.offset(skip).limit(limit)
        
        result = await db.execute(query)
        grievances = result.scalars().all()
        
        return grievances
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch grievances: {str(e)}"
        )


@router.get("/{grievance_id}", response_model=GrievanceResponse)
async def get_grievance(
    grievance_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Get a specific grievance by ID
    """
    try:
        result = await db.execute(
            select(Grievance).where(Grievance.grievance_id == grievance_id)
        )
        grievance = result.scalar_one_or_none()
        
        if not grievance:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Grievance not found"
            )
        
        return grievance
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch grievance: {str(e)}"
        )


@router.patch("/{grievance_id}", response_model=GrievanceResponse)
async def update_grievance(
    grievance_id: str,
    update_data: GrievanceUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Update a grievance
    """
    try:
        result = await db.execute(
            select(Grievance).where(Grievance.grievance_id == grievance_id)
        )
        grievance = result.scalar_one_or_none()
        
        if not grievance:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Grievance not found"
            )
        
        # Update fields
        if update_data.status is not None:
            old_status = grievance.status
            grievance.status = update_data.status
            
            if update_data.status == GrievanceStatus.RESOLVED:
                grievance.resolved_at = datetime.utcnow()
            
            # Publish status change event
            await pubsub.publish_grievance_event(
                "grievance.status_changed",
                {
                    "grievance_id": grievance_id,
                    "old_status": old_status.value,
                    "new_status": update_data.status.value,
                    "updated_at": datetime.utcnow().isoformat()
                }
            )
        
        if update_data.department is not None:
            grievance.department = update_data.department
        
        if update_data.assigned_to is not None:
            grievance.assigned_to = update_data.assigned_to
            grievance.assigned_at = datetime.utcnow()
        
        if update_data.resolution_notes is not None:
            grievance.resolution_notes = update_data.resolution_notes
        
        if update_data.resolution_images is not None:
            grievance.resolution_images = update_data.resolution_images
        
        await db.commit()
        await db.refresh(grievance)
        
        return grievance
        
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update grievance: {str(e)}"
        )


@router.get("/stats/summary")
async def get_grievance_stats(
    constituency_id: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Get grievance statistics
    """
    try:
        filters = []
        
        if constituency_id:
            filters.append(Grievance.constituency_id == constituency_id)
        elif current_user.get("constituency_id"):
            filters.append(Grievance.constituency_id == current_user["constituency_id"])
        
        base_query = select(Grievance)
        if filters:
            base_query = base_query.where(and_(*filters))
        
        # Total count
        total_result = await db.execute(
            select(func.count()).select_from(base_query.subquery())
        )
        total_count = total_result.scalar()
        
        # Count by status
        status_query = select(
            Grievance.status,
            func.count(Grievance.id).label("count")
        )
        if filters:
            status_query = status_query.where(and_(*filters))
        status_query = status_query.group_by(Grievance.status)
        
        status_result = await db.execute(status_query)
        status_counts = {row.status.value: row.count for row in status_result}
        
        # Count by category
        category_query = select(
            Grievance.category,
            func.count(Grievance.id).label("count")
        )
        if filters:
            category_query = category_query.where(and_(*filters))
        category_query = category_query.group_by(Grievance.category).limit(10)
        
        category_result = await db.execute(category_query)
        category_counts = {row.category: row.count for row in category_result}
        
        return {
            "total_grievances": total_count,
            "by_status": status_counts,
            "by_category": category_counts,
            "resolution_rate": (
                status_counts.get("RESOLVED", 0) / total_count * 100
                if total_count > 0 else 0
            )
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch statistics: {str(e)}"
        )
