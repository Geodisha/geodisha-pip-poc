-- ============================================================================
-- Module 4: ELECTION WAR ROOM VIEWS
-- Dataset: geo-pulse-463507.geo_pulse_data
-- Purpose: Booth analysis, election intelligence, and voter segmentation
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
  ba.location_village,
  ba.location_coordinates,
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
  
  -- Score Components
  ba.score_components.historical_performance as hist_performance_score,
  ba.score_components.current_sentiment as sentiment_score,
  ba.score_components.organization_strength as org_strength_score,
  ba.score_components.leader_connect as leader_connect_score,
  ba.score_components.ground_presence as ground_presence_score,
  
  -- Risk Assessment
  ba.risk_level,
  ba.risk_factors,
  ba.competitive_threat_score,
  
  -- Vote Estimation
  ba.estimated_votes.favorable as estimated_favorable_votes,
  ba.estimated_votes.opposition as estimated_opposition_votes,
  ba.estimated_votes.others as estimated_other_votes,
  ba.estimated_votes.confidence_level as estimation_confidence,
  SAFE_DIVIDE(ba.estimated_votes.favorable, 
    ba.estimated_votes.favorable + ba.estimated_votes.opposition + ba.estimated_votes.others
  ) * 100 as estimated_vote_share,
  
  -- Current Strength Assessment
  ba.current_strength.favorable_voters,
  ba.current_strength.leaning_favorable,
  ba.current_strength.neutral_voters,
  ba.current_strength.opposition_voters,
  ba.current_strength.undecided_voters,
  SAFE_DIVIDE(
    ba.current_strength.favorable_voters + ba.current_strength.leaning_favorable,
    ba.total_voters
  ) * 100 as support_base_percentage,
  
  -- Organization Strength
  ba.booth_agents,
  ba.active_volunteers,
  ba.booth_committee_strength,
  ba.last_meeting_date,
  DATE_DIFF(CURRENT_DATE(), ba.last_meeting_date, DAY) as days_since_meeting,
  
  -- Priority Actions
  ba.priority_actions,
  ARRAY_LENGTH(ba.priority_actions) as action_items_count,
  
  -- Metadata
  ba.surveyed_by,
  ba.verified_by,
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
    SUM(active_volunteers) as total_volunteers,
    SUM(estimated_votes.favorable) as total_estimated_favorable,
    SUM(estimated_votes.opposition) as total_estimated_opposition
  FROM `geo-pulse-463507.geo_pulse_data.booth_analysis`
  WHERE analysis_date = (
    SELECT MAX(analysis_date) 
    FROM `geo-pulse-463507.geo_pulse_data.booth_analysis`
  )
  GROUP BY constituency_id
),
voter_segments_stats AS (
  SELECT 
    constituency_id,
    SUM(total_voters) as segmented_voters,
    SUM(support_level.strong_favorable + support_level.leaning_favorable) as total_support,
    SUM(support_level.undecided) as total_undecided,
    SUM(support_level.opposition) as total_opposition
  FROM `geo-pulse-463507.geo_pulse_data.voter_segments`
  WHERE analysis_date = (
    SELECT MAX(analysis_date) 
    FROM `geo-pulse-463507.geo_pulse_data.voter_segments`
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
  
  -- Voter Estimates
  bs.total_voters,
  bs.total_estimated_favorable,
  bs.total_estimated_opposition,
  SAFE_DIVIDE(bs.total_estimated_favorable, bs.total_voters) * 100 as estimated_vote_share,
  SAFE_DIVIDE(
    bs.total_estimated_favorable - bs.total_estimated_opposition,
    bs.total_voters
  ) * 100 as estimated_margin_percentage,
  
  -- Organization Strength
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
  
  -- Voter Segmentation
  vss.segmented_voters,
  vss.total_support,
  vss.total_undecided,
  vss.total_opposition,
  SAFE_DIVIDE(vss.total_support, vss.segmented_voters) * 100 as support_percentage,
  SAFE_DIVIDE(vss.total_undecided, vss.segmented_voters) * 100 as undecided_percentage,
  
  -- Focus Areas
  CASE 
    WHEN bs.critical_booths > 0 THEN 'Address Critical Booths'
    WHEN SAFE_DIVIDE(bs.total_booth_agents, bs.total_booths) < 0.8 THEN 'Strengthen Agent Network'
    WHEN SAFE_DIVIDE(vss.total_undecided, vss.segmented_voters) > 0.15 THEN 'Target Undecided Voters'
    WHEN bs.avg_booth_score < 60 THEN 'Improve Overall Score'
    ELSE 'Maintain & Strengthen'
  END as primary_focus

FROM booth_stats bs
LEFT JOIN voter_segments_stats vss
  ON bs.constituency_id = vss.constituency_id
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
  ba.risk_factors,
  
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
  
  -- Vote Swing Potential
  CASE 
    WHEN ba.current_strength.undecided_voters >= ba.total_voters * 0.2 THEN 'High Swing Potential'
    WHEN ba.current_strength.undecided_voters >= ba.total_voters * 0.1 THEN 'Medium Swing Potential'
    ELSE 'Low Swing Potential'
  END as swing_potential,
  
  -- Organization Gaps
  CASE 
    WHEN ba.booth_agents = 0 THEN 'No Booth Agent'
    WHEN ba.active_volunteers < 5 THEN 'Low Volunteers'
    WHEN ba.booth_committee_strength IN ('weak', 'none') THEN 'Weak Committee'
    WHEN DATE_DIFF(CURRENT_DATE(), ba.last_meeting_date, DAY) > 30 THEN 'No Recent Meeting'
    ELSE 'Organization OK'
  END as organization_gap,
  
  -- Recommended Actions
  ba.priority_actions,
  ba.booth_agents,
  ba.active_volunteers,
  ba.booth_committee_strength,
  ba.total_voters,
  ba.current_strength.undecided_voters,
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
-- Purpose: Swing voter analysis and targeting strategy
-- Usage: Voter outreach and conversion planning
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_swing_analysis` AS
WITH booth_swing_data AS (
  SELECT 
    ba.booth_id,
    ba.constituency_id,
    ba.booth_name,
    ba.location_ward,
    ba.total_voters,
    ba.current_strength.undecided_voters,
    ba.current_strength.leaning_favorable,
    ba.current_strength.neutral_voters,
    ba.booth_score,
    SAFE_DIVIDE(ba.current_strength.undecided_voters, ba.total_voters) * 100 as undecided_percentage,
    SAFE_DIVIDE(ba.current_strength.neutral_voters, ba.total_voters) * 100 as neutral_percentage,
    ba.analysis_date
  FROM `geo-pulse-463507.geo_pulse_data.booth_analysis` ba
  WHERE ba.analysis_date = (
    SELECT MAX(analysis_date) 
    FROM `geo-pulse-463507.geo_pulse_data.booth_analysis`
  )
),
segment_swing_data AS (
  SELECT 
    vs.constituency_id,
    vs.segment_name,
    vs.total_voters as segment_size,
    vs.support_level.undecided as undecided_count,
    vs.swing_potential,
    vs.estimated_conversion_rate,
    vs.priority_level,
    vs.target_message,
    vs.recommended_actions,
    SAFE_DIVIDE(vs.support_level.undecided, vs.total_voters) * 100 as segment_undecided_pct
  FROM `geo-pulse-463507.geo_pulse_data.voter_segments` vs
  WHERE vs.analysis_date = (
    SELECT MAX(analysis_date) 
    FROM `geo-pulse-463507.geo_pulse_data.voter_segments`
  )
    AND vs.support_level.undecided > 0
)
SELECT 
  -- Booth Level Swing Analysis
  bsd.booth_id,
  bsd.constituency_id,
  bsd.booth_name,
  bsd.location_ward,
  bsd.total_voters,
  bsd.undecided_voters,
  bsd.leaning_favorable,
  bsd.neutral_voters,
  bsd.undecided_percentage,
  bsd.neutral_percentage,
  bsd.booth_score,
  
  -- Swing Potential Classification
  CASE 
    WHEN bsd.undecided_percentage >= 25 THEN 'Very High Swing Potential'
    WHEN bsd.undecided_percentage >= 15 THEN 'High Swing Potential'
    WHEN bsd.undecided_percentage >= 10 THEN 'Medium Swing Potential'
    WHEN bsd.undecided_percentage >= 5 THEN 'Low Swing Potential'
    ELSE 'Minimal Swing Potential'
  END as swing_classification,
  
  -- Target Value (voters that could be converted)
  bsd.undecided_voters + bsd.neutral_voters as targetable_voters,
  SAFE_DIVIDE(bsd.undecided_voters + bsd.neutral_voters, bsd.total_voters) * 100 as targetable_percentage,
  
  -- Impact Score (swing potential × booth size)
  ROUND(bsd.undecided_percentage * (bsd.total_voters / 100.0), 0) as impact_score,
  
  -- Conversion Priority
  CASE 
    WHEN bsd.booth_score < 40 AND bsd.undecided_percentage >= 15 THEN 'Critical - High Conversion Potential'
    WHEN bsd.booth_score >= 60 AND bsd.undecided_percentage >= 15 THEN 'Strengthen - High Conversion Potential'
    WHEN bsd.booth_score < 40 THEN 'Critical - Standard Conversion'
    WHEN bsd.undecided_percentage >= 20 THEN 'High - Focus on Swing'
    ELSE 'Standard - Regular Outreach'
  END as conversion_strategy,
  
  -- Recommended Approach
  CASE 
    WHEN bsd.undecided_percentage >= 20 THEN 'Intensive Door-to-Door + Public Meetings'
    WHEN bsd.undecided_percentage >= 10 THEN 'Targeted Outreach + Events'
    WHEN bsd.neutral_percentage >= 15 THEN 'Messaging Campaign + Personal Touch'
    ELSE 'Regular Engagement'
  END as recommended_approach,
  
  bsd.analysis_date

FROM booth_swing_data bsd
WHERE bsd.undecided_percentage >= 5  -- Only include booths with meaningful swing potential
ORDER BY 
  impact_score DESC,
  bsd.undecided_percentage DESC,
  bsd.total_voters DESC;

-- ============================================================================
-- End of Election War Room Views
-- ============================================================================
