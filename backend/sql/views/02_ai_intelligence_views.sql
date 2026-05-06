-- ============================================================================
-- Module 2: AI INTELLIGENCE HUB VIEWS
-- Dataset: geo-pulse-463507.geo_pulse_data
-- Purpose: AI recommendations, media intelligence, and strategic insights
-- Created: 2024-12-03
-- ============================================================================

-- ----------------------------------------------------------------------------
-- View 2.1: v_ai_recommendations_active
-- Purpose: Active AI recommendations with prioritization
-- Usage: AI recommendations dashboard and action items
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_ai_recommendations_active` AS
SELECT 
  r.recommendation_id,
  r.constituency_id,
  r.recommendation_type,
  r.title,
  r.description,
  r.priority,
  r.confidence_score,
  r.impact_score,
  r.effort_level,
  r.target_audience,
  r.estimated_cost,
  r.estimated_timeline_days,
  r.status,
  r.assigned_to,
  r.ai_reasoning,
  r.expected_outcomes,
  r.risks,
  r.created_at,
  r.updated_at,
  
  -- Priority Score (weighted)
  CASE r.priority
    WHEN 'critical' THEN 100
    WHEN 'high' THEN 75
    WHEN 'medium' THEN 50
    ELSE 25
  END as priority_score,
  
  -- Days since creation
  DATE_DIFF(CURRENT_DATE(), DATE(r.created_at), DAY) as days_open,
  
  -- Urgency indicator
  CASE 
    WHEN r.priority = 'critical' AND DATE_DIFF(CURRENT_DATE(), DATE(r.created_at), DAY) > 3 THEN 'Overdue'
    WHEN r.priority = 'high' AND DATE_DIFF(CURRENT_DATE(), DATE(r.created_at), DAY) > 7 THEN 'Overdue'
    WHEN r.priority = 'medium' AND DATE_DIFF(CURRENT_DATE(), DATE(r.created_at), DAY) > 14 THEN 'Overdue'
    ELSE 'On Time'
  END as urgency_status,
  
  -- ROI Estimate
  SAFE_DIVIDE(r.impact_score, 
    CASE r.effort_level
      WHEN 'high' THEN 3
      WHEN 'medium' THEN 2
      ELSE 1
    END
  ) as roi_estimate

FROM `geo-pulse-463507.geo_pulse_data.ai_recommendations` r
WHERE r.status IN ('pending', 'accepted', 'in_progress')
ORDER BY priority_score DESC, r.confidence_score DESC, r.created_at ASC;

-- ----------------------------------------------------------------------------
-- View 2.2: v_media_briefing_latest
-- Purpose: Current media talking points and messaging strategy
-- Usage: Media briefing preparation and communication planning
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_media_briefing_latest` AS
SELECT 
  tp.talking_point_id,
  tp.constituency_id,
  tp.topic,
  tp.headline,
  tp.key_message,
  tp.supporting_facts,
  tp.statistics,
  tp.target_media,
  tp.tone,
  tp.urgency,
  tp.related_events,
  tp.dos,
  tp.donts,
  tp.sample_quotes,
  tp.counter_narratives,
  tp.generated_by,
  tp.ai_confidence,
  tp.reviewed_by,
  tp.approved_status,
  tp.created_at,
  tp.updated_at,
  tp.used_at,
  tp.effectiveness_rating,
  
  -- Time relevance
  CASE 
    WHEN tp.urgency = 'immediate' THEN 1
    WHEN tp.urgency = 'this_week' THEN 7
    WHEN tp.urgency = 'this_month' THEN 30
    ELSE 90
  END as relevance_days,
  
  -- Usage status
  CASE 
    WHEN tp.used_at IS NULL THEN 'Unused'
    WHEN DATE_DIFF(CURRENT_DATE(), DATE(tp.used_at), DAY) <= 7 THEN 'Recently Used'
    ELSE 'Previously Used'
  END as usage_status,
  
  -- Approval status
  CASE 
    WHEN tp.approved_status = 'approved' THEN 'Ready'
    WHEN tp.approved_status = 'published' THEN 'Published'
    WHEN tp.approved_status = 'draft' THEN 'Needs Review'
    ELSE 'Archived'
  END as readiness_status

FROM `geo-pulse-463507.geo_pulse_data.media_talking_points` tp
WHERE tp.approved_status IN ('draft', 'approved', 'published')
  AND tp.created_at >= DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
ORDER BY 
  CASE tp.urgency
    WHEN 'immediate' THEN 1
    WHEN 'this_week' THEN 2
    WHEN 'this_month' THEN 3
    ELSE 4
  END,
  tp.created_at DESC;

-- ----------------------------------------------------------------------------
-- View 2.3: v_influencer_map
-- Purpose: Strategic influencer mapping and relationship management
-- Usage: Stakeholder engagement and outreach planning
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_influencer_map` AS
SELECT 
  im.influencer_id,
  im.constituency_id,
  im.name,
  im.category,
  im.sub_category,
  im.influence_level,
  im.influence_score,
  im.reach_estimate,
  im.location_ward,
  im.location_mandal,
  im.contact_phone,
  im.contact_email,
  im.political_leaning,
  im.engagement_history,
  im.key_issues,
  im.relationship_strength,
  im.last_interaction_date,
  im.next_followup_date,
  im.notes,
  im.verified,
  im.created_at,
  im.updated_at,
  
  -- Engagement priority
  CASE 
    WHEN im.influence_level = 'high' AND im.relationship_strength IN ('weak', 'none') THEN 'High Priority'
    WHEN im.influence_level = 'high' AND im.political_leaning IN ('neutral', 'unknown') THEN 'Medium Priority'
    WHEN im.influence_level = 'medium' AND im.relationship_strength = 'none' THEN 'Medium Priority'
    ELSE 'Low Priority'
  END as engagement_priority,
  
  -- Follow-up status
  CASE 
    WHEN im.next_followup_date IS NULL THEN 'No Follow-up Scheduled'
    WHEN im.next_followup_date < CURRENT_DATE() THEN 'Overdue'
    WHEN im.next_followup_date = CURRENT_DATE() THEN 'Today'
    WHEN im.next_followup_date <= DATE_ADD(CURRENT_DATE(), INTERVAL 7 DAY) THEN 'This Week'
    ELSE 'Future'
  END as followup_status,
  
  -- Days since last interaction
  DATE_DIFF(CURRENT_DATE(), im.last_interaction_date, DAY) as days_since_interaction,
  
  -- Risk indicator
  CASE 
    WHEN im.political_leaning = 'opposition' AND im.influence_level = 'high' THEN 'High Risk'
    WHEN im.political_leaning = 'neutral' AND im.influence_level = 'high' THEN 'Medium Risk'
    WHEN im.political_leaning = 'favorable' THEN 'Low Risk'
    ELSE 'Unknown Risk'
  END as risk_indicator

FROM `geo-pulse-463507.geo_pulse_data.influencer_mapping` im
WHERE im.verified = TRUE
ORDER BY 
  CASE im.influence_level
    WHEN 'high' THEN 1
    WHEN 'medium' THEN 2
    ELSE 3
  END,
  im.influence_score DESC;

-- ----------------------------------------------------------------------------
-- View 2.4: v_visit_priority_list
-- Purpose: Prioritized visit planning recommendations
-- Usage: Visit scheduling and route optimization
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_visit_priority_list` AS
SELECT 
  vp.plan_id,
  vp.constituency_id,
  vp.plan_name,
  vp.plan_date,
  vp.plan_type,
  vp.status,
  vp.priority,
  vp.locations,
  vp.route_optimization,
  vp.objectives,
  vp.target_demographics,
  vp.key_messages,
  vp.resource_requirements,
  vp.risk_assessment,
  vp.ai_suggestions,
  vp.created_by,
  vp.approved_by,
  vp.created_at,
  vp.updated_at,
  
  -- Priority score
  CASE vp.priority
    WHEN 'critical' THEN 100
    WHEN 'high' THEN 75
    WHEN 'medium' THEN 50
    ELSE 25
  END as priority_score,
  
  -- Urgency based on plan date
  CASE 
    WHEN vp.plan_date < CURRENT_DATE() AND vp.status != 'completed' THEN 'Overdue'
    WHEN vp.plan_date = CURRENT_DATE() THEN 'Today'
    WHEN vp.plan_date <= DATE_ADD(CURRENT_DATE(), INTERVAL 3 DAY) THEN 'This Week'
    WHEN vp.plan_date <= DATE_ADD(CURRENT_DATE(), INTERVAL 14 DAY) THEN 'Next 2 Weeks'
    ELSE 'Future'
  END as urgency_category,
  
  -- Days until visit
  DATE_DIFF(vp.plan_date, CURRENT_DATE(), DAY) as days_until_visit,
  
  -- Readiness score
  CASE 
    WHEN vp.approved_by IS NOT NULL AND vp.status = 'scheduled' THEN 100
    WHEN vp.approved_by IS NOT NULL AND vp.status = 'draft' THEN 75
    WHEN vp.approved_by IS NULL AND vp.status = 'scheduled' THEN 50
    ELSE 25
  END as readiness_score,
  
  -- Route efficiency (parse JSON from STRING)
  SAFE_CAST(JSON_EXTRACT_SCALAR(vp.route_optimization, '$.total_distance_km') AS FLOAT64) as total_distance,
  SAFE_CAST(JSON_EXTRACT_SCALAR(vp.route_optimization, '$.estimated_travel_time_mins') AS INT64) as travel_time_mins,
  SAFE_CAST(JSON_EXTRACT_SCALAR(vp.route_optimization, '$.fuel_cost_estimate') AS FLOAT64) as estimated_fuel_cost,
  
  -- Resource needs (parse JSON from STRING)
  SAFE_CAST(JSON_EXTRACT_SCALAR(vp.resource_requirements, '$.vehicles') AS INT64) as vehicles_needed,
  SAFE_CAST(JSON_EXTRACT_SCALAR(vp.resource_requirements, '$.security_personnel') AS INT64) as security_needed,
  SAFE_CAST(JSON_EXTRACT_SCALAR(vp.resource_requirements, '$.volunteers') AS INT64) as volunteers_needed,
  SAFE_CAST(JSON_EXTRACT_SCALAR(vp.resource_requirements, '$.budget') AS FLOAT64) as budget_required

FROM `geo-pulse-463507.geo_pulse_data.visit_planning` vp
WHERE vp.status IN ('draft', 'scheduled', 'in_progress')
  AND vp.plan_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
ORDER BY 
  priority_score DESC,
  days_until_visit ASC,
  readiness_score DESC;

-- ============================================================================
-- End of AI Intelligence Hub Views
-- ============================================================================
