-- ============================================================================
-- Module 6: ALERTS & CRISIS MANAGEMENT VIEWS
-- Dataset: geo-pulse-463507.geo_pulse_data
-- Purpose: Real-time alerts, crisis tracking, and escalation monitoring
-- Created: 2024-12-03
-- ============================================================================

-- ----------------------------------------------------------------------------
-- View 6.1: v_alerts_active
-- Purpose: Active alerts requiring attention or action
-- Usage: Real-time alert monitoring and response dashboard
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_alerts_active` AS
SELECT 
  a.alert_id,
  a.constituency_id,
  a.alert_type,
  a.alert_category,
  a.title,
  a.description,
  a.severity,
  a.urgency,
  a.location_type,
  a.location_ward,
  a.potential_impact,
  a.estimated_people_affected,
  a.estimated_voters_affected,
  a.political_risk_score,
  
  -- Source Information
  a.source_type,
  a.source_credibility,
  a.reported_by,
  a.incident_time,
  a.detected_at,
  a.reported_at,
  
  -- Status & Assignment
  a.status,
  a.priority,
  a.assigned_to,
  a.assigned_at,
  a.escalated_to,
  a.escalation_level,
  
  -- Time Metrics
  DATE_DIFF(CURRENT_TIMESTAMP(), a.reported_at, MINUTE) as minutes_since_reported,
  DATE_DIFF(CURRENT_TIMESTAMP(), a.assigned_at, MINUTE) as minutes_since_assigned,
  
  -- SLA Compliance
  CASE a.severity
    WHEN 'critical' THEN 15  -- 15 minutes
    WHEN 'high' THEN 60      -- 1 hour
    WHEN 'medium' THEN 240   -- 4 hours
    ELSE 1440                -- 24 hours
  END as response_sla_minutes,
  
  CASE 
    WHEN a.status = 'new' AND 
         DATE_DIFF(CURRENT_TIMESTAMP(), a.reported_at, MINUTE) > 
         CASE a.severity
           WHEN 'critical' THEN 15
           WHEN 'high' THEN 60
           WHEN 'medium' THEN 240
           ELSE 1440
         END 
    THEN 'SLA Breached'
    WHEN a.status IN ('acknowledged', 'investigating') AND 
         DATE_DIFF(CURRENT_TIMESTAMP(), a.assigned_at, MINUTE) > 
         CASE a.severity
           WHEN 'critical' THEN 60
           WHEN 'high' THEN 240
           WHEN 'medium' THEN 480
           ELSE 2880
         END
    THEN 'SLA At Risk'
    ELSE 'Within SLA'
  END as sla_status,
  
  -- Priority Score for sorting
  CASE a.severity
    WHEN 'critical' THEN 100
    WHEN 'high' THEN 75
    WHEN 'medium' THEN 50
    ELSE 25
  END + 
  CASE a.urgency
    WHEN 'immediate' THEN 50
    WHEN 'within_24h' THEN 25
    WHEN 'within_week' THEN 10
    ELSE 0
  END +
  (a.political_risk_score / 2) as priority_score,
  
  -- Response Progress
  a.actions_taken,
  0 as actions_count,
  
  -- Related Data
  a.related_alerts,
  a.related_promises,
  a.related_visits,
  
  -- AI Analysis
  a.ai_sentiment_score,
  a.ai_risk_prediction,
  a.ai_recommended_actions,
  
  -- Documentation
  a.photos,
  a.videos,
  a.documents,
  a.media_coverage,
  
  a.created_at,
  a.updated_at

FROM `geo-pulse-463507.geo_pulse_data.alerts` a
WHERE a.status IN ('new', 'acknowledged', 'investigating', 'action_taken', 'monitoring')
ORDER BY priority_score DESC, a.reported_at ASC;

-- ----------------------------------------------------------------------------
-- View 6.2: v_alerts_statistics
-- Purpose: Real-time alert statistics and performance metrics
-- Usage: Dashboard KPIs and trend analysis
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_alerts_statistics` AS
WITH daily_stats AS (
  SELECT 
    constituency_id,
    DATE(reported_at) as alert_date,
    COUNT(*) as total_alerts,
    SUM(CASE WHEN severity = 'critical' THEN 1 ELSE 0 END) as critical_alerts,
    SUM(CASE WHEN severity = 'high' THEN 1 ELSE 0 END) as high_alerts,
    SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) as resolved_alerts,
    SUM(CASE WHEN status = 'false_alarm' THEN 1 ELSE 0 END) as false_alarms,
    AVG(resolution_time_mins) as avg_resolution_time_mins,
    SUM(estimated_voters_affected) as total_voters_affected
  FROM `geo-pulse-463507.geo_pulse_data.alerts`
  WHERE reported_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  GROUP BY constituency_id, alert_date
),
current_active AS (
  SELECT 
    constituency_id,
    COUNT(*) as active_alerts,
    SUM(CASE WHEN severity = 'critical' THEN 1 ELSE 0 END) as active_critical,
    SUM(CASE WHEN urgency = 'immediate' THEN 1 ELSE 0 END) as immediate_urgency
  FROM `geo-pulse-463507.geo_pulse_data.alerts`
  WHERE status IN ('new', 'acknowledged', 'investigating', 'action_taken')
  GROUP BY constituency_id
),
category_breakdown AS (
  SELECT 
    constituency_id,
    alert_category,
    COUNT(*) as category_count
  FROM `geo-pulse-463507.geo_pulse_data.alerts`
  WHERE reported_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  GROUP BY constituency_id, alert_category
)
SELECT 
  ds.constituency_id,
  ds.alert_date,
  ds.total_alerts,
  ds.critical_alerts,
  ds.high_alerts,
  ds.resolved_alerts,
  ds.false_alarms,
  
  -- Resolution Metrics
  ROUND(ds.avg_resolution_time_mins, 1) as avg_resolution_time_mins,
  SAFE_DIVIDE(ds.resolved_alerts, ds.total_alerts) * 100 as resolution_rate,
  SAFE_DIVIDE(ds.false_alarms, ds.total_alerts) * 100 as false_alarm_rate,
  
  -- Impact
  ds.total_voters_affected,
  
  -- Current Active Status
  COALESCE(ca.active_alerts, 0) as current_active_alerts,
  COALESCE(ca.active_critical, 0) as current_critical_alerts,
  COALESCE(ca.immediate_urgency, 0) as current_immediate_alerts,
  
  -- Performance Category
  CASE 
    WHEN ds.avg_resolution_time_mins <= 120 THEN 'Excellent Response'
    WHEN ds.avg_resolution_time_mins <= 360 THEN 'Good Response'
    WHEN ds.avg_resolution_time_mins <= 720 THEN 'Fair Response'
    ELSE 'Slow Response'
  END as response_performance,
  
  -- Trend Indicators
  LAG(ds.total_alerts) OVER (
    PARTITION BY ds.constituency_id 
    ORDER BY ds.alert_date
  ) as prev_day_alerts,
  
  ds.total_alerts - LAG(ds.total_alerts) OVER (
    PARTITION BY ds.constituency_id 
    ORDER BY ds.alert_date
  ) as day_over_day_change,
  
  -- 7-day rolling average
  AVG(ds.total_alerts) OVER (
    PARTITION BY ds.constituency_id 
    ORDER BY ds.alert_date 
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) as rolling_7day_avg

FROM daily_stats ds
LEFT JOIN current_active ca
  ON ds.constituency_id = ca.constituency_id
  AND ds.alert_date = CURRENT_DATE()
ORDER BY ds.constituency_id, ds.alert_date DESC;

-- ----------------------------------------------------------------------------
-- View 6.3: v_crisis_dashboard
-- Purpose: Active crisis events and response monitoring
-- Usage: Crisis management and coordination
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_crisis_dashboard` AS
SELECT 
  ce.crisis_id,
  ce.constituency_id,
  ce.crisis_type,
  ce.crisis_name,
  ce.description,
  ce.severity_level,
  ce.status,
  
  -- Timeline
  ce.start_time,
  ce.end_time,
  ce.duration_hours,
  DATE_DIFF(CURRENT_TIMESTAMP(), ce.start_time, HOUR) as hours_since_start,
  CASE 
    WHEN ce.status = 'active' THEN 'Ongoing'
    WHEN ce.status = 'contained' THEN 'Under Control'
    WHEN ce.status = 'resolved' THEN 'Resolved'
    ELSE 'Monitoring'
  END as crisis_state,
  
  -- Impact Assessment (parse JSON from STRING fields)
  ce.affected_locations,
  ce.impact_metrics,
  SAFE_CAST(JSON_EXTRACT_SCALAR(ce.impact_metrics, '$.people_affected') AS INT64) as people_affected,
  SAFE_CAST(JSON_EXTRACT_SCALAR(ce.impact_metrics, '$.households_affected') AS INT64) as households_affected,
  SAFE_CAST(JSON_EXTRACT_SCALAR(ce.impact_metrics, '$.voters_affected') AS INT64) as voters_affected,
  SAFE_CAST(JSON_EXTRACT_SCALAR(ce.impact_metrics, '$.casualties') AS INT64) as casualties,
  SAFE_CAST(JSON_EXTRACT_SCALAR(ce.impact_metrics, '$.injuries') AS INT64) as injuries,
  SAFE_CAST(JSON_EXTRACT_SCALAR(ce.impact_metrics, '$.property_damage_estimate') AS FLOAT64) as property_damage_estimate,
  
  -- Impact Severity
  CASE 
    WHEN SAFE_CAST(JSON_EXTRACT_SCALAR(ce.impact_metrics, '$.casualties') AS INT64) > 0 OR ce.severity_level = 'catastrophic' THEN 'Life Threatening'
    WHEN SAFE_CAST(JSON_EXTRACT_SCALAR(ce.impact_metrics, '$.voters_affected') AS INT64) >= 10000 THEN 'Major Impact'
    WHEN SAFE_CAST(JSON_EXTRACT_SCALAR(ce.impact_metrics, '$.voters_affected') AS INT64) >= 1000 THEN 'Significant Impact'
    ELSE 'Limited Impact'
  END as impact_category,
  
  -- Political Sensitivity
  ce.political_sensitivity,
  ce.media_attention_level,
  ce.opposition_exploitation_risk,
  ce.voter_sentiment_impact,
  
  -- Political Risk Score
  CASE ce.political_sensitivity
    WHEN 'very_high' THEN 40
    WHEN 'high' THEN 30
    WHEN 'medium' THEN 20
    ELSE 10
  END +
  CASE ce.media_attention_level
    WHEN 'viral' THEN 30
    WHEN 'high' THEN 20
    WHEN 'medium' THEN 10
    ELSE 0
  END +
  CASE ce.opposition_exploitation_risk
    WHEN 'high' THEN 30
    WHEN 'medium' THEN 15
    ELSE 5
  END as political_risk_score,
  
  -- Response Management
  ce.response_team,
  ce.command_center_location,
  ce.response_coordinator,
  
  -- Relief Measures
  ce.relief_measures,
  
  -- Resources (parse JSON from STRING)
  ce.resources_deployed,
  SAFE_CAST(JSON_EXTRACT_SCALAR(ce.resources_deployed, '$.personnel') AS INT64) as personnel,
  SAFE_CAST(JSON_EXTRACT_SCALAR(ce.resources_deployed, '$.vehicles') AS INT64) as vehicles,
  SAFE_CAST(JSON_EXTRACT_SCALAR(ce.resources_deployed, '$.medical_teams') AS INT64) as medical_teams,
  SAFE_CAST(JSON_EXTRACT_SCALAR(ce.resources_deployed, '$.relief_camps') AS INT64) as relief_camps,
  SAFE_CAST(JSON_EXTRACT_SCALAR(ce.resources_deployed, '$.total_budget_spent') AS FLOAT64) as total_budget_spent,
  
  -- Status Assessment
  CASE 
    WHEN ce.status = 'active' AND DATE_DIFF(CURRENT_TIMESTAMP(), ce.start_time, HOUR) > 48 THEN 'Extended Crisis'
    WHEN ce.status = 'active' AND ce.severity_level IN ('catastrophic', 'severe') THEN 'Critical Situation'
    WHEN ce.status = 'contained' THEN 'Stabilizing'
    WHEN ce.status = 'resolved' AND ce.end_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY) THEN 'Recently Resolved'
    ELSE 'Normal'
  END as situation_assessment,
  
  -- Media Management
  ce.public_statements,
  ce.media_briefings_count,
  ce.social_media_updates_count,
  
  ce.created_at,
  ce.updated_at

FROM `geo-pulse-463507.geo_pulse_data.crisis_events` ce
WHERE ce.status IN ('active', 'contained', 'monitoring')
   OR ce.end_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
ORDER BY 
  CASE ce.status 
    WHEN 'active' THEN 1 
    WHEN 'contained' THEN 2 
    ELSE 3 
  END,
  political_risk_score DESC,
  ce.start_time DESC;

-- ----------------------------------------------------------------------------
-- View 6.4: v_alert_resolution_metrics
-- Purpose: Performance metrics for alert resolution and response
-- Usage: Team performance evaluation and process improvement
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_alert_resolution_metrics` AS
WITH resolution_data AS (
  SELECT 
    constituency_id,
    alert_category,
    severity,
    urgency,
    status,
    resolution_time_mins,
    DATE_DIFF(CURRENT_TIMESTAMP(), reported_at, DAY) as days_since_reported,
    CASE 
      WHEN resolved_at IS NOT NULL THEN DATE_DIFF(resolved_at, reported_at, MINUTE)
      ELSE NULL
    END as actual_resolution_mins,
    source_credibility,
    escalation_level,
    0 as actions_taken_count
  FROM `geo-pulse-463507.geo_pulse_data.alerts`
  WHERE reported_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
),
escalation_metrics AS (
  SELECT 
    constituency_id,
    COUNT(*) as total_escalations,
    AVG(days_since_reported) as avg_escalation_time,
    SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) as resolved_escalations
  FROM `geo-pulse-463507.geo_pulse_data.issue_escalations`
  WHERE escalated_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
  GROUP BY constituency_id
)
SELECT 
  rd.constituency_id,
  rd.alert_category,
  rd.severity,
  
  -- Volume Metrics
  COUNT(*) as total_alerts,
  SUM(CASE WHEN rd.status = 'resolved' THEN 1 ELSE 0 END) as resolved_count,
  SUM(CASE WHEN rd.status = 'false_alarm' THEN 1 ELSE 0 END) as false_alarm_count,
  SUM(CASE WHEN rd.status IN ('new', 'acknowledged', 'investigating') THEN 1 ELSE 0 END) as pending_count,
  
  -- Resolution Rates
  SAFE_DIVIDE(
    SUM(CASE WHEN rd.status = 'resolved' THEN 1 ELSE 0 END),
    COUNT(*)
  ) * 100 as resolution_rate,
  
  SAFE_DIVIDE(
    SUM(CASE WHEN rd.status = 'false_alarm' THEN 1 ELSE 0 END),
    COUNT(*)
  ) * 100 as false_alarm_rate,
  
  -- Time Metrics (for resolved alerts)
  AVG(rd.actual_resolution_mins) as avg_resolution_time_mins,
  MIN(rd.actual_resolution_mins) as min_resolution_time_mins,
  MAX(rd.actual_resolution_mins) as max_resolution_time_mins,
  APPROX_QUANTILES(rd.actual_resolution_mins, 100)[OFFSET(50)] as median_resolution_time_mins,
  APPROX_QUANTILES(rd.actual_resolution_mins, 100)[OFFSET(90)] as p90_resolution_time_mins,
  
  -- SLA Performance
  SUM(CASE 
    WHEN rd.status = 'resolved' AND rd.actual_resolution_mins <= 
      CASE rd.severity
        WHEN 'critical' THEN 60
        WHEN 'high' THEN 240
        WHEN 'medium' THEN 720
        ELSE 1440
      END
    THEN 1 ELSE 0 
  END) as within_sla_count,
  
  SAFE_DIVIDE(
    SUM(CASE 
      WHEN rd.status = 'resolved' AND rd.actual_resolution_mins <= 
        CASE rd.severity
          WHEN 'critical' THEN 60
          WHEN 'high' THEN 240
          WHEN 'medium' THEN 720
          ELSE 1440
        END
      THEN 1 ELSE 0 
    END),
    SUM(CASE WHEN rd.status = 'resolved' THEN 1 ELSE 0 END)
  ) * 100 as sla_compliance_rate,
  
  -- Response Quality
  AVG(rd.actions_taken_count) as avg_actions_per_alert,
  AVG(CASE WHEN rd.escalation_level > 0 THEN 1.0 ELSE 0.0 END) * 100 as escalation_rate,
  
  -- Source Quality
  AVG(CASE rd.source_credibility
    WHEN 'high' THEN 3
    WHEN 'medium' THEN 2
    WHEN 'low' THEN 1
    ELSE 0
  END) as avg_source_credibility_score,
  
  -- Performance Category
  CASE 
    WHEN AVG(rd.actual_resolution_mins) <= 120 AND
         SAFE_DIVIDE(SUM(CASE WHEN rd.status = 'resolved' THEN 1 ELSE 0 END), COUNT(*)) >= 0.8
    THEN 'Excellent'
    WHEN AVG(rd.actual_resolution_mins) <= 360 AND
         SAFE_DIVIDE(SUM(CASE WHEN rd.status = 'resolved' THEN 1 ELSE 0 END), COUNT(*)) >= 0.6
    THEN 'Good'
    WHEN AVG(rd.actual_resolution_mins) <= 720 AND
         SAFE_DIVIDE(SUM(CASE WHEN rd.status = 'resolved' THEN 1 ELSE 0 END), COUNT(*)) >= 0.4
    THEN 'Fair'
    ELSE 'Needs Improvement'
  END as performance_category,
  
  -- Escalation Data
  em.total_escalations,
  em.avg_escalation_time,
  em.resolved_escalations

FROM resolution_data rd
LEFT JOIN escalation_metrics em
  ON rd.constituency_id = em.constituency_id
GROUP BY 
  rd.constituency_id,
  rd.alert_category,
  rd.severity,
  em.total_escalations,
  em.avg_escalation_time,
  em.resolved_escalations
HAVING total_alerts >= 5  -- Only include categories with meaningful data
ORDER BY 
  rd.constituency_id,
  total_alerts DESC,
  resolution_rate DESC;

-- ============================================================================
-- End of Alerts & Crisis Management Views
-- ============================================================================
