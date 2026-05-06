"""
Promise Tracker API endpoints - Module 5
Connected to BigQuery views
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


@router.get("/dashboard", response_model=APIResponse)
async def get_promises_dashboard(
    status: Optional[str] = Query(default=None, description="Filter by status: completed, in_progress, delayed, announced"),
    category: Optional[str] = Query(default=None, description="Filter by category"),
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get promises dashboard with comprehensive details
    
    **Parameters:**
    - status: Filter by promise status
    - category: Filter by promise category (infrastructure, health, education, etc.)
    
    **Returns:**
    - Complete promise details
    - Progress tracking
    - Budget utilization
    - Timeline status
    """
    try:
        data = await bigquery_service.get_promises_dashboard(
            status=status,
            category=category,
            user_role=user_context.role.value,
            user_constituency_id=user_context.constituency_id,
            user_constituencies=user_context.constituencies
        )
        
        return APIResponse(
            success=True,
            data=data,
            filters_applied={"status": status, "category": category},
            metadata={
                "role": user_context.role.value,
                "total_records": len(data)
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch promises dashboard: {str(e)}"
        )


@router.get("/overdue", response_model=APIResponse)
async def get_promises_overdue(
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get overdue promises requiring attention
    
    **Returns:**
    - Promises past target completion date
    - Days overdue
    - Progress status
    - Attention priority
    """
    try:
        data = await bigquery_service.get_promises_overdue(
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
            detail=f"Failed to fetch overdue promises: {str(e)}"
        )


@router.get("/by-category", response_model=APIResponse)
async def get_promises_by_category(
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get promises grouped by category
    
    **Returns:**
    - Category-wise promise count
    - Completion rates
    - Budget allocation
    - Average satisfaction scores
    """
    try:
        data = await bigquery_service.get_promises_by_category(
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
            detail=f"Failed to fetch promises by category: {str(e)}"
        )


@router.get("/completion-rate", response_model=APIResponse)
async def get_promise_completion_rate(
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get promise completion rate metrics
    
    **Returns:**
    - Overall completion rate
    - Average days to complete
    - On-track vs delayed promises
    - Budget utilization metrics
    """
    try:
        data = await bigquery_service.get_promise_completion_rate(
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
            detail=f"Failed to fetch completion rate: {str(e)}"
        )


@router.get("/health")
async def health_check():
    """Health check for promises module"""
    return {
        "status": "healthy",
        "module": "promises",
        "bigquery_dataset": bigquery_service.dataset_id
    }
