-- ============================================================================
-- Module 4: ELECTION WAR ROOM VIEWS (SIMPLIFIED)
-- Dataset: geo-pulse-463507.geo_pulse_data
-- Purpose: Booth analysis and election intelligence
-- Created: 2024-12-03
-- ============================================================================

-- ----------------------------------------------------------------------------
-- View 4.1: v_booth_scores_summary
-- Purpose: Aggregated booth scores with performance categorization
-- Usage: Booth performance dashboard and war room analytics
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_booth_scores_summary` AS
WITH latest_analysis AS (
  SELECT 
    booth_id,
    MAX(analysis_date) as latest_date
  FROM `geo-pulse-463507.geo_pulse_data.booth_analysis`
  GROUP BY booth_id
)
SELECT 
  ba.booth_id,
  ba.constituency_id,
  ba.booth_number,
  ba.booth_name,
  ba.location_ward,
  ba.analysis_date,
  
  -- Voter Demographics
  ba.total_voters,
  ba.male_voters,
  ba.female_voters,
  ba.first_time_voters,
  ba.senior_voters,
  SAFE_DIVIDE(ba.female_voters, ba.total_voters) * 100 as female_voter_percentage,
  
  -- Booth Score
  ba.booth_score,
  CASE 
    WHEN ba.booth_score >= 80 THEN 'Stronghold'
    WHEN ba.booth_score >= 60 THEN 'Favorable'
    WHEN ba.booth_score >= 40 THEN 'Competitive'
    WHEN ba.booth_score >= 20 THEN 'Weak'
    ELSE 'Critical'
  END as strength_category,
  
  -- Risk Assessment
  ba.risk_level,
  ba.competitive_threat_score,
  
  -- Organization Strength
  ba.booth_agents,
  ba.active_volunteers,
  ba.booth_committee_strength,
  ba.last_meeting_date,
  DATE_DIFF(CURRENT_DATE(), ba.last_meeting_date, DAY) as days_since_meeting,
  
  -- Metadata
  ba.surveyed_by,
  ba.verification_date,
  ba.created_at,
  ba.updated_at

FROM `geo-pulse-463507.geo_pulse_data.booth_analysis` ba
INNER JOIN latest_analysis la
  ON ba.booth_id = la.booth_id
  AND ba.analysis_date = la.latest_date
ORDER BY ba.constituency_id, ba.booth_score ASC, ba.risk_level DESC;

-- ----------------------------------------------------------------------------
-- View 4.2: v_election_readiness
-- Purpose: Overall election readiness assessment by constituency
-- Usage: War room dashboard and readiness monitoring
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_election_readiness` AS
WITH booth_stats AS (
  SELECT 
    constituency_id,
    COUNT(*) as total_booths,
    SUM(total_voters) as total_voters,
    AVG(booth_score) as avg_booth_score,
    SUM(CASE WHEN booth_score >= 60 THEN 1 ELSE 0 END) as favorable_booths,
    SUM(CASE WHEN booth_score < 40 THEN 1 ELSE 0 END) as weak_booths,
    SUM(CASE WHEN risk_level = 'critical' THEN 1 ELSE 0 END) as critical_booths,
    SUM(CASE WHEN risk_level = 'vulnerable' THEN 1 ELSE 0 END) as vulnerable_booths,
    SUM(booth_agents) as total_booth_agents,
    SUM(active_volunteers) as total_volunteers
  FROM `geo-pulse-463507.geo_pulse_data.booth_analysis`
  WHERE analysis_date = (
    SELECT MAX(analysis_date) 
    FROM `geo-pulse-463507.geo_pulse_data.booth_analysis`
  )
  GROUP BY constituency_id
)
SELECT 
  bs.constituency_id,
  
  -- Booth Coverage
  bs.total_booths,
  bs.favorable_booths,
  bs.weak_booths,
  bs.critical_booths,
  bs.vulnerable_booths,
  SAFE_DIVIDE(bs.favorable_booths, bs.total_booths) * 100 as favorable_booth_percentage,
  SAFE_DIVIDE(bs.critical_booths + bs.vulnerable_booths, bs.total_booths) * 100 as at_risk_booth_percentage,
  
  -- Overall Readiness Score
  ROUND(bs.avg_booth_score, 1) as avg_booth_score,
  CASE 
    WHEN bs.avg_booth_score >= 70 THEN 'Excellent'
    WHEN bs.avg_booth_score >= 55 THEN 'Good'
    WHEN bs.avg_booth_score >= 40 THEN 'Fair'
    ELSE 'Poor'
  END as readiness_category,
  
  -- Organization Strength
  bs.total_voters,
  bs.total_booth_agents,
  bs.total_volunteers,
  SAFE_DIVIDE(bs.total_booth_agents, bs.total_booths) as agents_per_booth,
  SAFE_DIVIDE(bs.total_volunteers, bs.total_voters) * 1000 as volunteers_per_1000_voters,
  CASE 
    WHEN bs.total_booth_agents >= bs.total_booths THEN 'Full Coverage'
    WHEN bs.total_booth_agents >= bs.total_booths * 0.8 THEN 'Good Coverage'
    WHEN bs.total_booth_agents >= bs.total_booths * 0.5 THEN 'Partial Coverage'
    ELSE 'Insufficient Coverage'
  END as agent_coverage_status,
  
  -- Focus Areas
  CASE 
    WHEN bs.critical_booths > 0 THEN 'Address Critical Booths'
    WHEN SAFE_DIVIDE(bs.total_booth_agents, bs.total_booths) < 0.8 THEN 'Strengthen Agent Network'
    WHEN bs.avg_booth_score < 60 THEN 'Improve Overall Score'
    ELSE 'Maintain & Strengthen'
  END as primary_focus

FROM booth_stats bs
ORDER BY bs.avg_booth_score ASC, at_risk_booth_percentage DESC;

-- ----------------------------------------------------------------------------
-- View 4.3: v_booth_risk_matrix
-- Purpose: Risk categorization and prioritization matrix
-- Usage: Risk management and intervention planning
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_booth_risk_matrix` AS
WITH latest_trends AS (
  SELECT 
    booth_id,
    constituency_id,
    MAX(measurement_date) as latest_date
  FROM `geo-pulse-463507.geo_pulse_data.booth_score_trends`
  GROUP BY booth_id, constituency_id
)
SELECT 
  ba.booth_id,
  ba.constituency_id,
  ba.booth_number,
  ba.booth_name,
  ba.location_ward,
  ba.booth_score,
  ba.risk_level,
  ba.competitive_threat_score,
  
  -- Trend Analysis
  bst.booth_score as current_trend_score,
  bst.trend_direction,
  bst.momentum_score,
  bst.vs_previous_month as score_change_30d,
  
  -- Risk Matrix Position
  CASE 
    WHEN ba.booth_score < 40 AND ba.competitive_threat_score >= 70 THEN 'High Risk - High Threat'
    WHEN ba.booth_score < 40 AND ba.competitive_threat_score < 70 THEN 'High Risk - Low Threat'
    WHEN ba.booth_score >= 40 AND ba.competitive_threat_score >= 70 THEN 'Low Risk - High Threat'
    ELSE 'Low Risk - Low Threat'
  END as risk_matrix_quadrant,
  
  -- Priority Level
  CASE 
    WHEN ba.risk_level = 'critical' THEN 1
    WHEN ba.risk_level = 'vulnerable' AND bst.trend_direction = 'declining' THEN 2
    WHEN ba.risk_level = 'vulnerable' THEN 3
    WHEN ba.booth_score < 50 AND ba.competitive_threat_score >= 60 THEN 4
    WHEN bst.trend_direction = 'declining' THEN 5
    ELSE 6
  END as intervention_priority,
  
  -- Intervention Urgency
  CASE 
    WHEN ba.risk_level = 'critical' THEN 'Immediate'
    WHEN ba.risk_level = 'vulnerable' AND bst.momentum_score < -20 THEN 'This Week'
    WHEN ba.booth_score < 50 THEN 'This Month'
    ELSE 'Regular Monitoring'
  END as intervention_urgency,
  
  -- Organization Gaps
  CASE 
    WHEN ba.booth_agents = 0 THEN 'No Booth Agent'
    WHEN ba.active_volunteers < 5 THEN 'Low Volunteers'
    WHEN ba.booth_committee_strength IN ('weak', 'none') THEN 'Weak Committee'
    WHEN DATE_DIFF(CURRENT_DATE(), ba.last_meeting_date, DAY) > 30 THEN 'No Recent Meeting'
    ELSE 'Organization OK'
  END as organization_gap,
  
  ba.booth_agents,
  ba.active_volunteers,
  ba.booth_committee_strength,
  ba.total_voters,
  ba.analysis_date,
  ba.created_at

FROM `geo-pulse-463507.geo_pulse_data.booth_analysis` ba
LEFT JOIN `geo-pulse-463507.geo_pulse_data.booth_score_trends` bst
  ON ba.booth_id = bst.booth_id
INNER JOIN latest_trends lt
  ON ba.booth_id = lt.booth_id
  AND ba.analysis_date = lt.latest_date
  AND (bst.measurement_date = lt.latest_date OR bst.measurement_date IS NULL)
WHERE ba.risk_level IN ('critical', 'vulnerable', 'moderate')
ORDER BY intervention_priority ASC, ba.booth_score ASC;

-- ----------------------------------------------------------------------------
-- View 4.4: v_swing_analysis
-- Purpose: Booth-level swing analysis based on scores
-- Usage: Voter outreach and conversion planning
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_swing_analysis` AS
SELECT 
  ba.booth_id,
  ba.constituency_id,
  ba.booth_name,
  ba.location_ward,
  ba.total_voters,
  ba.booth_score,
  
  -- Swing Potential based on booth score
  CASE 
    WHEN ba.booth_score BETWEEN 35 AND 65 THEN 'Very High Swing Potential'
    WHEN ba.booth_score BETWEEN 25 AND 75 THEN 'High Swing Potential'
    WHEN ba.booth_score BETWEEN 20 AND 80 THEN 'Medium Swing Potential'
    ELSE 'Low Swing Potential'
  END as swing_classification,
  
  -- Estimated targetable voters (40% of voters in competitive booths)
  CASE 
    WHEN ba.booth_score BETWEEN 35 AND 65 THEN CAST(ba.total_voters * 0.4 AS INT64)
    WHEN ba.booth_score BETWEEN 25 AND 75 THEN CAST(ba.total_voters * 0.3 AS INT64)
    WHEN ba.booth_score BETWEEN 20 AND 80 THEN CAST(ba.total_voters * 0.2 AS INT64)
    ELSE CAST(ba.total_voters * 0.1 AS INT64)
  END as targetable_voters,
  
  -- Impact Score (swing potential × booth size)
  CASE 
    WHEN ba.booth_score BETWEEN 35 AND 65 THEN ba.total_voters * 40 / 100
    WHEN ba.booth_score BETWEEN 25 AND 75 THEN ba.total_voters * 30 / 100
    WHEN ba.booth_score BETWEEN 20 AND 80 THEN ba.total_voters * 20 / 100
    ELSE ba.total_voters * 10 / 100
  END as impact_score,
  
  -- Conversion Strategy
  CASE 
    WHEN ba.booth_score < 40 AND ba.booth_score BETWEEN 35 AND 65 THEN 'Critical - High Conversion Potential'
    WHEN ba.booth_score >= 60 AND ba.booth_score BETWEEN 35 AND 65 THEN 'Strengthen - High Conversion Potential'
    WHEN ba.booth_score < 40 THEN 'Critical - Standard Conversion'
    WHEN ba.booth_score BETWEEN 40 AND 60 THEN 'High - Focus on Swing'
    ELSE 'Standard - Regular Outreach'
  END as conversion_strategy,
  
  -- Recommended Approach
  CASE 
    WHEN ba.booth_score BETWEEN 40 AND 60 THEN 'Intensive Door-to-Door + Public Meetings'
    WHEN ba.booth_score BETWEEN 30 AND 70 THEN 'Targeted Outreach + Events'
    ELSE 'Regular Engagement'
  END as recommended_approach,
  
  ba.risk_level,
  ba.competitive_threat_score,
  ba.analysis_date

FROM `geo-pulse-463507.geo_pulse_data.booth_analysis` ba
WHERE ba.analysis_date = (
  SELECT MAX(analysis_date) 
  FROM `geo-pulse-463507.geo_pulse_data.booth_analysis`
)
  AND ba.booth_score BETWEEN 20 AND 80  -- Focus on competitive booths
ORDER BY 
  impact_score DESC,
  ba.total_voters DESC;

-- ============================================================================
-- End of Election War Room Views
-- ============================================================================
