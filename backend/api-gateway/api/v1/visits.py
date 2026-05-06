"""
Visits API endpoints - Connected to BigQuery visit_records_bhongir table
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

from core.bigquery_enhanced import BigQueryEnhancedService
from middleware.auth import get_current_user

router = APIRouter()
bigquery_service = BigQueryEnhancedService()


@router.get("/", response_model=dict)
async def get_visits(
    constituency_id: Optional[str] = Query(None, description="Filter by constituency ID"),
    limit: int = Query(100, ge=1, le=500, description="Number of records to return"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    current_user: dict = Depends(get_current_user)
):
    """
    Get visit records from BigQuery visit_records_bhongir table
    """
    try:
        visits = await bigquery_service.get_visit_records(
            constituency_id=constituency_id,
            limit=limit,
            offset=offset
        )
        
        return {
            "data": visits,
            "total": len(visits),
            "limit": limit,
            "offset": offset
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch visits: {str(e)}"
        )


@router.get("/statistics", response_model=dict)
async def get_visit_statistics(
    constituency_id: Optional[str] = Query(None, description="Filter by constituency ID"),
    current_user: dict = Depends(get_current_user)
):
    """Get visit statistics from BigQuery"""
    try:
        stats = await bigquery_service.get_visit_statistics(
            constituency_id=constituency_id
        )
        
        return {
            "statistics": stats,
            "constituency_id": constituency_id
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch visit statistics: {str(e)}"
        )


@router.get("/locations", response_model=dict)
async def get_location_visits(
    constituency_id: Optional[str] = Query(None, description="Filter by constituency ID"),
    limit: int = Query(50, ge=1, le=200, description="Number of locations to return"),
    current_user: dict = Depends(get_current_user)
):
    """Get visits grouped by location"""
    try:
        locations = await bigquery_service.get_location_visits(
            constituency_id=constituency_id,
            limit=limit
        )
        
        return {
            "data": locations,
            "total": len(locations)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch location visits: {str(e)}"
        )


@router.get("/timeline", response_model=dict)
async def get_visit_timeline(
    constituency_id: Optional[str] = Query(None, description="Filter by constituency ID"),
    days: int = Query(30, ge=1, le=365, description="Number of days to include"),
    current_user: dict = Depends(get_current_user)
):
    """Get visit timeline for last N days"""
    try:
        timeline = await bigquery_service.get_visit_timeline(
            constituency_id=constituency_id,
            days=days
        )
        
        return {
            "data": timeline,
            "days": days,
            "constituency_id": constituency_id
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch visit timeline: {str(e)}"
        )


@router.get("/search", response_model=dict)
async def search_visits(
    q: str = Query(..., min_length=2, description="Search term"),
    constituency_id: Optional[str] = Query(None, description="Filter by constituency ID"),
    limit: int = Query(50, ge=1, le=200, description="Number of results to return"),
    current_user: dict = Depends(get_current_user)
):
    """Search visits by location or notes"""
    try:
        results = await bigquery_service.search_visits(
            search_term=q,
            constituency_id=constituency_id,
            limit=limit
        )
        
        return {
            "data": results,
            "total": len(results),
            "search_term": q
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to search visits: {str(e)}"
        )
