"""
Enhanced BigQuery service for GeoDisha Platform
Supports all 6 modules with views and role-based filtering
WITH CACHING for improved performance
"""

from google.cloud import bigquery
from google.api_core import retry
from google.oauth2 import service_account
import logging
import os
from typing import Dict, Any, List, Optional
from datetime import datetime, date
from decimal import Decimal

from config import settings
from core.cache import get_cache

logger = logging.getLogger(__name__)

# Global BigQuery client
_bigquery_client = None
# Global cache instance
_cache = get_cache()


def get_bigquery_client() -> bigquery.Client:
    """
    Get or create BigQuery client with proper authentication
    
    Authentication methods (in order of precedence):
    1. Service Account key file (GOOGLE_APPLICATION_CREDENTIALS)
    2. Application Default Credentials (gcloud auth for local dev)
    3. Workload Identity (automatic in GCP environments)
    """
    global _bigquery_client
    
    if not _bigquery_client:
        project_id = settings.BIGQUERY_PROJECT_ID or settings.PROJECT_ID
        
        # Check for service account credentials file
        creds_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        
        if creds_path and os.path.exists(creds_path):
            logger.info(f"Using service account credentials from: {creds_path}")
            credentials = service_account.Credentials.from_service_account_file(
                creds_path,
                scopes=["https://www.googleapis.com/auth/bigquery"]
            )
            _bigquery_client = bigquery.Client(
                project=project_id,
                credentials=credentials
            )
        else:
            # Fallback to Application Default Credentials
            logger.info("Using Application Default Credentials (gcloud auth or Workload Identity)")
            _bigquery_client = bigquery.Client(project=project_id)
        
        logger.info(f"✅ BigQuery client initialized for project: {_bigquery_client.project}")
    
    return _bigquery_client


class BigQueryEnhancedService:
    """Enhanced BigQuery service with support for all modules and views"""
    
    def __init__(self):
        self.client = get_bigquery_client()
        self.dataset_id = settings.BIGQUERY_DATASET
        self.project_id = self.client.project
    
    def _get_table_path(self, table_name: str) -> str:
        """Get full table path"""
        return f"{self.project_id}.{self.dataset_id}.{table_name}"
    
    def _serialize_row(self, row_dict: Dict[str, Any]) -> Dict[str, Any]:
        """Convert BigQuery row to JSON-serializable format"""
        serialized = {}
        for key, value in row_dict.items():
            if isinstance(value, (datetime, date)):
                serialized[key] = value.isoformat()
            elif isinstance(value, Decimal):
                serialized[key] = float(value)
            elif value is None:
                serialized[key] = None
            else:
                serialized[key] = value
        return serialized
    
    @retry.Retry(deadline=30)
    async def execute_query(
        self, 
        query: str, 
        parameters: Optional[List] = None,
        cache_ttl: int = 300  # 5 minutes default cache
    ) -> List[Dict[str, Any]]:
        """
        Execute a BigQuery query and return results with caching
        
        Args:
            query: SQL query to execute
            parameters: Optional query parameters
            cache_ttl: Cache time-to-live in seconds (default 5 minutes)
            
        Returns:
            List of dictionaries containing query results
        """
        # Try to get from cache first (using query as key and empty params)
        cached_result = _cache.get(query, {})
        if cached_result is not None:
            logger.info(f"Cache HIT for query (returned {len(cached_result)} rows)")
            return cached_result
        
        try:
            job_config = bigquery.QueryJobConfig()
            
            if parameters:
                job_config.query_parameters = parameters
            
            query_job = self.client.query(query, job_config=job_config)
            results = query_job.result()
            
            # Convert results to list of dicts
            rows = []
            for row in results:
                row_dict = dict(row.items())
                rows.append(self._serialize_row(row_dict))
            
            # Cache the result
            _cache.set(query, {}, rows, ttl_seconds=cache_ttl)
            
            logger.info(f"Query executed successfully, returned {len(rows)} rows (cached for {cache_ttl}s)")
            return rows
            
        except Exception as e:
            logger.error(f"Error executing BigQuery query: {e}")
            logger.error(f"Query: {query}")
            raise
    
    def _apply_role_filter(
        self, 
        base_query: str, 
        user_role: str, 
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> str:
        """
        Apply role-based filtering to queries
        
        Args:
            base_query: Base SQL query
            user_role: User's role (admin, mp_mla, minister, volunteer, etc.)
            user_constituency_id: User's primary constituency
            user_constituencies: List of constituencies user has access to
            
        Returns:
            Modified query with role filters
        """
        # Admin: See all constituencies
        if user_role in ["admin", "super_admin"]:
            return base_query
        
        # MP/MLA: See only assigned constituency
        elif user_role in ["mp", "mla", "mp_mla"]:
            if user_constituency_id:
                if "WHERE" in base_query.upper():
                    return base_query + f" AND constituency_id = '{user_constituency_id}'"
                else:
                    return base_query + f" WHERE constituency_id = '{user_constituency_id}'"
        
        # Minister: See multiple constituencies
        elif user_role == "minister":
            if user_constituencies:
                constituencies_str = "', '".join(user_constituencies)
                if "WHERE" in base_query.upper():
                    return base_query + f" AND constituency_id IN ('{constituencies_str}')"
                else:
                    return base_query + f" WHERE constituency_id IN ('{constituencies_str}')"
        
        # Volunteer: Limited to single constituency
        elif user_role == "volunteer":
            if user_constituency_id:
                if "WHERE" in base_query.upper():
                    return base_query + f" AND constituency_id = '{user_constituency_id}'"
                else:
                    return base_query + f" WHERE constituency_id = '{user_constituency_id}'"
        
        # Default: No data
        return base_query + " WHERE 1=0"
    
    # ==================== Module 1: Command Center ====================
    
    async def get_constituency_overview(
        self,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get constituency overview from v_constituency_overview_latest"""
        view_path = self._get_table_path("v_constituency_overview_latest")
        
        query = f"SELECT * FROM `{view_path}` LIMIT 100"  # Added LIMIT
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query, cache_ttl=600)  # Cache for 10 mins
    
    async def get_kpi_trends(
        self,
        days: int = 30,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get KPI trends from v_kpi_trends_30d"""
        view_path = self._get_table_path("v_kpi_trends_30d")
        
        query = f"SELECT * FROM `{view_path}` WHERE report_date >= DATE_SUB(CURRENT_DATE(), INTERVAL {days} DAY) ORDER BY report_date DESC LIMIT 1000"  # Added LIMIT
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query, cache_ttl=300)  # Cache for 5 mins
    
    async def get_executive_summary(
        self,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get executive summary from v_executive_summary_current"""
        view_path = self._get_table_path("v_executive_summary_current")
        
        query = f"SELECT * FROM `{view_path}`"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_trends_summary(
        self,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get trends summary from v_trends_summary"""
        view_path = self._get_table_path("v_trends_summary")
        
        query = f"SELECT * FROM `{view_path}` ORDER BY constituency_id, metric_name LIMIT 30"  # Fixed: Removed trend_date
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    # ==================== Module 2: AI Intelligence Hub ====================
    
    async def get_ai_recommendations(
        self,
        status: Optional[str] = None,
        priority: Optional[str] = None,
        category: Optional[str] = None,  # maps to recommendation_type
        limit: int = 50,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get AI recommendations from v_ai_recommendations_active"""
        view_path = self._get_table_path("v_ai_recommendations_active")
        
        query = f"SELECT * FROM `{view_path}` WHERE 1=1"
        
        if status:
            query += f" AND status = '{status}'"
        if priority:
            query += f" AND priority = '{priority}'"
        if category:
            query += f" AND recommendation_type = '{category}'"  # Fixed: category -> recommendation_type
        
        query += f" ORDER BY priority_score DESC, created_at DESC LIMIT {limit}"  # Fixed: created_date -> created_at
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_media_briefing(
        self,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get media briefing from v_media_briefing_latest"""
        view_path = self._get_table_path("v_media_briefing_latest")
        
        query = f"SELECT * FROM `{view_path}` ORDER BY created_at DESC"  # Fixed: generated_date -> created_at
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_influencer_map(
        self,
        min_score: int = 0,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get influencer map from v_influencer_map"""
        view_path = self._get_table_path("v_influencer_map")
        
        query = f"SELECT * FROM `{view_path}` WHERE influence_score >= {min_score} ORDER BY influence_score DESC"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_visit_priority_list(
        self,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get visit priority list from v_visit_priority_list"""
        view_path = self._get_table_path("v_visit_priority_list")
        
        query = f"SELECT * FROM `{view_path}` ORDER BY priority_score DESC LIMIT 50"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    # ==================== Module 3: Ground Reality ====================
    
    async def get_visits_enhanced(
        self,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
        visit_type: Optional[str] = None,
        limit: int = 100,
        offset: int = 0,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get enhanced visits from v_visits_enhanced"""
        view_path = self._get_table_path("v_visits_enhanced")
        
        query = f"SELECT * FROM `{view_path}` WHERE 1=1"
        
        if start_date:
            query += f" AND visit_date >= '{start_date}'"
        if end_date:
            query += f" AND visit_date <= '{end_date}'"
        if visit_type:
            query += f" AND visit_type = '{visit_type}'"
        
        query += f" ORDER BY visit_date DESC LIMIT {limit} OFFSET {offset}"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_heatmap_current(
        self,
        risk_level: Optional[str] = None,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get current heatmap from v_heatmap_current"""
        view_path = self._get_table_path("v_heatmap_current")
        
        query = f"SELECT * FROM `{view_path}` WHERE 1=1"
        
        if risk_level:
            query += f" AND ward_risk_level = '{risk_level}'"
        
        query += " ORDER BY ward_risk_level DESC"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_ward_coverage(
        self,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get ward coverage from v_ward_coverage"""
        view_path = self._get_table_path("v_ward_coverage")
        
        query = f"SELECT * FROM `{view_path}` ORDER BY coverage_priority DESC"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_visit_trends(
        self,
        days: int = 30,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get visit trends from v_visit_trends"""
        view_path = self._get_table_path("v_visit_trends")
        
        query = f"SELECT * FROM `{view_path}` ORDER BY week_start DESC LIMIT {days}"  # Fixed: report_date -> week_start
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    # ==================== Module 4: Election War Room ====================
    
    async def get_booth_scores_summary(
        self,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get booth scores summary from v_booth_scores_summary"""
        view_path = self._get_table_path("v_booth_scores_summary")
        
        query = f"SELECT * FROM `{view_path}` ORDER BY booth_score DESC"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_election_readiness(
        self,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get election readiness from v_election_readiness"""
        view_path = self._get_table_path("v_election_readiness")
        
        query = f"SELECT * FROM `{view_path}`"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_booth_risk_matrix(
        self,
        risk_category: Optional[str] = None,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get booth risk matrix from v_booth_risk_matrix"""
        view_path = self._get_table_path("v_booth_risk_matrix")
        
        query = f"SELECT * FROM `{view_path}` WHERE 1=1"
        
        if risk_category:
            query += f" AND risk_category = '{risk_category}'"
        
        query += " ORDER BY booth_score DESC"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_swing_analysis(
        self,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get swing analysis from v_swing_analysis"""
        view_path = self._get_table_path("v_swing_analysis")
        
        query = f"SELECT * FROM `{view_path}` ORDER BY swing_classification DESC"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    # ==================== Module 5: Promises ====================
    
    async def get_promises_dashboard(
        self,
        status: Optional[str] = None,
        category: Optional[str] = None,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get promises dashboard from v_promises_dashboard"""
        view_path = self._get_table_path("v_promises_dashboard")
        
        query = f"SELECT * FROM `{view_path}` WHERE 1=1"
        
        if status:
            query += f" AND status = '{status}'"
        if category:
            query += f" AND promise_category = '{category}'"
        
        query += " ORDER BY attention_priority DESC, target_completion_date ASC"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_promises_overdue(
        self,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get overdue promises from v_promises_overdue"""
        view_path = self._get_table_path("v_promises_overdue")
        
        query = f"SELECT * FROM `{view_path}` ORDER BY days_overdue DESC"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_promises_by_category(
        self,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get promises by category from v_promises_by_category"""
        view_path = self._get_table_path("v_promises_by_category")
        
        query = f"SELECT * FROM `{view_path}` ORDER BY total_promises DESC"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_promise_completion_rate(
        self,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get promise completion rate from v_promise_completion_rate"""
        view_path = self._get_table_path("v_promise_completion_rate")
        
        query = f"SELECT * FROM `{view_path}` ORDER BY delivery_velocity DESC"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    # ==================== Module 6: Alerts & Crisis ====================
    
    async def get_alerts_active(
        self,
        priority: Optional[str] = None,
        alert_type: Optional[str] = None,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get active alerts from v_alerts_active"""
        view_path = self._get_table_path("v_alerts_active")
        
        query = f"SELECT * FROM `{view_path}` WHERE 1=1"
        
        if priority:
            query += f" AND priority = '{priority}'"
        if alert_type:
            query += f" AND alert_type = '{alert_type}'"
        
        query += " ORDER BY priority_score DESC, created_at DESC"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_alerts_statistics(
        self,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get alerts statistics from v_alerts_statistics"""
        view_path = self._get_table_path("v_alerts_statistics")
        
        query = f"SELECT * FROM `{view_path}`"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_crisis_dashboard(
        self,
        severity_level: Optional[str] = None,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get crisis dashboard from v_crisis_dashboard"""
        view_path = self._get_table_path("v_crisis_dashboard")
        
        query = f"SELECT * FROM `{view_path}` WHERE 1=1"
        
        if severity_level:
            query += f" AND severity_level = '{severity_level}'"
        
        query += " ORDER BY political_risk_score DESC, start_time DESC"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    async def get_alert_resolution_metrics(
        self,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Get alert resolution metrics from v_alert_resolution_metrics"""
        view_path = self._get_table_path("v_alert_resolution_metrics")
        
        query = f"SELECT * FROM `{view_path}` ORDER BY resolution_rate ASC"
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        
        return await self.execute_query(query)
    
    # ==================== Constituency Data ====================
    
    async def get_constituency_data(
        self,
        user_role: str = "admin",
        user_constituency_id: Optional[str] = None,
        user_constituencies: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """
        Get list of all constituencies from constituency_overview table
        
        Args:
            user_role: User's role for filtering
            user_constituency_id: User's primary constituency
            user_constituencies: List of constituencies user has access to
            
        Returns:
            List of constituencies with constituency_id and constituency_name
        """
        table_path = self._get_table_path("constituency_overview")
        
        query = f"""
        SELECT DISTINCT
            constituency_id,
            constituency_name
        FROM `{table_path}`
        WHERE constituency_id IS NOT NULL 
          AND constituency_name IS NOT NULL
        """
        
        # Apply role-based filtering
        query = self._apply_role_filter(query, user_role, user_constituency_id, user_constituencies)
        query += " ORDER BY constituency_name"
        
        return await self.execute_query(query)
