"""
AI Intelligence Hub API endpoints - Module 2
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


@router.get("/recommendations", response_model=APIResponse)
async def get_ai_recommendations(
    status: Optional[str] = Query(default=None, description="Filter by status: open, in_progress, completed, dismissed"),
    priority: Optional[str] = Query(default=None, description="Filter by priority: critical, high, medium, low"),
    category: Optional[str] = Query(default=None, description="Filter by category: visit, issue, promise, crisis"),
    limit: int = Query(default=50, ge=1, le=200, description="Number of recommendations to return"),
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get AI-generated recommendations
    
    **Parameters:**
    - status: Filter by recommendation status
    - priority: Filter by priority level
    - category: Filter by recommendation category
    - limit: Maximum number of results (1-200)
    
    **Returns:**
    - AI recommendations sorted by priority and confidence
    """
    try:
        data = await bigquery_service.get_ai_recommendations(
            status=status,
            priority=priority,
            category=category,
            limit=limit,
            user_role=user_context.role.value,
            user_constituency_id=user_context.constituency_id,
            user_constituencies=user_context.constituencies
        )
        
        return APIResponse(
            success=True,
            data=data,
            filters_applied={
                "status": status,
                "priority": priority,
                "category": category,
                "limit": limit
            },
            metadata={
                "role": user_context.role.value,
                "total_records": len(data)
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch AI recommendations: {str(e)}"
        )


@router.get("/media-briefing", response_model=APIResponse)
async def get_media_briefing(
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get latest media briefing and talking points
    
    **Returns:**
    - Current talking points
    - Key messages
    - Supporting data
    - Target audience insights
    """
    try:
        data = await bigquery_service.get_media_briefing(
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
            detail=f"Failed to fetch media briefing: {str(e)}"
        )


@router.get("/influencer-map", response_model=APIResponse)
async def get_influencer_map(
    min_score: int = Query(default=0, ge=0, le=100, description="Minimum influence score"),
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get strategic influencer mapping
    
    **Parameters:**
    - min_score: Minimum influence score (0-100)
    
    **Returns:**
    - Key influencers and their network
    - Influence scores
    - Engagement recommendations
    """
    try:
        data = await bigquery_service.get_influencer_map(
            min_score=min_score,
            user_role=user_context.role.value,
            user_constituency_id=user_context.constituency_id,
            user_constituencies=user_context.constituencies
        )
        
        return APIResponse(
            success=True,
            data=data,
            filters_applied={"min_score": min_score},
            metadata={
                "role": user_context.role.value,
                "total_records": len(data)
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch influencer map: {str(e)}"
        )


@router.get("/visit-priorities", response_model=APIResponse)
async def get_visit_priorities(
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get AI-recommended visit priorities
    
    **Returns:**
    - Priority locations for visits
    - Visit priority scores
    - Best times to visit
    - Expected impact
    """
    try:
        data = await bigquery_service.get_visit_priority_list(
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
            detail=f"Failed to fetch visit priorities: {str(e)}"
        )


@router.get("/health")
async def health_check():
    """Health check for AI intelligence module"""
    return {
        "status": "healthy",
        "module": "ai_intelligence",
        "bigquery_dataset": bigquery_service.dataset_id
    }
