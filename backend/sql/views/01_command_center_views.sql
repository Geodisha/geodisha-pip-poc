-- =====================================================
-- Command Center Views
-- Optimized views for dashboard queries
-- =====================================================

-- View 1: Latest Constituency Overview
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_constituency_overview_latest` AS
SELECT 
  constituency_id,
  constituency_name,
  health_score,
  risk_level,
  total_population,
  total_voters,
  active_issues,
  resolved_issues_30d,
  satisfaction_score,
  last_updated
FROM `geo-pulse-463507.geo_pulse_data.constituency_overview`
WHERE DATE(last_updated) = (
  SELECT MAX(DATE(last_updated)) 
  FROM `geo-pulse-463507.geo_pulse_data.constituency_overview`
);

-- View 2: KPI Trends (Last 30 Days)
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_kpi_trends_30d` AS
SELECT 
  constituency_id,
  report_date,
  visits_conducted,
  people_contacted,
  grievances_received,
  grievances_resolved,
  events_conducted,
  promises_on_track,
  promises_delayed,
  alert_count,
  critical_alerts
FROM `geo-pulse-463507.geo_pulse_data.constituency_kpis`
WHERE report_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
ORDER BY constituency_id, report_date DESC;

-- View 3: Executive Summary Dashboard
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_executive_summary_current` AS
WITH latest_summary AS (
  SELECT 
    constituency_id,
    report_date,
    ROW_NUMBER() OVER (PARTITION BY constituency_id ORDER BY report_date DESC) as rn
  FROM `geo-pulse-463507.geo_pulse_data.executive_summary`
)
SELECT 
  es.constituency_id,
  es.report_date,
  es.overall_health_score,
  es.key_achievements,
  es.critical_issues,
  es.top_opportunities,
  es.immediate_actions,
  es.risk_alerts,
  es.constituency_mood,
  es.political_temperature
FROM `geo-pulse-463507.geo_pulse_data.executive_summary` es
INNER JOIN latest_summary ls 
  ON es.constituency_id = ls.constituency_id 
  AND es.report_date = ls.report_date
WHERE ls.rn = 1;

-- View 4: Trend Analysis Summary
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_trends_summary` AS
SELECT 
  constituency_id,
  metric_name,
  current_value,
  previous_value,
  change_percentage,
  trend_direction,
  analysis_period
FROM `geo-pulse-463507.geo_pulse_data.constituency_trends`
WHERE analysis_date = (
  SELECT MAX(analysis_date) 
  FROM `geo-pulse-463507.geo_pulse_data.constituency_trends`
)
ORDER BY 
  constituency_id,
  CASE metric_name 
    WHEN 'health_score' THEN 1
    WHEN 'satisfaction' THEN 2
    WHEN 'visit_coverage' THEN 3
    ELSE 4
  END;
