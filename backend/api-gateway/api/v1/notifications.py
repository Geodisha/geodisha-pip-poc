"""Notifications API endpoints"""
from fastapi import APIRouter
router = APIRouter()

@router.get("/")
async def get_notifications():
    """Get user notifications"""
    return {"message": "Get notifications"}

@router.patch("/{notification_id}/read")
async def mark_notification_read(notification_id: str):
    """Mark notification as read"""
    return {"message": f"Mark {notification_id} as read"}

@router.post("/subscribe")
async def subscribe_to_topic():
    """Subscribe to notification topic"""
    return {"message": "Subscribe to topic"}
