"""
Google Cloud Pub/Sub client and utilities
"""

from google.cloud import pubsub_v1
from google.cloud.pubsub_v1.types import PubsubMessage
import json
import logging
from typing import Dict, Any

from config import settings

logger = logging.getLogger(__name__)

# Global publisher client
_publisher_client = None


def initialize_pubsub():
    """Initialize Pub/Sub publisher client"""
    global _publisher_client
    
    try:
        if not _publisher_client:
            _publisher_client = pubsub_v1.PublisherClient()
            logger.info("Pub/Sub initialized successfully")
    except Exception as e:
        logger.error(f"Error initializing Pub/Sub: {e}")
        raise


def get_publisher() -> pubsub_v1.PublisherClient:
    """Get Pub/Sub publisher client"""
    if not _publisher_client:
        initialize_pubsub()
    return _publisher_client


class PubSubService:
    """Service for publishing messages to Pub/Sub topics"""
    
    def __init__(self):
        self.publisher = get_publisher()
        self.project_id = settings.PROJECT_ID
    
    def _get_topic_path(self, topic_name: str) -> str:
        """Get full topic path"""
        return f"projects/{self.project_id}/topics/{topic_name}"
    
    async def publish_message(self, topic_name: str, data: Dict[str, Any], attributes: Dict[str, str] = None) -> str:
        """
        Publish a message to a Pub/Sub topic
        
        Args:
            topic_name: Name of the topic
            data: Message data as dictionary
            attributes: Optional message attributes
            
        Returns:
            Message ID
        """
        try:
            topic_path = self._get_topic_path(topic_name)
            
            # Convert data to JSON bytes
            message_bytes = json.dumps(data).encode("utf-8")
            
            # Publish message
            future = self.publisher.publish(
                topic_path,
                message_bytes,
                **(attributes or {})
            )
            
            message_id = future.result()
            logger.info(f"Published message {message_id} to {topic_name}")
            
            return message_id
        except Exception as e:
            logger.error(f"Error publishing message to {topic_name}: {e}")
            raise
    
    async def publish_grievance_event(self, event_type: str, grievance_data: Dict[str, Any]) -> str:
        """Publish grievance event"""
        return await self.publish_message(
            settings.GRIEVANCE_TOPIC,
            grievance_data,
            {"event_type": event_type}
        )
    
    async def publish_visit_event(self, event_type: str, visit_data: Dict[str, Any]) -> str:
        """Publish visit event"""
        return await self.publish_message(
            settings.VISIT_TOPIC,
            visit_data,
            {"event_type": event_type}
        )
    
    async def publish_analytics_event(self, event_type: str, analytics_data: Dict[str, Any]) -> str:
        """Publish analytics event"""
        return await self.publish_message(
            settings.ANALYTICS_TOPIC,
            analytics_data,
            {"event_type": event_type}
        )
