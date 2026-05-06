"""
Pydantic response models for all GeoDisha modules
"""

from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from enum import Enum


# ==================== Common Models ====================

class PaginationInfo(BaseModel):
    """Pagination information"""
    total: int
    page: int
    page_size: int
    total_pages: int


class APIResponse(BaseModel):
    """Standard API response wrapper"""
    success: bool = True
    data: Any
    pagination: Optional[PaginationInfo] = None
    filters_applied: Optional[Dict[str, Any]] = None
    metadata: Optional[Dict[str, Any]] = None


# ==================== Module 1: Command Center ====================

class ConstituencyOverview(BaseModel):
    """Constituency overview model"""
    constituency_id: str
    constituency_name: str
    health_score: int
    risk_level: str
    total_population: int
    total_voters: int
    active_issues: int
    resolved_issues_30d: int
    satisfaction_score: int
    last_updated: datetime


class KPITrend(BaseModel):
    """KPI trend model"""
    constituency_id: str
    constituency_name: str
    kpi_date: date
    visits_count: int
    alerts_count: int
    promises_fulfilled: int
    booth_coverage: float
    voter_engagement_score: int
    ai_recommendations_count: int


class ExecutiveSummary(BaseModel):
    """Executive summary model"""
    constituency_id: str
    constituency_name: str
    report_date: date
    top_issues: Optional[str] = None
    priority_actions: Optional[str] = None
    resource_allocation: Optional[str] = None
    budget_status: Optional[str] = None


class TrendSummary(BaseModel):
    """Trend summary model"""
    constituency_id: str
    constituency_name: str
    trend_date: date
    health_score_change: float
    sentiment_change: float
    visit_frequency: int
    issue_resolution_rate: float


# ==================== Module 2: AI Intelligence Hub ====================

class AIRecommendation(BaseModel):
    """AI recommendation model"""
    recommendation_id: str
    constituency_id: str
    created_date: datetime
    priority: str
    category: str
    title: str
    description: str
    reasoning: str
    ai_confidence_score: float
    status: str
    expected_impact: str
    deadline: Optional[date] = None
    priority_score: int


class MediaBriefing(BaseModel):
    """Media briefing model"""
    talking_point_id: str
    constituency_id: str
    topic: str
    key_message: str
    supporting_data: Optional[str] = None
    target_audience: str
    sentiment_tone: str
    generated_date: datetime
    expiry_date: Optional[date] = None


class InfluencerMap(BaseModel):
    """Influencer mapping model"""
    intelligence_id: str
    constituency_id: str
    influencer_name: str
    influence_score: int
    category: str
    network_connections: Optional[str] = None
    engagement_history: Optional[str] = None
    recommendation_action: str


class VisitPriority(BaseModel):
    """Visit priority model"""
    suggestion_id: str
    constituency_id: str
    location: str
    visit_priority_score: float
    last_visit_days_ago: Optional[int] = None
    issues_count: int
    voter_density: int
    best_time_to_visit: Optional[str] = None
    duration_estimate: Optional[int] = None


# ==================== Module 3: Ground Reality ====================

class VisitEnhanced(BaseModel):
    """Enhanced visit model"""
    visit_id: str
    constituency_id: str
    constituency_name: str
    location: str
    visit_date: datetime
    visit_type: str
    duration: int
    attendees_count: int
    issues_raised: Optional[str] = None
    notes: Optional[str] = None
    photos: Optional[str] = None
    gps_coordinates: Optional[str] = None
    media_coverage: bool
    satisfaction_rating: Optional[int] = None


class HeatmapCurrent(BaseModel):
    """Current heatmap model"""
    heatmap_id: str
    constituency_id: str
    constituency_name: str
    ward_number: str
    risk_score: int
    risk_level: str
    issue_density: int
    policy_sector: str
    last_incident_date: Optional[date] = None
    resolution_status: str


class WardCoverage(BaseModel):
    """Ward coverage model"""
    ward_id: str
    constituency_id: str
    constituency_name: str
    ward_name: str
    total_voters: int
    visited_households: int
    issue_count: int
    resolved_count: int
    sentiment_score: int
    last_visit_date: Optional[date] = None
    coverage_score: float


class VisitTrend(BaseModel):
    """Visit trend model"""
    report_date: date
    constituency_id: str
    constituency_name: str
    total_visits: int
    unique_locations: int
    average_duration: float
    coverage_percentage: float
    average_attendance_per_visit: float


# ==================== Module 4: Election War Room ====================

class BoothScoreSummary(BaseModel):
    """Booth score summary model"""
    booth_id: str
    constituency_id: str
    constituency_name: str
    booth_name: str
    booth_number: str
    total_voters: int
    turnout_2019: float
    winner_2019: str
    margin_2019: int
    overall_score: int
    swing_potential: str
    risk_category: str
    last_assessment: date


class ElectionReadiness(BaseModel):
    """Election readiness model"""
    readiness_id: str
    constituency_id: str
    constituency_name: str
    assessment_date: date
    overall_score: int
    booth_coverage: float
    agent_deployment_status: str
    resource_status: str
    predicted_turnout: float
    confidence_level: float


class BoothRiskMatrix(BaseModel):
    """Booth risk matrix model"""
    booth_id: str
    constituency_id: str
    booth_name: str
    risk_category: str
    risk_score: int
    strength_score: int
    total_voters: int
    predicted_performance: str


class SwingAnalysis(BaseModel):
    """Swing analysis model"""
    booth_id: str
    constituency_id: str
    booth_name: str
    swing_potential: str
    swing_score: float
    total_voters: int
    winner_2019: str
    margin_2019: int
    predicted_swing: float


# ==================== Module 5: Promises ====================

class PromiseDashboard(BaseModel):
    """Promise dashboard model"""
    promise_id: str
    constituency_id: str
    promise_title: str
    promise_description: str
    promise_category: str
    promise_type: str
    announced_date: date
    announced_by: str
    target_beneficiaries: str
    estimated_beneficiaries_count: int
    scope: str
    impact_level: str
    estimated_cost: float
    budget_allocated: float
    budget_utilized: float
    budget_utilization_pct: float
    funding_source: str
    target_completion_date: date
    actual_start_date: Optional[date] = None
    actual_completion_date: Optional[date] = None
    duration_months: int
    days_until_deadline: int
    days_since_announced: int
    status: str
    completion_percentage: int
    timeline_status: str
    progress_health: str
    implementing_agency: str
    project_manager: str
    contact_person: str
    public_awareness_level: str
    satisfaction_score: int
    feedback_count: int
    media_coverage_count: int
    visibility_score: int
    last_public_update_date: Optional[date] = None
    days_since_update: Optional[int] = None
    current_challenges: Optional[str] = None
    challenge_count: int
    risk_factors: Optional[str] = None
    attention_priority: int


class PromiseOverdue(BaseModel):
    """Overdue promise model"""
    promise_id: str
    constituency_id: str
    promise_title: str
    promise_category: str
    target_completion_date: date
    status: str
    completion_percentage: int
    days_overdue: int
    budget_utilization_pct: float
    implementing_agency: str
    attention_priority: int


class PromiseByCategory(BaseModel):
    """Promise by category model"""
    constituency_id: str
    constituency_name: str
    promise_category: str
    total_promises: int
    completed: int
    in_progress: int
    delayed: int
    announced: int
    avg_completion_pct: float
    total_budget_allocated: float
    total_budget_utilized: float
    avg_satisfaction_score: float


class PromiseCompletionRate(BaseModel):
    """Promise completion rate model"""
    constituency_id: str
    constituency_name: str
    total_promises: int
    completed_promises: int
    completion_rate: float
    avg_days_to_complete: float
    on_track_promises: int
    delayed_promises: int
    avg_budget_utilization: float


# ==================== Module 6: Alerts & Crisis ====================

class AlertActive(BaseModel):
    """Active alert model"""
    alert_id: str
    constituency_id: str
    constituency_name: str
    created_by_user_id: str
    alert_type: str
    priority: str
    title: str
    description: str
    location: str
    gps_coordinates: Optional[str] = None
    photos: Optional[str] = None
    status: str
    created_date: datetime
    resolved_date: Optional[datetime] = None
    days_open: int
    priority_score: int
    is_escalated: bool
    escalated_at: Optional[datetime] = None


class AlertStatistics(BaseModel):
    """Alert statistics model"""
    constituency_id: str
    constituency_name: str
    stat_date: date
    total_alerts: int
    resolved_alerts: int
    avg_resolution_time: float
    pending_count: int
    by_category: Optional[str] = None
    by_priority: Optional[str] = None


class CrisisDashboard(BaseModel):
    """Crisis dashboard model"""
    crisis_id: str
    constituency_id: str
    constituency_name: str
    crisis_type: str
    severity_level: str
    affected_areas: Optional[str] = None
    start_date: datetime
    end_date: Optional[datetime] = None
    status: str
    response_actions: Optional[str] = None
    resources_deployed: Optional[str] = None
    severity_score: int
    duration_days: Optional[int] = None


class AlertResolutionMetrics(BaseModel):
    """Alert resolution metrics model"""
    constituency_id: str
    constituency_name: str
    alert_type: str
    total_alerts: int
    resolved_alerts: int
    avg_resolution_days: float
    resolution_rate: float
    escalated_count: int
    escalation_rate: float


# ==================== Role-Based Filter Models ====================

class UserRole(str, Enum):
    """User role enumeration"""
    ADMIN = "admin"
    SUPER_ADMIN = "super_admin"
    MP = "mp"
    MLA = "mla"
    MP_MLA = "mp_mla"
    MINISTER = "minister"
    VOLUNTEER = "volunteer"
    STAFF = "staff"


class UserContext(BaseModel):
    """User context for role-based filtering"""
    user_id: str
    role: UserRole
    constituency_id: Optional[str] = None
    constituencies: Optional[List[str]] = None
    permissions: Optional[List[str]] = None
