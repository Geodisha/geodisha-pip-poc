"""
Constituencies API endpoints - Connected to BigQuery
"""

from fastapi import APIRouter, Depends, HTTPException, status, Request, Query
from typing import List, Dict, Any, Optional

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


@router.get("/", response_model=APIResponse)
async def get_constituencies(
    user_role: str = Query(default="admin", description="User role for filtering"),
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get all constituencies from BigQuery master_data table
    
    **Parameters:**
    - user_role: User role (used for filtering)
    
    **Returns:**
    - List of constituency names and IDs from geo_pulse_data.master_data
    """
    try:
        constituencies = await bigquery_service.get_constituency_data(
            user_role=user_context.role.value,
            user_constituency_id=user_context.constituency_id,
            user_constituencies=user_context.constituencies
        )
        
        return APIResponse(
            success=True,
            data=constituencies,
            metadata={
                "total_constituencies": len(constituencies),
                "role": user_context.role.value,
                "source": "geo_pulse_data.master_data"
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch constituencies: {str(e)}"
        )


@router.get("/{constituency_id}", response_model=APIResponse)
async def get_constituency(
    constituency_id: str,
    user_context: UserContext = Depends(get_user_context)
):
    """Get constituency details"""
    try:
        constituencies = await bigquery_service.get_constituency_data(
            user_role=user_context.role.value,
            user_constituency_id=user_context.constituency_id,
            user_constituencies=user_context.constituencies
        )
        constituency = next((c for c in constituencies if c.get("constituency_id") == constituency_id), None)
        
        if not constituency:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Constituency {constituency_id} not found"
            )
        
        return APIResponse(
            success=True,
            data=constituency,
            metadata={"source": "geo_pulse_data.master_data"}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch constituency: {str(e)}"
        )


@router.get("/{constituency_id}/stats", response_model=APIResponse)
async def get_constituency_stats(
    constituency_id: str,
    user_context: UserContext = Depends(get_user_context)
):
    """Get constituency statistics - combining multiple data sources"""
    try:
        # Get constituency overview
        overview = await bigquery_service.get_constituency_overview(
            user_role=user_context.role.value,
            user_constituency_id=constituency_id,
            user_constituencies=user_context.constituencies
        )
        
        # Get KPI trends
        trends = await bigquery_service.get_kpi_trends(
            days=30,
            user_role=user_context.role.value,
            user_constituency_id=constituency_id,
            user_constituencies=user_context.constituencies
        )
        
        # Filter for specific constituency
        constituency_overview = next((o for o in overview if o.get("constituency_id") == constituency_id), {})
        
        return APIResponse(
            success=True,
            data={
                "constituency_id": constituency_id,
                "overview": constituency_overview,
                "trends_30d": trends,
                "source": "geo_pulse_data views"
            },
            metadata={
                "data_source": "BigQuery Enhanced Views",
                "role": user_context.role.value
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch constituency stats: {str(e)}"
        )


@router.get("/health")
async def health_check():
    """Health check for constituencies module"""
    return {
        "status": "healthy",
        "module": "constituencies",
        "message": "Constituencies API is running"
    }

