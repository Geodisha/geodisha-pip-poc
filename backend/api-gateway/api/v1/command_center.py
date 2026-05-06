"""
Command Center API endpoints - Module 1
Connected to BigQuery views
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
from typing import List, Optional

from core.bigquery_enhanced import BigQueryEnhancedService
from middleware.auth import get_optional_user
from schemas.responses import (
    APIResponse,
    ConstituencyOverview,
    KPITrend,
    ExecutiveSummary,
    TrendSummary,
    UserContext
)

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
        role="admin",  # Default to admin for testing to see all data
        constituency_id=None,
        constituencies=[],
        permissions=[]
    )


@router.get("/overview", response_model=APIResponse)
async def get_constituency_overview(
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get constituency overview dashboard
    
    **Role-based access:**
    - Admin: All constituencies
    - MP/MLA: Assigned constituency
    - Minister: Multiple constituencies
    - Volunteer: Assigned constituency
    """
    try:
        data = await bigquery_service.get_constituency_overview(
            user_role=user_context.role.value,
            user_constituency_id=user_context.constituency_id,
            user_constituencies=user_context.constituencies
        )
        
        return APIResponse(
            success=True,
            data=data,
            metadata={
                "role": user_context.role.value,
                "constituency_filter": user_context.constituency_id or "all",
                "total_records": len(data)
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch constituency overview: {str(e)}"
        )


@router.get("/kpi-trends", response_model=APIResponse)
async def get_kpi_trends(
    days: int = Query(default=30, ge=1, le=365, description="Number of days to fetch"),
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get KPI trends over time
    
    **Parameters:**
    - days: Number of days to fetch (1-365)
    
    **Returns:**
    - Daily KPI metrics including visits, alerts, promises, booth coverage
    """
    try:
        data = await bigquery_service.get_kpi_trends(
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
            detail=f"Failed to fetch KPI trends: {str(e)}"
        )


@router.get("/executive-summary", response_model=APIResponse)
async def get_executive_summary(
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get executive summary with top issues and priority actions
    
    **Returns:**
    - Current executive summary with key insights
    - Top issues requiring attention
    - Priority actions
    - Resource allocation status
    """
    try:
        data = await bigquery_service.get_executive_summary(
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
            detail=f"Failed to fetch executive summary: {str(e)}"
        )


@router.get("/trends", response_model=APIResponse)
async def get_trends_summary(
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get trends summary including health score and sentiment changes
    
    **Returns:**
    - Health score changes
    - Sentiment trends
    - Visit frequency
    - Issue resolution rates
    """
    try:
        data = await bigquery_service.get_trends_summary(
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
            detail=f"Failed to fetch trends summary: {str(e)}"
        )


@router.get("/health")
async def health_check():
    """Health check for command center module"""
    return {
        "status": "healthy",
        "module": "command_center",
        "bigquery_dataset": bigquery_service.dataset_id
    }
