"""
Firebase Admin SDK initialization and utilities
"""

import firebase_admin
from firebase_admin import credentials, firestore, auth
import logging
from typing import Dict, Any, Optional

from config import settings

logger = logging.getLogger(__name__)

# Global Firebase app instance
_firebase_app = None
_firestore_client = None


def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    global _firebase_app, _firestore_client
    
    try:
        if not _firebase_app:
            if settings.FIREBASE_CREDENTIALS_PATH:
                cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
                _firebase_app = firebase_admin.initialize_app(cred)
            else:
                # Use Application Default Credentials in GCP
                _firebase_app = firebase_admin.initialize_app()
            
            _firestore_client = firestore.client()
            logger.info("Firebase initialized successfully")
    except Exception as e:
        logger.error(f"Error initializing Firebase: {e}")
        raise


def get_firestore_client():
    """Get Firestore client instance"""
    if not _firestore_client:
        initialize_firebase()
    return _firestore_client


async def verify_firebase_token(token: str) -> Dict[str, Any]:
    """
    Verify Firebase ID token
    
    Args:
        token: Firebase ID token
        
    Returns:
        Decoded token claims
        
    Raises:
        ValueError: If token is invalid
    """
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        logger.error(f"Token verification failed: {e}")
        raise ValueError("Invalid token")


class FirestoreService:
    """Service for Firestore operations"""
    
    def __init__(self):
        self.db = get_firestore_client()
    
    async def get_document(self, collection: str, document_id: str) -> Optional[Dict[str, Any]]:
        """Get a document from Firestore"""
        try:
            doc_ref = self.db.collection(collection).document(document_id)
            doc = doc_ref.get()
            
            if doc.exists:
                return doc.to_dict()
            return None
        except Exception as e:
            logger.error(f"Error getting document: {e}")
            raise
    
    async def create_document(self, collection: str, data: Dict[str, Any], document_id: Optional[str] = None) -> str:
        """Create a document in Firestore"""
        try:
            if document_id:
                doc_ref = self.db.collection(collection).document(document_id)
                doc_ref.set(data)
                return document_id
            else:
                doc_ref = self.db.collection(collection).add(data)
                return doc_ref[1].id
        except Exception as e:
            logger.error(f"Error creating document: {e}")
            raise
    
    async def update_document(self, collection: str, document_id: str, data: Dict[str, Any]) -> None:
        """Update a document in Firestore"""
        try:
            doc_ref = self.db.collection(collection).document(document_id)
            doc_ref.update(data)
        except Exception as e:
            logger.error(f"Error updating document: {e}")
            raise
    
    async def delete_document(self, collection: str, document_id: str) -> None:
        """Delete a document from Firestore"""
        try:
            doc_ref = self.db.collection(collection).document(document_id)
            doc_ref.delete()
        except Exception as e:
            logger.error(f"Error deleting document: {e}")
            raise
    
    async def query_collection(
        self,
        collection: str,
        filters: Optional[list] = None,
        order_by: Optional[str] = None,
        limit: Optional[int] = None
    ) -> list:
        """Query a collection with filters"""
        try:
            query = self.db.collection(collection)
            
            if filters:
                for field, operator, value in filters:
                    query = query.where(field, operator, value)
            
            if order_by:
                query = query.order_by(order_by)
            
            if limit:
                query = query.limit(limit)
            
            docs = query.stream()
            return [{"id": doc.id, **doc.to_dict()} for doc in docs]
        except Exception as e:
            logger.error(f"Error querying collection: {e}")
            raise
