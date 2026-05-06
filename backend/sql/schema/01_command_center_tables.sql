-- ============================================================================
-- Module 1: COMMAND CENTER TABLES
-- Dataset: geo-pulse-463507.geo_pulse_data
-- Purpose: Executive overview, KPIs, trends, and analytics
-- Created: 2024-12-03
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table 1.1: constituency_overview
-- Purpose: Master table for constituency-level overview and health metrics
-- Partition: By last_updated date
-- Cluster: By constituency_id, risk_level
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.constituency_overview` (
  -- Primary Keys
  constituency_id STRING NOT NULL OPTIONS(description="Unique identifier for constituency (e.g., PC01, PC02)"),
  constituency_name STRING NOT NULL OPTIONS(description="Constituency name (e.g., Adilabad, Hyderabad)"),
  
  -- Key Performance Indicators
  health_score INT64 OPTIONS(description="Overall constituency health score (0-100)"),
  risk_level STRING OPTIONS(description="Risk category: low, medium, high"),
  
  -- Population & Voter Metrics
  total_population INT64 OPTIONS(description="Estimated total population"),
  total_voters INT64 OPTIONS(description="Total registered voters (electors)"),
  
  -- Issue Tracking
  active_issues INT64 OPTIONS(description="Currently active issues"),
  resolved_issues_30d INT64 OPTIONS(description="Issues resolved in last 30 days"),
  pending_issues INT64 OPTIONS(description="Pending issues count"),
  critical_alerts INT64 OPTIONS(description="Number of critical alerts"),
  
  -- Satisfaction & Engagement
  satisfaction_score INT64 OPTIONS(description="Public satisfaction score (0-100)"),
  last_visit_date DATE OPTIONS(description="Date of last leader visit"),
  visit_frequency_30d INT64 OPTIONS(description="Number of visits in last 30 days"),
  grievances_30d INT64 OPTIONS(description="Grievances received in last 30 days"),
  
  -- Promise Tracking
  promises_total INT64 OPTIONS(description="Total promises made"),
  promises_completed INT64 OPTIONS(description="Number of completed promises"),
  promises_in_progress INT64 OPTIONS(description="Promises currently in progress"),
  
  -- Metadata
  last_updated TIMESTAMP NOT NULL OPTIONS(description="Last update timestamp")
)
PARTITION BY DATE(last_updated)
CLUSTER BY constituency_id, risk_level
OPTIONS(
  description="Constituency overview and health metrics for command center dashboard",
  labels=[("module", "command_center"), ("type", "master_data")]
);

-- ----------------------------------------------------------------------------
-- Table 1.2: constituency_kpis
-- Purpose: Daily KPI tracking for each constituency
-- Partition: By kpi_date
-- Cluster: By constituency_id, kpi_date
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.constituency_kpis` (
  -- Primary Keys
  kpi_id STRING NOT NULL OPTIONS(description="Unique KPI record ID (UUID)"),
  constituency_id STRING NOT NULL OPTIONS(description="Reference to constituency"),
  report_date DATE NOT NULL OPTIONS(description="Date for KPI measurement"),
  
  -- Visit Metrics
  visits_conducted INT64 DEFAULT 0 OPTIONS(description="Number of visits on this date"),
  people_contacted INT64 DEFAULT 0 OPTIONS(description="Number of people contacted"),
  
  -- Grievance Metrics
  grievances_received INT64 DEFAULT 0 OPTIONS(description="Grievances received on this date"),
  grievances_resolved INT64 DEFAULT 0 OPTIONS(description="Grievances resolved on this date"),
  
  -- Event & Resource Metrics
  events_conducted INT64 DEFAULT 0 OPTIONS(description="Events conducted on this date"),
  resources_distributed INT64 DEFAULT 0 OPTIONS(description="Resources distributed"),
  
  -- Promise Metrics
  promises_on_track INT64 DEFAULT 0 OPTIONS(description="Promises on track"),
  promises_delayed INT64 DEFAULT 0 OPTIONS(description="Promises delayed"),
  
  -- Alert Metrics
  alert_count INT64 DEFAULT 0 OPTIONS(description="Total alerts on this date"),
  critical_alerts INT64 DEFAULT 0 OPTIONS(description="Critical priority alerts"),
  
  -- Sentiment & Engagement
  sentiment_score FLOAT64 OPTIONS(description="Daily sentiment score (0-1)"),
  media_mentions INT64 DEFAULT 0 OPTIONS(description="Media mentions count"),
  social_engagement INT64 DEFAULT 0 OPTIONS(description="Social media engagement count"),
  
  -- Metadata
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP() OPTIONS(description="Record creation time")
)
PARTITION BY report_date
CLUSTER BY constituency_id, report_date
OPTIONS(
  description="Daily KPI tracking for constituency performance monitoring",
  labels=[("module", "command_center"), ("type", "time_series")]
);

-- ----------------------------------------------------------------------------
-- Table 1.3: constituency_trends
-- Purpose: Trend analysis and historical comparisons (VERTICAL FORMAT)
-- Partition: By analysis_date
-- Cluster: By constituency_id, metric_name
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.constituency_trends` (
  -- Primary Keys
  trend_id STRING NOT NULL OPTIONS(description="Unique trend record ID (UUID)"),
  constituency_id STRING NOT NULL OPTIONS(description="Reference to constituency"),
  
  -- Metric Details
  metric_name STRING OPTIONS(description="Name of metric: health_score, satisfaction, etc."),
  current_value FLOAT64 OPTIONS(description="Current metric value"),
  previous_value FLOAT64 OPTIONS(description="Previous period metric value"),
  change_value FLOAT64 OPTIONS(description="Change in value"),
  change_percentage FLOAT64 OPTIONS(description="Percentage change"),
  trend_direction STRING OPTIONS(description="up, down, stable"),
  
  -- Analysis Period
  analysis_period STRING OPTIONS(description="Period type: daily, weekly, monthly"),
  analysis_date DATE NOT NULL OPTIONS(description="Date of analysis"),
  benchmark_value FLOAT64 OPTIONS(description="Benchmark comparison value"),
  
  -- Metadata
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP() OPTIONS(description="Record creation time")
)
PARTITION BY analysis_date
CLUSTER BY constituency_id, metric_name
OPTIONS(
  description="Historical trend analysis for constituency performance (vertical format)",
  labels=[("module", "command_center"), ("type", "analytics")]
);

-- ----------------------------------------------------------------------------
-- Table 1.4: executive_summary
-- Purpose: Executive-level summary reports and insights
-- Partition: By report_date
-- Cluster: By constituency_id
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `geo-pulse-463507.geo_pulse_data.executive_summary` (
  -- Primary Keys
  summary_id STRING NOT NULL OPTIONS(description="Unique summary record ID (UUID)"),
  constituency_id STRING NOT NULL OPTIONS(description="Reference to constituency"),
  report_date DATE NOT NULL OPTIONS(description="Date of summary report"),
  report_period STRING OPTIONS(description="Period type: monthly, quarterly"),
  
  -- Summary Metrics
  overall_health_score INT64 OPTIONS(description="Overall health score (0-100)"),
  
  -- Key Information (JSON Arrays)
  key_achievements STRING OPTIONS(description="JSON array of key achievements"),
  critical_issues STRING OPTIONS(description="JSON array of critical issues"),
  top_opportunities STRING OPTIONS(description="JSON array of opportunities"),
  immediate_actions STRING OPTIONS(description="JSON array of immediate actions"),
  risk_alerts STRING OPTIONS(description="JSON array of risk alerts"),
  
  -- Mood & Temperature
  constituency_mood STRING OPTIONS(description="Overall mood: positive, neutral, negative"),
  political_temperature INT64 OPTIONS(description="Political temperature score (0-100)"),
  
  -- Metadata
  generated_by STRING OPTIONS(description="System or user who generated report"),
  reviewed_by STRING OPTIONS(description="User who reviewed the report"),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP() OPTIONS(description="Report creation time"),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP() OPTIONS(description="Last update time")
)
PARTITION BY report_date
CLUSTER BY constituency_id
OPTIONS(
  description="Executive summary reports with strategic insights and recommendations",
  labels=[("module", "command_center"), ("type", "reports")]
);

-- ============================================================================
-- INDEXES AND CONSTRAINTS
-- ============================================================================

-- Note: BigQuery doesn't support traditional indexes, but clustering provides similar benefits
-- Primary key enforcement and uniqueness checks should be handled at application level

-- ============================================================================
-- DATA VALIDATION RULES
-- ============================================================================

-- Scores should be between 0-100
-- Risk levels: low, medium, high, critical
-- Trend types: daily, weekly, monthly
-- Status values: draft, published, archived
-- Priority levels: low, medium, high, critical

-- ============================================================================
-- SAMPLE QUERIES
-- ============================================================================

-- Get latest overview for all constituencies
-- SELECT * FROM `geo-pulse-463507.geo_pulse_data.constituency_overview` 
-- WHERE DATE(last_updated) = CURRENT_DATE()
-- ORDER BY health_score DESC;

-- Get KPIs for last 30 days for a constituency
-- SELECT * FROM `geo-pulse-463507.geo_pulse_data.constituency_kpis`
-- WHERE constituency_id = 'TEL001'
--   AND kpi_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
-- ORDER BY kpi_date DESC;

-- Get trend analysis for a constituency
-- SELECT * FROM `geo-pulse-463507.geo_pulse_data.constituency_trends`
-- WHERE constituency_id = 'TEL001'
--   AND trend_type = 'weekly'
-- ORDER BY trend_date DESC
-- LIMIT 12;

-- ============================================================================
-- END OF COMMAND CENTER TABLES
-- ============================================================================
