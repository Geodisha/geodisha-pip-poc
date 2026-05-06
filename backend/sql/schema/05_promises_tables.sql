-- =====================================================
-- Promise Tracker Tables
-- Module 5: Political Promises & Delivery Tracking
-- =====================================================

-- Table 1: Promises Catalog
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.promises` (
  promise_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  promise_title STRING NOT NULL,
  promise_description STRING NOT NULL,
  promise_category STRING NOT NULL, -- 'infrastructure', 'healthcare', 'education', 'employment', 'agriculture', 'welfare'
  promise_type STRING, -- 'election_manifesto', 'public_meeting', 'media_statement', 'budget_announcement'
  
  -- Promise Details
  announced_date DATE NOT NULL,
  announced_by STRING NOT NULL, -- Name of leader
  announced_at STRING, -- Location/Event
  target_beneficiaries STRING, -- 'all', 'youth', 'women', 'farmers', 'sc_st', 'minorities'
  estimated_beneficiaries_count INT64,
  
  -- Scope & Impact
  scope STRING, -- 'constituency_wide', 'ward_specific', 'village_specific'
  specific_locations ARRAY<STRING>,
  impact_level STRING, -- 'transformative', 'high', 'medium', 'low'
  
  -- Budget & Resources
  estimated_cost FLOAT64,
  budget_allocated FLOAT64,
  budget_utilized FLOAT64,
  funding_source STRING, -- 'state_govt', 'central_govt', 'local_body', 'private', 'mixed'
  
  -- Timeline
  target_completion_date DATE,
  actual_start_date DATE,
  actual_completion_date DATE,
  duration_months INT64,
  
  -- Status Tracking
  status STRING NOT NULL, -- 'announced', 'planning', 'in_progress', 'completed', 'delayed', 'cancelled'
  completion_percentage INT64, -- 0-100
  
  -- Progress Milestones
  milestones ARRAY<STRUCT<
    milestone_name STRING,
    target_date DATE,
    actual_date DATE,
    status STRING,
    description STRING
  >>,
  
  -- Stakeholders
  implementing_agency STRING,
  project_manager STRING,
  contact_person STRING,
  contact_phone STRING,
  
  -- Challenges & Risks
  current_challenges ARRAY<STRING>,
  risk_factors ARRAY<STRING>,
  mitigation_measures ARRAY<STRING>,
  
  -- Public Perception
  public_awareness_level STRING, -- 'high', 'medium', 'low'
  satisfaction_score INT64, -- 0-100
  feedback_count INT64,
  
  -- Media & Communication
  media_coverage_count INT64,
  last_public_update_date DATE,
  visibility_score INT64, -- 0-100
  
  -- Documentation
  document_urls ARRAY<STRING>,
  photo_urls ARRAY<STRING>,
  
  notes STRING,
  created_by STRING,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
)
PARTITION BY announced_date
CLUSTER BY constituency_id, status, promise_category
OPTIONS(
  description="Catalog of political promises and commitments",
  labels=[("module", "promises"), ("type", "catalog")]
);

-- Table 2: Promise Progress Updates
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.promise_updates` (
  update_id STRING NOT NULL,
  promise_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  update_date DATE NOT NULL,
  update_time TIMESTAMP NOT NULL,
  
  -- Progress Information
  completion_percentage INT64,
  status STRING, -- Current status at time of update
  
  -- Update Details
  update_type STRING, -- 'milestone_achieved', 'progress_report', 'delay_notification', 'budget_update', 'completion'
  update_title STRING NOT NULL,
  update_description STRING,
  
  -- Achievements
  achievements ARRAY<STRING>,
  deliverables_completed ARRAY<STRING>,
  
  -- Metrics
  beneficiaries_reached INT64,
  amount_spent FLOAT64,
  
  -- Challenges
  new_challenges ARRAY<STRING>,
  delays_reason STRING,
  revised_timeline DATE,
  
  -- Media & Visibility
  media_release BOOLEAN,
  public_event BOOLEAN,
  photos_count INT64,
  videos_count INT64,
  
  -- Verification
  verified BOOLEAN,
  verified_by STRING,
  verification_notes STRING,
  
  -- Social Proof
  testimonials ARRAY<STRUCT<
    person_name STRING,
    person_role STRING,
    quote STRING,
    photo_url STRING
  >>,
  
  updated_by STRING,
  created_at TIMESTAMP NOT NULL
)
PARTITION BY update_date
CLUSTER BY promise_id, constituency_id, update_type
OPTIONS(
  description="Timeline of progress updates for promises",
  labels=[("module", "promises"), ("type", "updates")]
);

-- Table 3: Promise Impact Assessment
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.promise_impact` (
  assessment_id STRING NOT NULL,
  promise_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  assessment_date DATE NOT NULL,
  
  -- Delivery Assessment
  delivery_score INT64, -- 0-100, how well promise was delivered
  timeline_adherence_score INT64, -- 0-100
  budget_efficiency_score INT64, -- 0-100
  quality_score INT64, -- 0-100
  
  -- Actual Impact
  actual_beneficiaries INT64,
  vs_projected_beneficiaries FLOAT64, -- Percentage
  
  impact_metrics STRUCT<
    lives_improved INT64,
    jobs_created INT64,
    infrastructure_delivered STRING,
    services_improved STRING
  >,
  
  -- Social Impact
  social_impact_score INT64, -- 0-100
  community_satisfaction FLOAT64, -- 1-5 stars
  feedback_summary STRING,
  
  -- Political Impact
  political_impact_score INT64, -- 0-100
  perception_change STRUCT<
    before_sentiment FLOAT64,
    after_sentiment FLOAT64,
    sentiment_improvement FLOAT64
  >,
  
  voter_appreciation_level STRING, -- 'very_high', 'high', 'medium', 'low'
  electoral_advantage_score INT64, -- 0-100
  
  -- Comparative Analysis
  vs_similar_promises STRING,
  vs_opposition_delivery STRING,
  
  -- Success Factors
  success_factors ARRAY<STRING>,
  lessons_learned ARRAY<STRING>,
  best_practices ARRAY<STRING>,
  
  -- Challenges Overcome
  challenges_faced ARRAY<STRING>,
  how_overcome ARRAY<STRING>,
  
  -- Future Implications
  replicability_score INT64, -- 0-100, can it be replicated elsewhere
  sustainability_score INT64, -- 0-100, long-term viability
  
  -- Recommendations
  recommendations ARRAY<STRING>,
  
  assessed_by STRING,
  assessment_method STRING, -- 'survey', 'field_visit', 'data_analysis', 'stakeholder_feedback'
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
)
PARTITION BY assessment_date
CLUSTER BY constituency_id, promise_id, delivery_score
OPTIONS(
  description="Impact assessment and evaluation of delivered promises",
  labels=[("module", "promises"), ("type", "impact")]
);

-- Table 4: Promise Comparison & Benchmarking
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.promise_benchmarks` (
  benchmark_id STRING NOT NULL,
  constituency_id STRING NOT NULL,
  report_date DATE NOT NULL,
  comparison_period STRING, -- 'monthly', 'quarterly', 'yearly', 'term'
  
  -- Overall Metrics
  total_promises INT64,
  promises_completed INT64,
  promises_in_progress INT64,
  promises_delayed INT64,
  promises_cancelled INT64,
  
  -- Performance Scores
  overall_delivery_rate FLOAT64, -- Percentage
  on_time_delivery_rate FLOAT64,
  budget_efficiency FLOAT64,
  average_completion_score INT64,
  
  -- Category-wise Performance
  category_performance ARRAY<STRUCT<
    category STRING,
    total_promises INT64,
    completed INT64,
    in_progress INT64,
    delivery_rate FLOAT64,
    avg_score INT64
  >>,
  
  -- Time-based Analysis
  promise_velocity FLOAT64, -- Promises completed per month
  average_delivery_time_days INT64,
  
  -- Trend Analysis
  vs_previous_period STRUCT<
    delivery_rate_change FLOAT64,
    completion_count_change INT64,
    trend STRING
  >,
  
  -- Comparative Benchmarks
  vs_state_average STRUCT<
    delivery_rate_diff FLOAT64,
    performance_percentile INT64
  >,
  
  vs_similar_constituencies ARRAY<STRUCT<
    constituency_name STRING,
    delivery_rate FLOAT64,
    comparison STRING
  >>,
  
  -- Public Perception
  public_awareness_score INT64, -- 0-100
  public_satisfaction_score INT64, -- 0-100
  media_sentiment FLOAT64, -- -1 to 1
  
  -- Highlights
  top_performing_categories ARRAY<STRING>,
  underperforming_categories ARRAY<STRING>,
  flagship_promises ARRAY<STRING>,
  
  -- Strategic Insights
  strengths ARRAY<STRING>,
  weaknesses ARRAY<STRING>,
  opportunities ARRAY<STRING>,
  threats ARRAY<STRING>,
  
  -- Recommendations
  priority_actions ARRAY<STRING>,
  communication_strategy ARRAY<STRING>,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
)
PARTITION BY report_date
CLUSTER BY constituency_id
OPTIONS(
  description="Comparative benchmarking and performance analysis of promises",
  labels=[("module", "promises"), ("type", "benchmarks")]
);

-- =====================================================
-- Indexes and Constraints (Documentation)
-- =====================================================

-- Note: Tables optimized for tracking promise lifecycle
-- Partitioning by date fields for time-series analysis
-- Clustering on constituency and status for quick filtering
