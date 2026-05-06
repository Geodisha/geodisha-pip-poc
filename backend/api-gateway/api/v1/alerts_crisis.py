"""
Alerts & Crisis Management API endpoints - Module 6
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


@router.get("/active", response_model=APIResponse)
async def get_alerts_active(
    priority: Optional[str] = Query(default=None, description="Filter by priority: critical, high, medium, low"),
    alert_type: Optional[str] = Query(default=None, description="Filter by type: emergency, reminder, risk, crisis"),
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get active alerts
    
    **Parameters:**
    - priority: Filter by priority level
    - alert_type: Filter by alert type
    
    **Returns:**
    - Currently open alerts
    - Days open
    - Escalation status
    """
    try:
        data = await bigquery_service.get_alerts_active(
            priority=priority,
            alert_type=alert_type,
            user_role=user_context.role.value,
            user_constituency_id=user_context.constituency_id,
            user_constituencies=user_context.constituencies
        )
        
        return APIResponse(
            success=True,
            data=data,
            filters_applied={"priority": priority, "alert_type": alert_type},
            metadata={
                "role": user_context.role.value,
                "total_records": len(data)
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch active alerts: {str(e)}"
        )


@router.get("/statistics", response_model=APIResponse)
async def get_alerts_statistics(
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get alert statistics
    
    **Returns:**
    - Total alerts
    - Resolved vs pending
    - Average resolution time
    - Category and priority breakdown
    """
    try:
        data = await bigquery_service.get_alerts_statistics(
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
            detail=f"Failed to fetch alert statistics: {str(e)}"
        )


@router.get("/crisis-dashboard", response_model=APIResponse)
async def get_crisis_dashboard(
    severity_level: Optional[str] = Query(default=None, description="Filter by severity: critical, high, medium, low"),
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get crisis management dashboard
    
    **Parameters:**
    - severity_level: Filter by crisis severity
    
    **Returns:**
    - Active crisis events
    - Affected areas
    - Response actions
    - Resource deployment
    """
    try:
        data = await bigquery_service.get_crisis_dashboard(
            severity_level=severity_level,
            user_role=user_context.role.value,
            user_constituency_id=user_context.constituency_id,
            user_constituencies=user_context.constituencies
        )
        
        return APIResponse(
            success=True,
            data=data,
            filters_applied={"severity_level": severity_level},
            metadata={
                "role": user_context.role.value,
                "total_records": len(data)
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch crisis dashboard: {str(e)}"
        )


@router.get("/resolution-metrics", response_model=APIResponse)
async def get_alert_resolution_metrics(
    user_context: UserContext = Depends(get_user_context)
):
    """
    Get alert resolution performance metrics
    
    **Returns:**
    - Average resolution time by type
    - Resolution rates
    - Escalation rates
    - Performance trends
    """
    try:
        data = await bigquery_service.get_alert_resolution_metrics(
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
            detail=f"Failed to fetch resolution metrics: {str(e)}"
        )


@router.get("/health")
async def health_check():
    """Health check for alerts & crisis module"""
    return {
        "status": "healthy",
        "module": "alerts_crisis",
        "bigquery_dataset": bigquery_service.dataset_id
    }
