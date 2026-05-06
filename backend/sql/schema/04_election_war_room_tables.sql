-- =====================================================
-- Election War Room Tables
-- Module 4: Booth Scores + Election Intelligence
-- =====================================================

-- Table 1: Booth Analysis
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.booth_analysis` (
  booth_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  booth_number STRING NOT NULL,
  booth_name STRING NOT NULL,
  location_ward STRING NOT NULL,
  location_village STRING,
  location_coordinates STRUCT<lat FLOAT64, lng FLOAT64>,
  analysis_date DATE NOT NULL,
  
  -- Voter Demographics
  total_voters INT64 NOT NULL,
  male_voters INT64,
  female_voters INT64,
  first_time_voters INT64,
  senior_voters INT64,
  
  -- Historical Performance
  previous_election STRUCT<
    total_votes INT64,
    party_votes INT64,
    party_vote_share FLOAT64,
    winning_margin INT64,
    turnout_pct FLOAT64
  >,
  
  -- Current Assessment
  current_strength STRUCT<
    favorable_voters INT64,
    leaning_favorable INT64,
    neutral_voters INT64,
    opposition_voters INT64,
    undecided_voters INT64
  >,
  
  -- Booth Score Metrics
  booth_score INT64, -- 0-100, overall booth strength
  score_components STRUCT<
    historical_performance INT64,
    current_sentiment INT64,
    organization_strength INT64,
    leader_connect INT64,
    ground_presence INT64
  >,
  
  -- Risk Assessment
  risk_level STRING, -- 'secure', 'moderate', 'vulnerable', 'critical'
  risk_factors ARRAY<STRING>,
  competitive_threat_score INT64, -- 0-100
  
  -- Vote Estimation
  estimated_votes STRUCT<
    favorable INT64,
    opposition INT64,
    others INT64,
    confidence_level FLOAT64
  >,
  
  -- Ground Organization
  booth_agents INT64,
  active_volunteers INT64,
  booth_committee_strength STRING, -- 'strong', 'moderate', 'weak', 'none'
  last_meeting_date DATE,
  
  -- Influencers & Key Contacts
  key_influencers ARRAY<STRUCT<
    name STRING,
    role STRING,
    support_level STRING
  >>,
  
  -- Action Items
  priority_actions ARRAY<STRUCT<
    action STRING,
    urgency STRING,
    assigned_to STRING,
    due_date DATE,
    status STRING
  >>,
  
  -- Metadata
  surveyed_by STRING,
  verified_by STRING,
  verification_date DATE,
  notes STRING,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
)
PARTITION BY analysis_date
CLUSTER BY constituency_id, location_ward
OPTIONS(
  description="Detailed booth-level analysis and scoring for election planning",
  labels=[("module", "election_war_room"), ("type", "booth_analysis")]
);

-- Table 2: Booth Score Trends
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.booth_score_trends` (
  trend_id STRING NOT NULL,
  booth_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  measurement_date DATE NOT NULL,
  
  -- Score Timeline
  booth_score INT64 NOT NULL,
  favorable_pct FLOAT64,
  opposition_pct FLOAT64,
  undecided_pct FLOAT64,
  
  -- Trend Analysis
  vs_previous_week INT64, -- Score change
  vs_previous_month INT64,
  vs_baseline INT64,
  trend_direction STRING, -- 'improving', 'stable', 'declining'
  
  -- Momentum Indicators
  momentum_score INT64, -- -100 to +100
  velocity FLOAT64, -- Rate of change
  
  -- Activity Tracking
  visits_count_7d INT64,
  visits_count_30d INT64,
  events_count_7d INT64,
  events_count_30d INT64,
  volunteer_activity_score INT64,
  
  -- Engagement Metrics
  door_to_door_coverage_pct FLOAT64,
  voter_contact_count_30d INT64,
  grievances_resolved_30d INT64,
  
  -- Comparative Metrics
  rank_in_constituency INT64, -- Booth ranking
  percentile INT64, -- Performance percentile
  
  -- Impact Factors
  positive_events ARRAY<STRING>,
  negative_events ARRAY<STRING>,
  
  created_at TIMESTAMP NOT NULL
)
PARTITION BY measurement_date
CLUSTER BY constituency_id, booth_id
OPTIONS(
  description="Time-series tracking of booth scores and trends",
  labels=[("module", "election_war_room"), ("type", "booth_trends")]
);

-- Table 3: Voter Segments
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.voter_segments` (
  segment_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  segment_name STRING NOT NULL,
  segment_type STRING NOT NULL, -- 'demographic', 'issue_based', 'geographic', 'loyalty'
  analysis_date DATE NOT NULL,
  
  -- Segment Profile
  total_voters INT64 NOT NULL,
  percentage_of_total FLOAT64,
  
  -- Demographic Profile (if demographic segment)
  demographics STRUCT<
    age_group STRING,
    gender STRING,
    occupation_category STRING,
    income_level STRING,
    education_level STRING,
    religion STRING,
    caste_category STRING
  >,
  
  -- Geographic Distribution
  geographic_concentration ARRAY<STRUCT<
    ward STRING,
    voter_count INT64,
    concentration_pct FLOAT64
  >>,
  
  -- Political Assessment
  support_level STRUCT<
    strong_favorable INT64,
    leaning_favorable INT64,
    neutral INT64,
    opposition INT64,
    undecided INT64
  >,
  
  -- Key Issues
  top_issues ARRAY<STRUCT<
    issue STRING,
    priority_level STRING,
    satisfaction_score INT64
  >>,
  
  -- Engagement Status
  engagement_score INT64, -- 0-100
  contact_coverage_pct FLOAT64,
  last_contact_date DATE,
  
  -- Influence & Communication
  preferred_channels ARRAY<STRING>, -- 'door_to_door', 'phone', 'whatsapp', 'social_media', 'events'
  key_messengers ARRAY<STRING>, -- Who they trust
  
  -- Targeting Strategy
  priority_level STRING, -- 'high', 'medium', 'low'
  target_message ARRAY<STRING>,
  recommended_actions ARRAY<STRING>,
  estimated_conversion_rate FLOAT64,
  
  -- Historical Behavior
  turnout_tendency STRING, -- 'high', 'medium', 'low'
  loyalty_score INT64, -- 0-100
  swing_potential STRING, -- 'high', 'medium', 'low'
  
  -- Resources Allocated
  budget_allocated FLOAT64,
  volunteers_assigned INT64,
  events_planned INT64,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
)
PARTITION BY analysis_date
CLUSTER BY constituency_id, segment_type, priority_level
OPTIONS(
  description="Voter segmentation analysis for targeted campaign strategies",
  labels=[("module", "election_war_room"), ("type", "voter_segments")]
);

-- Table 4: Opposition Intelligence
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.opposition_intelligence` (
  intel_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  opposition_party STRING NOT NULL,
  report_date DATE NOT NULL,
  
  -- Opposition Strength
  overall_strength_score INT64, -- 0-100
  estimated_vote_share FLOAT64,
  trend STRING, -- 'growing', 'stable', 'declining'
  
  -- Leadership Assessment
  candidate_profile STRUCT<
    name STRING,
    age INT64,
    background STRING,
    strength_areas ARRAY<STRING>,
    weakness_areas ARRAY<STRING>,
    popularity_score INT64
  >,
  
  -- Campaign Activity
  campaign_intensity STRING, -- 'very_high', 'high', 'medium', 'low'
  activity_metrics STRUCT<
    public_meetings_30d INT64,
    door_to_door_coverage_pct FLOAT64,
    social_media_reach INT64,
    volunteer_count INT64,
    estimated_budget FLOAT64
  >,
  
  -- Messaging & Strategy
  key_messages ARRAY<STRING>,
  attack_lines ARRAY<STRING>,
  target_segments ARRAY<STRING>,
  
  -- Ground Presence
  strong_areas ARRAY<STRUCT<
    ward STRING,
    strength_level STRING,
    estimated_vote_share FLOAT64
  >>,
  weak_areas ARRAY<STRUCT<
    ward STRING,
    strength_level STRING,
    estimated_vote_share FLOAT64
  >>,
  
  -- Alliance & Support
  alliance_partners ARRAY<STRING>,
  support_from_influencers ARRAY<STRING>,
  
  -- Issues Exploited
  issues_being_raised ARRAY<STRUCT<
    issue STRING,
    narrative STRING,
    impact_level STRING
  >>,
  
  -- Vulnerabilities
  vulnerabilities ARRAY<STRUCT<
    vulnerability STRING,
    severity STRING,
    exploitation_strategy STRING
  >>,
  
  -- Counter Strategy
  recommended_counter_actions ARRAY<STRING>,
  defensive_messaging ARRAY<STRING>,
  
  -- Intelligence Sources
  source_quality STRING, -- 'high', 'medium', 'low'
  verification_status STRING, -- 'verified', 'probable', 'rumor'
  
  notes STRING,
  reported_by STRING,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
)
PARTITION BY report_date
CLUSTER BY constituency_id, opposition_party, overall_strength_score
OPTIONS(
  description="Intelligence on opposition parties, candidates, and strategies",
  labels=[("module", "election_war_room"), ("type", "opposition_intel")]
);

-- =====================================================
-- Indexes and Constraints (Documentation)
-- =====================================================

-- Note: All tables optimized for election campaign queries
-- Partitioning by date enables efficient time-based filtering
-- Clustering on constituency and scores for performance
