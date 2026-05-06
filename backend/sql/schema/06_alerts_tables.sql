-- =====================================================
-- Alerts & Crisis Management Tables
-- Module 6: Real-time Alerts + Crisis Response
-- =====================================================

-- Table 1: Alerts System
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.alerts` (
  alert_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  alert_type STRING NOT NULL, -- 'crisis', 'opportunity', 'threat', 'anomaly', 'milestone', 'reminder'
  alert_category STRING NOT NULL, -- 'political', 'social', 'infrastructure', 'health', 'law_order', 'natural_disaster', 'other'
  
  -- Alert Details
  title STRING NOT NULL,
  description STRING NOT NULL,
  severity STRING NOT NULL, -- 'critical', 'high', 'medium', 'low'
  urgency STRING NOT NULL, -- 'immediate', 'within_24h', 'within_week', 'routine'
  
  -- Location
  location_type STRING, -- 'constituency_wide', 'ward', 'village', 'specific_location'
  location_ward STRING,
  
  -- Impact Assessment
  potential_impact STRING, -- 'high', 'medium', 'low'
  estimated_people_affected INT64,
  estimated_voters_affected INT64,
  political_risk_score INT64, -- 0-100
  
  -- Source Information
  source_type STRING, -- 'field_report', 'social_media', 'news', 'volunteer', 'ai_detection', 'public_complaint'
  source_credibility STRING, -- 'high', 'medium', 'low'
  reported_by STRING,
  
  -- Timestamps
  incident_time TIMESTAMP, -- When incident occurred
  detected_at TIMESTAMP NOT NULL, -- When alert was created
  reported_at TIMESTAMP NOT NULL,
  
  -- Status & Assignment
  status STRING NOT NULL, -- 'new', 'acknowledged', 'investigating', 'action_taken', 'resolved', 'false_alarm', 'monitoring'
  priority STRING, -- 'p0_critical', 'p1_high', 'p2_medium', 'p3_low'
  assigned_to STRING,
  assigned_at TIMESTAMP,
  escalated_to STRING,
  escalation_level INT64, -- 0=field, 1=ward, 2=constituency, 3=state
  
  -- Response Actions
  actions_taken ARRAY<STRUCT<
    action STRING,
    taken_by STRING,
    taken_at TIMESTAMP,
    outcome STRING
  >>,
  
  -- Resolution
  resolution_notes STRING,
  resolved_by STRING,
  resolved_at TIMESTAMP,
  resolution_time_mins INT64,
  
  -- Follow-up
  requires_followup BOOLEAN,
  followup_date DATE,
  followup_notes STRING,
  
  -- Media & Documentation
  photos ARRAY<STRING>,
  videos ARRAY<STRING>,
  documents ARRAY<STRING>,
  media_coverage BOOLEAN,
  
  -- Related Data
  related_alerts ARRAY<STRING>, -- IDs of related alerts
  related_promises ARRAY<STRING>, -- Related promise IDs
  related_visits ARRAY<STRING>, -- Related visit IDs
  
  -- AI Analysis
  ai_sentiment_score FLOAT64,
  ai_risk_prediction STRING,
  ai_recommended_actions ARRAY<STRING>,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
)
PARTITION BY DATE(reported_at)
CLUSTER BY constituency_id, severity, status
OPTIONS(
  description="Real-time alert system for crisis, threats, and opportunities",
  labels=[("module", "alerts"), ("type", "alerts")]
);

-- Table 2: Crisis Events
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.crisis_events` (
  crisis_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  crisis_type STRING NOT NULL, -- 'natural_disaster', 'civil_unrest', 'health_emergency', 'infrastructure_failure', 'political_crisis', 'law_order'
  
  -- Crisis Details
  crisis_name STRING NOT NULL,
  description STRING NOT NULL,
  severity_level STRING NOT NULL, -- 'catastrophic', 'severe', 'moderate', 'minor'
  
  -- Timeline
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP,
  duration_hours FLOAT64,
  status STRING NOT NULL, -- 'active', 'contained', 'resolved', 'monitoring'
  
  -- Impact Assessment
  affected_locations ARRAY<STRUCT<
    ward STRING,
    village STRING,
    severity STRING
  >>,
  
  impact_metrics STRUCT<
    people_affected INT64,
    households_affected INT64,
    voters_affected INT64,
    casualties INT64,
    injuries INT64,
    property_damage_estimate FLOAT64,
    infrastructure_damaged ARRAY<STRING>
  >,
  
  -- Political Impact
  political_sensitivity STRING, -- 'very_high', 'high', 'medium', 'low'
  media_attention_level STRING, -- 'viral', 'high', 'medium', 'low', 'none'
  opposition_exploitation_risk STRING, -- 'high', 'medium', 'low'
  voter_sentiment_impact FLOAT64, -- -1 to 1
  
  -- Response Management
  response_team ARRAY<STRUCT<
    member_name STRING,
    role STRING,
    contact STRING
  >>,
  
  command_center_location STRING,
  response_coordinator STRING,
  
  -- Actions & Relief
  relief_measures ARRAY<STRUCT<
    measure STRING,
    beneficiaries INT64,
    amount_spent FLOAT64,
    deployed_at TIMESTAMP,
    effectiveness STRING
  >>,
  
  resources_deployed STRUCT<
    personnel INT64,
    vehicles INT64,
    equipment ARRAY<STRING>,
    budget_allocated FLOAT64,
    budget_spent FLOAT64
  >,
  
  -- Communication
  public_statements ARRAY<STRUCT<
    statement_time TIMESTAMP,
    statement_by STRING,
    channel STRING,
    content STRING
  >>,
  
  media_briefings_count INT64,
  social_media_updates_count INT64,
  
  -- Collaboration
  agencies_involved ARRAY<STRING>,
  external_support ARRAY<STRING>,
  
  -- Lessons Learned
  challenges_faced ARRAY<STRING>,
  what_worked_well ARRAY<STRING>,
  areas_for_improvement ARRAY<STRING>,
  recommendations ARRAY<STRING>,
  
  -- Documentation
  incident_report_url STRING,
  photos ARRAY<STRING>,
  videos ARRAY<STRING>,
  news_coverage ARRAY<STRING>,
  
  created_by STRING,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
)
PARTITION BY DATE(start_time)
CLUSTER BY constituency_id, crisis_type, severity_level
OPTIONS(
  description="Major crisis events and emergency response tracking",
  labels=[("module", "alerts"), ("type", "crisis")]
);

-- Table 3: Issue Escalation Tracker
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.issue_escalations` (
  escalation_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  original_issue_id STRING, -- Link to complaint/grievance system
  
  -- Issue Details
  issue_type STRING NOT NULL,
  issue_category STRING NOT NULL,
  issue_description STRING NOT NULL,
  
  -- Escalation Path
  escalation_level INT64 NOT NULL, -- 1=volunteer, 2=ward, 3=constituency, 4=state
  escalation_reason STRING,
  escalated_from STRING,
  escalated_to STRING,
  escalated_at TIMESTAMP NOT NULL,
  
  -- Timeline
  original_report_date TIMESTAMP,
  days_since_reported INT64,
  sla_breached BOOLEAN,
  sla_deadline TIMESTAMP,
  
  -- Status
  status STRING NOT NULL, -- 'escalated', 'under_review', 'action_initiated', 'resolved', 'closed'
  priority STRING NOT NULL,
  
  -- Complainant Info
  complainant_name STRING,
  complainant_contact STRING,
  complainant_location STRING,
  
  -- Resolution Tracking
  assigned_to STRING,
  assigned_at TIMESTAMP,
  actions_taken ARRAY<STRUCT<
    action STRING,
    action_by STRING,
    action_at TIMESTAMP,
    notes STRING
  >>,
  
  resolution_time_hours FLOAT64,
  resolution_notes STRING,
  resolved_by STRING,
  resolved_at TIMESTAMP,
  
  -- Quality Metrics
  complainant_satisfied BOOLEAN,
  satisfaction_score INT64, -- 1-5
  feedback STRING,
  
  -- Learning
  root_cause STRING,
  preventive_measures ARRAY<STRING>,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
)
PARTITION BY DATE(escalated_at)
CLUSTER BY constituency_id, escalation_level, status
OPTIONS(
  description="Tracking of escalated issues and resolution process",
  labels=[("module", "alerts"), ("type", "escalations")]
);

-- Table 4: Monitoring Dashboard Metrics
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.monitoring_metrics` (
  metric_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  measurement_time TIMESTAMP NOT NULL,
  measurement_date DATE NOT NULL,
  
  -- Alert Metrics
  alert_counts STRUCT<
    total_active INT64,
    critical INT64,
    high INT64,
    medium INT64,
    low INT64,
    new_24h INT64,
    resolved_24h INT64
  >,
  
  -- Crisis Metrics
  crisis_counts STRUCT<
    active_crises INT64,
    new_crises_7d INT64,
    resolved_crises_7d INT64,
    average_resolution_time_hours FLOAT64
  >,
  
  -- Response Metrics
  response_performance STRUCT<
    avg_response_time_mins FLOAT64,
    avg_resolution_time_hours FLOAT64,
    on_time_resolution_rate FLOAT64,
    escalation_rate FLOAT64
  >,
  
  -- Health Indicators
  health_scores STRUCT<
    overall_health INT64, -- 0-100
    crisis_readiness INT64,
    response_capability INT64,
    resource_adequacy INT64
  >,
  
  -- Trend Indicators
  trends STRUCT<
    alert_trend_7d STRING, -- 'increasing', 'stable', 'decreasing'
    severity_trend STRING,
    resolution_trend STRING
  >,
  
  -- Hotspot Analysis
  hotspot_wards ARRAY<STRUCT<
    ward STRING,
    active_alerts INT64,
    severity_score INT64,
    attention_needed BOOLEAN
  >>,
  
  -- Category Distribution
  alerts_by_category ARRAY<STRUCT<
    category STRING,
    count INT64,
    critical_count INT64
  >>,
  
  -- Risk Assessment
  risk_indicators STRUCT<
    high_risk_areas INT64,
    unresolved_critical_alerts INT64,
    pending_escalations INT64,
    sla_breaches_24h INT64
  >,
  
  -- Capacity Metrics
  capacity_status STRUCT<
    active_responders INT64,
    available_resources INT64,
    utilization_rate FLOAT64,
    overload_risk BOOLEAN
  >,
  
  created_at TIMESTAMP NOT NULL
)
PARTITION BY measurement_date
CLUSTER BY constituency_id, measurement_time
OPTIONS(
  description="Real-time monitoring dashboard metrics and KPIs",
  labels=[("module", "alerts"), ("type", "monitoring")]
);

-- =====================================================
-- Indexes and Constraints (Documentation)
-- =====================================================

-- Note: All tables optimized for real-time monitoring
-- Partitioning by timestamp/date for efficient time-based queries
-- Clustering on constituency, severity, and status for quick filtering
-- Critical for sub-second dashboard queries
