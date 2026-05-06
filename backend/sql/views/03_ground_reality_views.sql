-- ============================================================================
-- Module 3: GROUND REALITY VIEWS
-- Dataset: geo-pulse-463507.geo_pulse_data
-- Purpose: Visit tracking, heatmap analytics, and ward intelligence
-- Created: 2024-12-03
-- ============================================================================

-- ----------------------------------------------------------------------------
-- View 3.1: v_visits_enhanced
-- Purpose: Enhanced visit records with statistics and context
-- Usage: Visit tracking and ground reality analysis
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_visits_enhanced` AS
SELECT 
  vr.visit_id,
  vr.constituency_id,
  vr.visit_date,
  vr.visit_time,
  vr.location_ward,
  vr.visit_type,
  vr.visit_category,
  vr.leader_name,
  vr.leader_role,
  vr.total_attendance,
  vr.grievances_count,
  vr.grievances_resolved_on_spot,
  vr.public_sentiment,
  vr.sentiment_score,
  vr.photos_count,
  vr.videos_count,
  vr.media_coverage,
  vr.recorded_by,
  vr.verification_status,
  vr.created_at,
  vr.updated_at,
  
  -- Calculated metrics
  SAFE_DIVIDE(vr.grievances_resolved_on_spot, vr.grievances_count) * 100 as on_spot_resolution_rate,
  
  -- Sentiment category
  CASE 
    WHEN vr.sentiment_score >= 0.7 THEN 'Very Positive'
    WHEN vr.sentiment_score >= 0.4 THEN 'Positive'
    WHEN vr.sentiment_score >= 0 THEN 'Neutral'
    WHEN vr.sentiment_score >= -0.4 THEN 'Negative'
    ELSE 'Very Negative'
  END as sentiment_category,
  
  -- Attendance category
  CASE 
    WHEN vr.total_attendance >= 500 THEN 'Very Large'
    WHEN vr.total_attendance >= 200 THEN 'Large'
    WHEN vr.total_attendance >= 50 THEN 'Medium'
    WHEN vr.total_attendance >= 10 THEN 'Small'
    ELSE 'Very Small'
  END as attendance_category,
  
  -- Documentation score
  CASE 
    WHEN vr.photos_count + vr.videos_count >= 10 THEN 'Well Documented'
    WHEN vr.photos_count + vr.videos_count >= 5 THEN 'Adequately Documented'
    WHEN vr.photos_count + vr.videos_count >= 1 THEN 'Minimally Documented'
    ELSE 'Not Documented'
  END as documentation_status,
  
  -- Days since visit
  DATE_DIFF(CURRENT_DATE(), vr.visit_date, DAY) as days_since_visit,
  
  -- Ward statistics from ward_intelligence
  wi.total_voters as ward_total_voters,
  wi.overall_health_score as ward_health_score,
  wi.risk_level as ward_risk_level

FROM `geo-pulse-463507.geo_pulse_data.visit_records_enhanced` vr
LEFT JOIN `geo-pulse-463507.geo_pulse_data.ward_intelligence` wi
  ON vr.constituency_id = wi.constituency_id
  AND vr.location_ward = wi.ward_name
  AND wi.report_date = (
    SELECT MAX(report_date) 
    FROM `geo-pulse-463507.geo_pulse_data.ward_intelligence` 
    WHERE constituency_id = vr.constituency_id
  )
WHERE vr.verification_status != 'flagged'
ORDER BY vr.visit_date DESC, vr.visit_time DESC;

-- ----------------------------------------------------------------------------
-- View 3.2: v_heatmap_current
-- Purpose: Current issue concentration and risk levels by ward
-- Usage: Heatmap visualization and resource allocation
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_heatmap_current` AS
WITH latest_heatmap AS (
  SELECT 
    constituency_id,
    location_ward,
    MAX(data_date) as latest_date
  FROM `geo-pulse-463507.geo_pulse_data.issue_heatmap`
  GROUP BY constituency_id, location_ward
)
SELECT 
  ih.heatmap_id,
  ih.constituency_id,
  ih.location_ward,
  ih.data_date,
  ih.total_issues_reported,
  ih.critical_issues,
  ih.resolved_issues,
  ih.pending_issues,
  ih.resolution_rate,
  ih.intensity_score,
  ih.severity_index,
  ih.urgency_index,
  ih.population_estimate,
  ih.issues_per_capita,
  ih.last_visit_date,
  ih.days_since_last_visit,
  ih.visit_frequency_30d,
  ih.created_at,
  
  -- Issue severity classification
  CASE 
    WHEN ih.intensity_score >= 0.8 THEN 'Critical'
    WHEN ih.intensity_score >= 0.6 THEN 'High'
    WHEN ih.intensity_score >= 0.4 THEN 'Medium'
    WHEN ih.intensity_score >= 0.2 THEN 'Low'
    ELSE 'Minimal'
  END as intensity_category,
  
  -- Attention needed indicator
  CASE 
    WHEN ih.critical_issues > 0 THEN 'Immediate Attention'
    WHEN ih.days_since_last_visit > 30 THEN 'Overdue Visit'
    WHEN ih.pending_issues >= 10 THEN 'High Pending Issues'
    WHEN ih.resolution_rate < 0.5 THEN 'Low Resolution Rate'
    ELSE 'Normal'
  END as attention_status,
  
  -- Visit priority score
  (ih.intensity_score * 40) + 
  (LEAST(ih.days_since_last_visit / 30.0, 1.0) * 30) +
  (SAFE_DIVIDE(ih.pending_issues, 20.0) * 30) as visit_priority_score,
  
  -- Resolution performance
  CASE 
    WHEN ih.resolution_rate >= 0.8 THEN 'Excellent'
    WHEN ih.resolution_rate >= 0.6 THEN 'Good'
    WHEN ih.resolution_rate >= 0.4 THEN 'Fair'
    ELSE 'Poor'
  END as resolution_performance,
  
  -- Ward statistics
  wi.overall_health_score as ward_health_score,
  wi.satisfaction_score as ward_satisfaction_score,
  wi.risk_level as ward_risk_level,
  wi.total_voters as ward_total_voters

FROM `geo-pulse-463507.geo_pulse_data.issue_heatmap` ih
INNER JOIN latest_heatmap lh
  ON ih.constituency_id = lh.constituency_id
  AND ih.location_ward = lh.location_ward
  AND ih.data_date = lh.latest_date
LEFT JOIN `geo-pulse-463507.geo_pulse_data.ward_intelligence` wi
  ON ih.constituency_id = wi.constituency_id
  AND ih.location_ward = wi.ward_name
  AND wi.report_date = (
    SELECT MAX(report_date) 
    FROM `geo-pulse-463507.geo_pulse_data.ward_intelligence`
    WHERE constituency_id = ih.constituency_id
  )
ORDER BY visit_priority_score DESC, ih.intensity_score DESC;

-- ----------------------------------------------------------------------------
-- View 3.3: v_ward_coverage
-- Purpose: Ward-wise coverage analysis and engagement metrics
-- Usage: Coverage planning and resource allocation
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_ward_coverage` AS
WITH latest_ward_data AS (
  SELECT 
    constituency_id,
    ward_name,
    MAX(report_date) as latest_date
  FROM `geo-pulse-463507.geo_pulse_data.ward_intelligence`
  GROUP BY constituency_id, ward_name
)
SELECT 
  wi.ward_id,
  wi.constituency_id,
  wi.ward_name,
  wi.report_date,
  wi.total_population,
  wi.total_voters,
  wi.total_households,
  
  -- Coverage Metrics
  wi.last_leader_visit_date,
  wi.visit_frequency_30d,
  wi.visit_frequency_90d,
  wi.leader_visibility_score,
  DATE_DIFF(CURRENT_DATE(), wi.last_leader_visit_date, DAY) as days_since_visit,
  
  -- Health Scores
  wi.infrastructure_score,
  wi.public_service_score,
  wi.safety_score,
  wi.development_score,
  wi.satisfaction_score,
  wi.overall_health_score,
  
  -- Health category
  CASE 
    WHEN wi.overall_health_score >= 80 THEN 'Excellent'
    WHEN wi.overall_health_score >= 60 THEN 'Good'
    WHEN wi.overall_health_score >= 40 THEN 'Fair'
    ELSE 'Poor'
  END as health_category,
  
  -- Community Engagement
  wi.active_volunteers,
  wi.community_events_30d,
  SAFE_DIVIDE(wi.active_volunteers, wi.total_voters) * 1000 as volunteers_per_1000_voters,
  
  -- Opposition Analysis
  wi.opposition_activity_level,
  wi.opposition_events_30d,
  wi.competitive_threat_score,
  
  -- Risk Assessment
  wi.risk_level,
  wi.attention_required,
  
  -- Coverage priority
  CASE 
    WHEN CAST(wi.attention_required AS STRING) = 'true' THEN 'High Priority'
    WHEN wi.risk_level = 'high' THEN 'High Priority'
    WHEN DATE_DIFF(CURRENT_DATE(), wi.last_leader_visit_date, DAY) > 60 THEN 'Medium Priority'
    WHEN wi.visit_frequency_30d < 2 THEN 'Medium Priority'
    ELSE 'Low Priority'
  END as coverage_priority,
  
  -- Engagement score
  (wi.leader_visibility_score * 0.4) + 
  (wi.satisfaction_score * 0.3) +
  (LEAST(wi.visit_frequency_30d * 10, 100) * 0.3) as engagement_score,
  
  wi.created_at,
  wi.updated_at

FROM `geo-pulse-463507.geo_pulse_data.ward_intelligence` wi
INNER JOIN latest_ward_data lwd
  ON wi.constituency_id = lwd.constituency_id
  AND wi.ward_name = lwd.ward_name
  AND wi.report_date = lwd.latest_date
ORDER BY 
  CASE wi.risk_level WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END,
  wi.overall_health_score ASC,
  days_since_visit DESC;

-- ----------------------------------------------------------------------------
-- View 3.4: v_visit_trends
-- Purpose: Visit pattern analysis and trends
-- Usage: Visit planning and trend visualization
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_visit_trends` AS
WITH daily_visits AS (
  SELECT 
    constituency_id,
    location_ward,
    visit_date,
    COUNT(*) as visit_count,
    SUM(total_attendance) as total_attendance,
    SUM(grievances_count) as total_grievances,
    SUM(grievances_resolved_on_spot) as resolved_grievances,
    AVG(sentiment_score) as avg_sentiment,
    COUNT(CASE WHEN media_coverage = TRUE THEN 1 END) as media_covered_visits
  FROM `geo-pulse-463507.geo_pulse_data.visit_records_enhanced`
  WHERE visit_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  GROUP BY constituency_id, location_ward, visit_date
),
weekly_aggregates AS (
  SELECT 
    constituency_id,
    location_ward,
    DATE_TRUNC(visit_date, WEEK) as week_start,
    SUM(visit_count) as weekly_visits,
    SUM(total_attendance) as weekly_attendance,
    AVG(avg_sentiment) as weekly_avg_sentiment,
    SUM(total_grievances) as weekly_grievances
  FROM daily_visits
  GROUP BY constituency_id, location_ward, week_start
)
SELECT 
  wa.constituency_id,
  wa.location_ward,
  wa.week_start,
  wa.weekly_visits,
  wa.weekly_attendance,
  ROUND(wa.weekly_avg_sentiment, 3) as weekly_avg_sentiment,
  wa.weekly_grievances,
  
  -- Trend indicators
  CASE 
    WHEN wa.weekly_visits >= 10 THEN 'Very Active'
    WHEN wa.weekly_visits >= 5 THEN 'Active'
    WHEN wa.weekly_visits >= 2 THEN 'Moderate'
    WHEN wa.weekly_visits >= 1 THEN 'Low'
    ELSE 'Inactive'
  END as activity_level,
  
  -- Average attendance per visit
  SAFE_DIVIDE(wa.weekly_attendance, wa.weekly_visits) as avg_attendance_per_visit,
  
  -- Sentiment trend
  CASE 
    WHEN wa.weekly_avg_sentiment >= 0.6 THEN 'Positive'
    WHEN wa.weekly_avg_sentiment >= 0.3 THEN 'Neutral'
    ELSE 'Negative'
  END as sentiment_trend,
  
  -- Comparison with previous week
  LAG(wa.weekly_visits) OVER (
    PARTITION BY wa.constituency_id, wa.location_ward 
    ORDER BY wa.week_start
  ) as prev_week_visits,
  
  wa.weekly_visits - LAG(wa.weekly_visits) OVER (
    PARTITION BY wa.constituency_id, wa.location_ward 
    ORDER BY wa.week_start
  ) as visit_change,
  
  -- Statistics
  vs.total_visits as constituency_total_visits,
  vs.average_attendance_per_visit as constituency_avg_attendance,
  vs.total_grievances_collected as constituency_total_grievances,
  vs.average_sentiment_score as constituency_avg_sentiment

FROM weekly_aggregates wa
LEFT JOIN `geo-pulse-463507.geo_pulse_data.visit_statistics` vs
  ON wa.constituency_id = vs.constituency_id
  AND vs.report_date = (
    SELECT MAX(report_date) 
    FROM `geo-pulse-463507.geo_pulse_data.visit_statistics`
    WHERE constituency_id = wa.constituency_id
  )
ORDER BY wa.constituency_id, wa.location_ward, wa.week_start DESC;

-- ============================================================================
-- End of Ground Reality Views
-- ============================================================================
