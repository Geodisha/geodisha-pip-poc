-- ============================================================================
-- Module 5: PROMISES TRACKER VIEWS
-- Dataset: geo-pulse-463507.geo_pulse_data
-- Purpose: Promise tracking, delivery monitoring, and impact assessment
-- Created: 2024-12-03
-- ============================================================================

-- ----------------------------------------------------------------------------
-- View 5.1: v_promises_dashboard
-- Purpose: Comprehensive promise tracking dashboard
-- Usage: Main promises overview and progress monitoring
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_promises_dashboard` AS
SELECT 
  p.promise_id,
  p.constituency_id,
  p.promise_title,
  p.promise_description,
  p.promise_category,
  p.promise_type,
  p.announced_date,
  p.announced_by,
  p.target_beneficiaries,
  p.estimated_beneficiaries_count,
  p.scope,
  p.impact_level,
  
  -- Budget Information
  p.estimated_cost,
  p.budget_allocated,
  p.budget_utilized,
  SAFE_DIVIDE(p.budget_utilized, p.budget_allocated) * 100 as budget_utilization_pct,
  p.funding_source,
  
  -- Timeline
  p.target_completion_date,
  p.actual_start_date,
  p.actual_completion_date,
  p.duration_months,
  DATE_DIFF(p.target_completion_date, CURRENT_DATE(), DAY) as days_until_deadline,
  DATE_DIFF(CURRENT_DATE(), p.announced_date, DAY) as days_since_announced,
  
  -- Status & Progress
  p.status,
  p.completion_percentage,
  CASE 
    WHEN p.status = 'completed' THEN 'Completed'
    WHEN p.status = 'cancelled' THEN 'Cancelled'
    WHEN p.target_completion_date < CURRENT_DATE() AND p.status != 'completed' THEN 'Overdue'
    WHEN DATE_DIFF(p.target_completion_date, CURRENT_DATE(), DAY) <= 30 THEN 'Due Soon'
    WHEN p.status = 'delayed' THEN 'Delayed'
    WHEN p.status = 'in_progress' THEN 'On Track'
    ELSE 'Planned'
  END as timeline_status,
  
  -- Progress Health
  CASE 
    WHEN p.status = 'completed' THEN 'Completed'
    WHEN p.completion_percentage >= 75 THEN 'Good Progress'
    WHEN p.completion_percentage >= 50 THEN 'Fair Progress'
    WHEN p.completion_percentage >= 25 THEN 'Slow Progress'
    ELSE 'Minimal Progress'
  END as progress_health,
  
  -- Stakeholders
  p.implementing_agency,
  p.project_manager,
  p.contact_person,
  
  -- Public Perception
  p.public_awareness_level,
  p.satisfaction_score,
  p.feedback_count,
  p.media_coverage_count,
  p.visibility_score,
  p.last_public_update_date,
  DATE_DIFF(CURRENT_DATE(), p.last_public_update_date, DAY) as days_since_update,
  
  -- Challenges
  p.current_challenges,
  0 as challenge_count,
  p.risk_factors,
  
  -- Priority Score (for dashboard sorting)
  CASE 
    WHEN p.status = 'cancelled' THEN 0
    WHEN p.status = 'completed' THEN 1
    WHEN p.target_completion_date < CURRENT_DATE() THEN 100
    WHEN DATE_DIFF(p.target_completion_date, CURRENT_DATE(), DAY) <= 30 THEN 90
    WHEN p.status = 'delayed' THEN 80
    WHEN p.completion_percentage < 25 THEN 70
    ELSE 50
  END as attention_priority,
  
  p.created_at,
  p.updated_at

FROM `geo-pulse-463507.geo_pulse_data.promises` p
ORDER BY attention_priority DESC, p.announced_date DESC;

-- ----------------------------------------------------------------------------
-- View 5.2: v_promises_overdue
-- Purpose: Overdue and delayed promises requiring immediate attention
-- Usage: Escalation and intervention planning
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_promises_overdue` AS
WITH latest_updates AS (
  SELECT 
    promise_id,
    MAX(update_date) as last_update_date
  FROM `geo-pulse-463507.geo_pulse_data.promise_updates`
  GROUP BY promise_id
),
recent_update_info AS (
  SELECT 
    pu.promise_id,
    pu.update_date,
    pu.update_type,
    pu.update_description,
    pu.delays_reason,
    pu.revised_timeline,
    pu.new_challenges
  FROM `geo-pulse-463507.geo_pulse_data.promise_updates` pu
  INNER JOIN latest_updates lu
    ON pu.promise_id = lu.promise_id
    AND pu.update_date = lu.last_update_date
)
SELECT 
  p.promise_id,
  p.constituency_id,
  p.promise_title,
  p.promise_category,
  p.announced_date,
  p.announced_by,
  p.target_completion_date,
  p.status,
  p.completion_percentage,
  p.budget_allocated,
  p.budget_utilized,
  
  -- Delay Metrics
  DATE_DIFF(CURRENT_DATE(), p.target_completion_date, DAY) as days_overdue,
  CASE 
    WHEN DATE_DIFF(CURRENT_DATE(), p.target_completion_date, DAY) >= 180 THEN 'Severely Overdue'
    WHEN DATE_DIFF(CURRENT_DATE(), p.target_completion_date, DAY) >= 90 THEN 'Highly Overdue'
    WHEN DATE_DIFF(CURRENT_DATE(), p.target_completion_date, DAY) >= 30 THEN 'Moderately Overdue'
    ELSE 'Recently Overdue'
  END as delay_severity,
  
  -- Impact Assessment
  p.impact_level,
  p.estimated_beneficiaries_count,
  p.public_awareness_level,
  p.satisfaction_score,
  CASE 
    WHEN p.public_awareness_level = 'high' AND p.impact_level IN ('transformative', 'high') THEN 'High Visibility Risk'
    WHEN p.public_awareness_level = 'high' THEN 'Medium Visibility Risk'
    ELSE 'Low Visibility Risk'
  END as reputation_risk,
  
  -- Latest Update Info
  rui.update_date,
  DATE_DIFF(CURRENT_DATE(), rui.update_date, DAY) as days_since_last_update,
  rui.update_type as last_update_type,
  rui.delays_reason,
  rui.revised_timeline,
  rui.new_challenges,
  
  -- Challenges & Risks
  p.current_challenges,
  0 as active_challenges,
  p.risk_factors,
  
  -- Stakeholders
  p.implementing_agency,
  p.project_manager,
  p.contact_person,
  p.contact_phone,
  
  -- Urgency Score
  (DATE_DIFF(CURRENT_DATE(), p.target_completion_date, DAY) * 2) +
  (CASE p.public_awareness_level WHEN 'high' THEN 50 WHEN 'medium' THEN 25 ELSE 0 END) +
  (CASE p.impact_level WHEN 'transformative' THEN 30 WHEN 'high' THEN 20 ELSE 10 END) +
  (100 - p.completion_percentage) as urgency_score,
  
  p.updated_at

FROM `geo-pulse-463507.geo_pulse_data.promises` p
LEFT JOIN recent_update_info rui
  ON p.promise_id = rui.promise_id
WHERE p.status IN ('in_progress', 'delayed')
  AND p.target_completion_date < CURRENT_DATE()
ORDER BY urgency_score DESC, days_overdue DESC;

-- ----------------------------------------------------------------------------
-- View 5.3: v_promises_by_category
-- Purpose: Category-wise promise performance analysis
-- Usage: Sector-wise performance tracking and reporting
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_promises_by_category` AS
WITH category_stats AS (
  SELECT 
    constituency_id,
    promise_category,
    COUNT(*) as total_promises,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_count,
    SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress_count,
    SUM(CASE WHEN status = 'delayed' THEN 1 ELSE 0 END) as delayed_count,
    SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_count,
    SUM(CASE WHEN status = 'announced' THEN 1 ELSE 0 END) as announced_count,
    AVG(completion_percentage) as avg_completion_pct,
    SUM(estimated_beneficiaries_count) as total_beneficiaries,
    SUM(budget_allocated) as total_budget_allocated,
    SUM(budget_utilized) as total_budget_utilized,
    AVG(satisfaction_score) as avg_satisfaction_score,
    SUM(media_coverage_count) as total_media_coverage
  FROM `geo-pulse-463507.geo_pulse_data.promises`
  GROUP BY constituency_id, promise_category
),
category_impact AS (
  SELECT 
    pi.promise_id,
    p.constituency_id,
    p.promise_category,
    pi.delivery_score,
    pi.political_impact_score,
    pi.social_impact_score
  FROM `geo-pulse-463507.geo_pulse_data.promise_impact` pi
  JOIN `geo-pulse-463507.geo_pulse_data.promises` p
    ON pi.promise_id = p.promise_id
  WHERE pi.assessment_date = (
    SELECT MAX(assessment_date)
    FROM `geo-pulse-463507.geo_pulse_data.promise_impact`
    WHERE promise_id = pi.promise_id
  )
)
SELECT 
  cs.constituency_id,
  cs.promise_category,
  cs.total_promises,
  cs.completed_count,
  cs.in_progress_count,
  cs.delayed_count,
  cs.cancelled_count,
  cs.announced_count,
  
  -- Completion Metrics
  SAFE_DIVIDE(cs.completed_count, cs.total_promises) * 100 as completion_rate,
  SAFE_DIVIDE(cs.delayed_count, cs.total_promises) * 100 as delay_rate,
  ROUND(cs.avg_completion_pct, 1) as avg_completion_percentage,
  
  -- Beneficiary Impact
  cs.total_beneficiaries,
  SAFE_DIVIDE(cs.total_beneficiaries, cs.total_promises) as avg_beneficiaries_per_promise,
  
  -- Budget Performance
  cs.total_budget_allocated,
  cs.total_budget_utilized,
  SAFE_DIVIDE(cs.total_budget_utilized, cs.total_budget_allocated) * 100 as budget_utilization_rate,
  
  -- Public Perception
  ROUND(cs.avg_satisfaction_score, 1) as avg_satisfaction_score,
  cs.total_media_coverage,
  SAFE_DIVIDE(cs.total_media_coverage, cs.total_promises) as media_coverage_per_promise,
  
  -- Performance Category
  CASE 
    WHEN SAFE_DIVIDE(cs.completed_count, cs.total_promises) >= 0.7 THEN 'Excellent'
    WHEN SAFE_DIVIDE(cs.completed_count, cs.total_promises) >= 0.5 THEN 'Good'
    WHEN SAFE_DIVIDE(cs.completed_count, cs.total_promises) >= 0.3 THEN 'Fair'
    ELSE 'Needs Improvement'
  END as performance_category,
  
  -- Impact Scores (from completed promises)
  AVG(ci.delivery_score) as avg_delivery_score,
  AVG(ci.political_impact_score) as avg_political_impact,
  AVG(ci.social_impact_score) as avg_social_impact

FROM category_stats cs
LEFT JOIN category_impact ci
  ON cs.constituency_id = ci.constituency_id
  AND cs.promise_category = ci.promise_category
GROUP BY 
  cs.constituency_id,
  cs.promise_category,
  cs.total_promises,
  cs.completed_count,
  cs.in_progress_count,
  cs.delayed_count,
  cs.cancelled_count,
  cs.announced_count,
  cs.avg_completion_pct,
  cs.total_beneficiaries,
  cs.total_budget_allocated,
  cs.total_budget_utilized,
  cs.avg_satisfaction_score,
  cs.total_media_coverage
ORDER BY 
  cs.constituency_id,
  completion_rate DESC,
  cs.total_promises DESC;

-- ----------------------------------------------------------------------------
-- View 5.4: v_promise_completion_rate
-- Purpose: Time-series promise completion metrics
-- Usage: Trend analysis and performance reporting
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `geo-pulse-463507.geo_pulse_data.v_promise_completion_rate` AS
WITH monthly_completions AS (
  SELECT 
    constituency_id,
    DATE_TRUNC(actual_completion_date, MONTH) as completion_month,
    COUNT(*) as promises_completed,
    SUM(estimated_beneficiaries_count) as beneficiaries_reached,
    AVG(DATE_DIFF(actual_completion_date, announced_date, DAY)) as avg_days_to_complete
  FROM `geo-pulse-463507.geo_pulse_data.promises`
  WHERE status = 'completed'
    AND actual_completion_date IS NOT NULL
  GROUP BY constituency_id, completion_month
),
monthly_announcements AS (
  SELECT 
    constituency_id,
    DATE_TRUNC(announced_date, MONTH) as announcement_month,
    COUNT(*) as promises_announced
  FROM `geo-pulse-463507.geo_pulse_data.promises`
  GROUP BY constituency_id, announcement_month
),
cumulative_metrics AS (
  SELECT 
    constituency_id,
    COUNT(*) as total_promises_to_date,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as total_completed,
    SUM(CASE WHEN status IN ('in_progress', 'delayed') THEN 1 ELSE 0 END) as total_active,
    AVG(completion_percentage) as avg_progress
  FROM `geo-pulse-463507.geo_pulse_data.promises`
  GROUP BY constituency_id
)
SELECT 
  COALESCE(mc.constituency_id, ma.constituency_id) as constituency_id,
  COALESCE(mc.completion_month, ma.announcement_month) as report_month,
  
  -- Monthly Metrics
  COALESCE(ma.promises_announced, 0) as promises_announced_this_month,
  COALESCE(mc.promises_completed, 0) as promises_completed_this_month,
  mc.beneficiaries_reached,
  ROUND(mc.avg_days_to_complete, 0) as avg_days_to_complete,
  
  -- Cumulative Metrics
  cm.total_promises_to_date,
  cm.total_completed,
  cm.total_active,
  SAFE_DIVIDE(cm.total_completed, cm.total_promises_to_date) * 100 as overall_completion_rate,
  ROUND(cm.avg_progress, 1) as avg_progress_percentage,
  
  -- Performance Indicators
  CASE 
    WHEN mc.promises_completed >= 5 THEN 'High Delivery'
    WHEN mc.promises_completed >= 2 THEN 'Moderate Delivery'
    WHEN mc.promises_completed >= 1 THEN 'Low Delivery'
    ELSE 'No Completions'
  END as monthly_delivery_pace,
  
  -- Velocity (promises per month)
  SAFE_DIVIDE(mc.promises_completed, 
    DATE_DIFF(CURRENT_DATE(), DATE_TRUNC(mc.completion_month, MONTH), DAY) / 30.0
  ) as delivery_velocity,
  
  -- Comparison with previous month
  LAG(mc.promises_completed) OVER (
    PARTITION BY mc.constituency_id 
    ORDER BY mc.completion_month
  ) as prev_month_completions,
  
  mc.promises_completed - LAG(mc.promises_completed) OVER (
    PARTITION BY mc.constituency_id 
    ORDER BY mc.completion_month
  ) as month_over_month_change

FROM monthly_completions mc
FULL OUTER JOIN monthly_announcements ma
  ON mc.constituency_id = ma.constituency_id
  AND mc.completion_month = ma.announcement_month
LEFT JOIN cumulative_metrics cm
  ON COALESCE(mc.constituency_id, ma.constituency_id) = cm.constituency_id
WHERE COALESCE(mc.completion_month, ma.announcement_month) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
ORDER BY 
  constituency_id,
  report_month DESC;

-- ============================================================================
-- End of Promises Tracker Views
-- ============================================================================
