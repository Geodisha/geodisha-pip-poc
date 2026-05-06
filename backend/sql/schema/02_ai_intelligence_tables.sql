-- =====================================================
-- AI Intelligence Hub Tables
-- Module 2: AI Recommendations + Media AI + Strategic Intel
-- =====================================================

-- Table 1: AI Recommendations
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.ai_recommendations` (
  recommendation_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  recommendation_type STRING NOT NULL, -- 'policy', 'outreach', 'crisis_response', 'resource_allocation'
  title STRING NOT NULL,
  description STRING,
  priority STRING NOT NULL, -- 'critical', 'high', 'medium', 'low'
  confidence_score FLOAT64, -- 0.0 to 1.0
  impact_score FLOAT64, -- Expected impact 0-100
  effort_level STRING, -- 'low', 'medium', 'high'
  target_audience STRING, -- 'youth', 'women', 'farmers', 'all'
  estimated_cost FLOAT64,
  estimated_timeline_days INT64,
  status STRING NOT NULL, -- 'pending', 'accepted', 'in_progress', 'completed', 'rejected'
  assigned_to STRING,
  ai_reasoning STRING,
  data_sources ARRAY<STRING>, -- Sources used by AI
  expected_outcomes ARRAY<STRING>,
  risks ARRAY<STRING>,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  completed_at TIMESTAMP,
  feedback_rating INT64, -- 1-5 stars
  feedback_notes STRING
)
PARTITION BY DATE(created_at)
CLUSTER BY constituency_id, priority, status
OPTIONS(
  description="AI-generated recommendations for constituency improvement",
  labels=[("module", "ai_intelligence"), ("type", "recommendations")]
);

-- Table 2: Media AI Talking Points
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.media_talking_points` (
  talking_point_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  topic STRING NOT NULL, -- 'healthcare', 'education', 'infrastructure', etc.
  headline STRING NOT NULL,
  key_message STRING NOT NULL,
  supporting_facts ARRAY<STRING>,
  statistics ARRAY<STRUCT<label STRING, value STRING>>,
  target_media STRING, -- 'tv', 'print', 'social', 'press_conference'
  tone STRING, -- 'positive', 'defensive', 'aggressive', 'neutral'
  urgency STRING, -- 'immediate', 'this_week', 'this_month'
  related_events ARRAY<STRING>,
  dos ARRAY<STRING>, -- What to emphasize
  donts ARRAY<STRING>, -- What to avoid
  sample_quotes ARRAY<STRING>,
  counter_narratives ARRAY<STRING>, -- Response to opposition
  generated_by STRING, -- 'ai', 'manual', 'hybrid'
  ai_confidence FLOAT64,
  reviewed_by STRING,
  approved_status STRING, -- 'draft', 'approved', 'published', 'archived'
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP,
  effectiveness_rating INT64 -- Post-usage rating
)
PARTITION BY DATE(created_at)
CLUSTER BY constituency_id, topic, urgency
OPTIONS(
  description="AI-generated media talking points and messaging strategy",
  labels=[("module", "ai_intelligence"), ("type", "media")]
);

-- Table 3: Strategic Intelligence - Influencer Mapping
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.influencer_mapping` (
  influencer_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  name STRING NOT NULL,
  category STRING NOT NULL, -- 'religious', 'business', 'community', 'youth', 'women', 'media'
  sub_category STRING,
  influence_level STRING NOT NULL, -- 'high', 'medium', 'low'
  influence_score INT64, -- 0-100
  reach_estimate INT64, -- Number of people influenced
  location_ward STRING,
  location_mandal STRING,
  contact_phone STRING,
  contact_email STRING,
  political_leaning STRING, -- 'favorable', 'neutral', 'opposition', 'unknown'
  engagement_history ARRAY<STRUCT<date DATE, event STRING, outcome STRING>>,
  key_issues ARRAY<STRING>, -- Issues they care about
  relationship_strength STRING, -- 'strong', 'moderate', 'weak', 'none'
  last_interaction_date DATE,
  next_followup_date DATE,
  notes STRING,
  added_by STRING,
  verified BOOLEAN,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
)
PARTITION BY DATE(created_at)
CLUSTER BY constituency_id, influence_level, category
OPTIONS(
  description="Mapping of key influencers and stakeholders in constituency",
  labels=[("module", "ai_intelligence"), ("type", "strategic")]
);

-- Table 4: Visit Planning & Optimization
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.visit_planning` (
  plan_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  plan_name STRING NOT NULL,
  plan_date DATE NOT NULL,
  plan_type STRING NOT NULL, -- 'routine', 'campaign', 'crisis_response', 'festival'
  status STRING NOT NULL, -- 'draft', 'scheduled', 'in_progress', 'completed', 'cancelled'
  priority STRING, -- 'critical', 'high', 'medium', 'low'
  locations ARRAY<STRUCT<
    ward STRING,
    village STRING,
    visit_type STRING,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    expected_attendance INT64,
    key_people ARRAY<STRING>
  >>,
  route_optimization STRUCT<
    total_distance_km FLOAT64,
    estimated_travel_time_mins INT64,
    optimized_sequence ARRAY<STRING>,
    fuel_cost_estimate FLOAT64
  >,
  objectives ARRAY<STRING>,
  target_demographics ARRAY<STRING>,
  key_messages ARRAY<STRING>,
  resource_requirements STRUCT<
    vehicles INT64,
    security_personnel INT64,
    volunteers INT64,
    budget FLOAT64
  >,
  risk_assessment STRUCT<
    weather_risk STRING,
    security_risk STRING,
    crowd_management_risk STRING,
    mitigation_steps ARRAY<STRING>
  >,
  ai_suggestions ARRAY<STRING>,
  created_by STRING,
  approved_by STRING,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  actual_completion_notes STRING
)
PARTITION BY plan_date
CLUSTER BY constituency_id, status, priority
OPTIONS(
  description="AI-powered visit planning and route optimization",
  labels=[("module", "ai_intelligence"), ("type", "visit_planning")]
);

-- =====================================================
-- Indexes and Constraints (Documentation)
-- =====================================================

-- Note: BigQuery doesn't support traditional indexes, but CLUSTERING provides similar benefits
-- All tables are partitioned by date fields for query performance
-- Clustering on frequently filtered columns (constituency_id, status, priority)
