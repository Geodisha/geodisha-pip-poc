-- filepath: /Users/conglomerateit/Documents/GEODISHA/Code/gd_playground/geodisha-mobile-app/sql/schema/03_ground_reality_tables.sql
-- =====================================================
-- Ground Reality Tables
-- Module 3: Visit Records + Heatmap Analytics
-- =====================================================

-- Table 1: Visit Records (Enhanced - complements existing Snail_track_mvp1.visits)
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.visit_records_enhanced` (
  visit_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  visit_date DATE NOT NULL,
  visit_time TIME NOT NULL,
  location_ward STRING NOT NULL,
  visit_type STRING NOT NULL, -- 'public_meeting', 'house_visit', 'office_hours', 'event', 'inspection'
  visit_category STRING, -- 'scheduled', 'impromptu', 'emergency'
  
  -- Visitor/Leader Info
  leader_name STRING NOT NULL,
  leader_role STRING, -- 'MLA', 'MP', 'Minister'
  
  -- Attendance
  total_attendance INT64,
  
  -- Issues & Grievances
  grievances_count INT64,
  grievances_resolved_on_spot INT64,
  
  -- Sentiment & Feedback
  public_sentiment STRING, -- 'very_positive', 'positive', 'neutral', 'negative', 'very_negative'
  sentiment_score FLOAT64, -- -1.0 to 1.0
  
  -- Media & Documentation
  photos_count INT64,
  videos_count INT64,
  media_coverage STRING, -- 'yes', 'no'
  
  -- Metadata
  recorded_by STRING,
  verification_status STRING, -- 'pending', 'verified', 'flagged'
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
)
PARTITION BY visit_date
CLUSTER BY constituency_id, visit_type, location_ward
OPTIONS(
  description="Enhanced visit records with detailed ground intelligence",
  labels=[("module", "ground_reality"), ("type", "visits")]
);

-- Table 2: Heatmap Data - Issue Concentration
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.issue_heatmap` (
  heatmap_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  location_ward STRING NOT NULL,
  data_date DATE NOT NULL,
  
  -- Issue Metrics
  total_issues_reported INT64,
  critical_issues INT64,
  resolved_issues INT64,
  pending_issues INT64,
  resolution_rate FLOAT64,
  
  -- Intensity Metrics
  intensity_score FLOAT64,
  severity_index FLOAT64,
  urgency_index FLOAT64,
  
  -- Population Context
  population_estimate INT64,
  issues_per_capita FLOAT64,
  
  -- Visit Context
  last_visit_date DATE,
  days_since_last_visit INT64,
  visit_frequency_30d INT64,
  
  -- Metadata
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
)
PARTITION BY data_date
CLUSTER BY constituency_id, location_ward
OPTIONS(
  description="Geospatial heatmap data for issue concentration and severity",
  labels=[("module", "ground_reality"), ("type", "heatmap")]
);

-- Table 3: Ward-Level Intelligence
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.ward_intelligence` (
  ward_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  ward_name STRING NOT NULL,
  report_date DATE NOT NULL,
  
  -- Demographics
  total_population INT64,
  total_voters INT64,
  total_households INT64,
  
  -- Ground Reality Scores
  infrastructure_score INT64, -- 0-100
  public_service_score INT64,
  safety_score INT64,
  development_score INT64,
  satisfaction_score INT64,
  overall_health_score INT64,
  
  -- Leader Presence
  last_leader_visit_date DATE,
  visit_frequency_30d INT64,
  visit_frequency_90d INT64,
  leader_visibility_score INT64, -- 0-100
  
  -- Community Engagement
  active_volunteers INT64,
  community_events_30d INT64,
  
  -- Competitor Activity
  opposition_activity_level STRING, -- 'high', 'medium', 'low'
  opposition_events_30d INT64,
  competitive_threat_score INT64, -- 0-100
  
  -- Risk Indicators
  risk_level STRING, -- 'high', 'medium', 'low'
  attention_required BOOLEAN,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
)
PARTITION BY report_date
CLUSTER BY constituency_id, ward_name, risk_level
OPTIONS(
  description="Ward-level intelligence and political landscape analysis",
  labels=[("module", "ground_reality"), ("type", "ward_intel")]
);

-- =====================================================
-- Indexes and Constraints (Documentation)
-- =====================================================

-- Note: All tables partitioned by date for time-series queries
-- Clustering optimized for constituency and location-based filtering
