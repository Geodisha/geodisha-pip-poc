"""
Election War Room API endpoints - Module 4
Connected to BigQuery views for booth analysis
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


@router.get("/booth-scores", response_model=APIResponse)
async def get_booth_scores(
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get booth-wise score summary
    
    **Returns:**
    - Booth scores and rankings
    - Historical performance
    - Swing potential
    - Risk categories
    """
    try:
        data = await bigquery_service.get_booth_scores_summary(
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
            detail=f"Failed to fetch booth scores: {str(e)}"
        )


@router.get("/readiness", response_model=APIResponse)
async def get_election_readiness(
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get election readiness assessment
    
    **Returns:**
    - Overall readiness score
    - Booth coverage percentage
    - Agent deployment status
    - Resource status
    - Turnout predictions
    """
    try:
        data = await bigquery_service.get_election_readiness(
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
            detail=f"Failed to fetch election readiness: {str(e)}"
        )


@router.get("/risk-matrix", response_model=APIResponse)
async def get_booth_risk_matrix(
    risk_category: Optional[str] = Query(default=None, description="Filter by risk: critical, high, medium, low"),
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get booth risk matrix
    
    **Parameters:**
    - risk_category: Filter by risk category
    
    **Returns:**
    - Booth-wise risk assessment
    - Strength scores
    - Performance predictions
    """
    try:
        data = await bigquery_service.get_booth_risk_matrix(
            risk_category=risk_category,
            user_role=user_context.role.value,
            user_constituency_id=user_context.constituency_id,
            user_constituencies=user_context.constituencies
        )
        
        return APIResponse(
            success=True,
            data=data,
            filters_applied={"risk_category": risk_category},
            metadata={
                "role": user_context.role.value,
                "total_records": len(data)
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch booth risk matrix: {str(e)}"
        )


@router.get("/swing-analysis", response_model=APIResponse)
async def get_swing_analysis(
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get swing analysis for booths
    
    **Returns:**
    - Swing potential by booth
    - Historical margins
    - Predicted swing percentages
    - Target booth identification
    """
    try:
        data = await bigquery_service.get_swing_analysis(
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
            detail=f"Failed to fetch swing analysis: {str(e)}"
        )


@router.get("/health")
async def health_check():
    """Health check for election war room module"""
    return {
        "status": "healthy",
        "module": "election_war_room",
        "bigquery_dataset": bigquery_service.dataset_id
    }
