"""
Ground Reality API endpoints - Module 3
Connected to BigQuery views for visits and heatmap
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
from typing import Optional

from core.bigquery_enhanced import BigQueryEnhancedService
from middleware.auth import get_optional_user
from schemas.responses import APIResponse, UserContext

router = APIRouter()
bigquery_service = BigQueryEnhancedService()


async def get_user_context(request: Request) -> UserContext:
    """Extract user context for role-based filtering - optional auth for development"""
    current_user = await get_optional_user(request)
    
    if current_user:
        return UserContext(
            user_id=current_user.get("uid", ""),
            role=current_user.get("role", "volunteer"),
            constituency_id=current_user.get("constituency_id"),
            constituencies=current_user.get("constituencies", []),
            permissions=current_user.get("permissions", [])
        )
    
    # Default context for unauthenticated requests (development/testing)
    return UserContext(
        user_id="test_user",
        role="admin",
        constituency_id=None,
        constituencies=[],
        permissions=[]
    )


@router.get("/visits", response_model=APIResponse)
async def get_visits(
    start_date: Optional[str] = Query(default=None, description="Start date (YYYY-MM-DD)"),
    end_date: Optional[str] = Query(default=None, description="End date (YYYY-MM-DD)"),
    visit_type: Optional[str] = Query(default=None, description="Visit type filter"),
    limit: int = Query(default=100, ge=1, le=500, description="Number of visits to return"),
    offset: int = Query(default=0, ge=0, description="Offset for pagination"),
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get enhanced visit records
    
    **Parameters:**
    - start_date: Filter visits from this date
    - end_date: Filter visits until this date
    - visit_type: Filter by visit type (public_meeting, door-to-door, etc.)
    - limit: Maximum number of results (1-500)
    - offset: Pagination offset
    
    **Returns:**
    - Enhanced visit records with statistics
    """
    try:
        data = await bigquery_service.get_visits_enhanced(
            start_date=start_date,
            end_date=end_date,
            visit_type=visit_type,
            limit=limit,
            offset=offset,
            user_role=user_context.role.value,
            user_constituency_id=user_context.constituency_id,
            user_constituencies=user_context.constituencies
        )
        
        return APIResponse(
            success=True,
            data=data,
            filters_applied={
                "start_date": start_date,
                "end_date": end_date,
                "visit_type": visit_type,
                "limit": limit,
                "offset": offset
            },
            metadata={
                "role": user_context.role.value,
                "total_records": len(data)
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch visits: {str(e)}"
        )


@router.get("/heatmap", response_model=APIResponse)
async def get_heatmap(
    risk_level: Optional[str] = Query(default=None, description="Filter by risk level: critical, high, medium, low"),
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get current constituency heatmap
    
    **Parameters:**
    - risk_level: Filter by risk level
    
    **Returns:**
    - Ward-wise risk scores
    - Issue density
    - Policy sector breakdown
    - Resolution status
    """
    try:
        data = await bigquery_service.get_heatmap_current(
            risk_level=risk_level,
            user_role=user_context.role.value,
            user_constituency_id=user_context.constituency_id,
            user_constituencies=user_context.constituencies
        )
        
        return APIResponse(
            success=True,
            data=data,
            filters_applied={"risk_level": risk_level},
            metadata={
                "role": user_context.role.value,
                "total_records": len(data)
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch heatmap: {str(e)}"
        )


@router.get("/ward-coverage", response_model=APIResponse)
async def get_ward_coverage(
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get ward-wise coverage statistics
    
    **Returns:**
    - Total voters by ward
    - Visited households
    - Issue counts
    - Resolution rates
    - Coverage scores
    """
    try:
        data = await bigquery_service.get_ward_coverage(
            user_role=user_context.role.value,
            user_constituency_id=user_context.constituency_id,
            user_constituencies=user_context.constituencies
        )
        
        return APIResponse(
            success=True,
            data=data,
            metadata={
                "role": user_context.role.value,
                "total_records": len(data)
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch ward coverage: {str(e)}"
        )


@router.get("/visit-trends", response_model=APIResponse)
async def get_visit_trends(
    days: int = Query(default=30, ge=1, le=365, description="Number of days to fetch"),
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get visit trends over time
    
    **Parameters:**
    - days: Number of days to fetch (1-365)
    
    **Returns:**
    - Daily visit statistics
    - Unique locations visited
    - Average duration
    - Coverage percentage
    """
    try:
        data = await bigquery_service.get_visit_trends(
            days=days,
            user_role=user_context.role.value,
            user_constituency_id=user_context.constituency_id,
            user_constituencies=user_context.constituencies
        )
        
        return APIResponse(
            success=True,
            data=data,
            filters_applied={"days": days},
            metadata={
                "role": user_context.role.value,
                "total_records": len(data)
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch visit trends: {str(e)}"
        )


@router.get("/health")
async def health_check():
    """Health check for ground reality module"""
    return {
        "status": "healthy",
        "module": "ground_reality",
        "bigquery_dataset": bigquery_service.dataset_id
    }
