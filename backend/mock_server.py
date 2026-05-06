"""
GeoDisha Mock API Server
Serves all endpoints using local CSV seed data — no BigQuery, no DB required.
Run: python mock_server.py
"""

import os
import json
import math
import csv
from pathlib import Path
from typing import Optional, List, Any, Dict
from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
import uvicorn
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

# ── Seed data path ──────────────────────────────────────────────────────────
SEED_DIR = Path(__file__).parent / "sql" / "seed"

# ── Load all CSVs into memory at startup ────────────────────────────────────
def load_csv(filename: str) -> List[Dict]:
    path = SEED_DIR / filename
    if not path.exists():
        logger.warning(f"Seed file not found: {path}")
        return []
    rows = []
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(dict(row))
    logger.info(f"Loaded {len(rows):,} rows from {filename}")
    return rows

def parse_json_field(val: str) -> Any:
    if not val:
        return []
    try:
        return json.loads(val)
    except Exception:
        return val

def try_coerce(v: str):
    """Try to coerce a string value to int or float."""
    if not isinstance(v, str) or v in ("", "None", "null", "NaN"):
        return None if v in ("", "None", "null", "NaN") else v
    try:
        iv = int(v)
        return iv
    except ValueError:
        pass
    try:
        fv = float(v)
        return fv
    except ValueError:
        pass
    return v

# Fields that should stay as strings even if they look numeric
STRING_KEYS = {
    "constituency_id", "booth_id", "alert_id", "promise_id", "visit_id",
    "influencer_id", "event_id", "grievance_id", "user_id",
    "contact_phone", "phone", "email", "contact_email",
    "location_coordinates", "reported_by", "added_by", "surveyed_by",
    "verification_date", "last_visit_date", "incident_time",
    "last_interaction_date", "next_followup_date", "last_meeting_date",
    "analysis_date", "announced_date", "created_at", "updated_at", "last_updated",
}

def clean_row(row: Dict) -> Dict:
    """Parse known JSON fields, coerce numerics, remove empty strings."""
    JSON_KEYS = {
        "key_achievements", "critical_issues", "top_opportunities",
        "immediate_actions", "risk_alerts", "locations", "route_optimization",
        "objectives", "target_demographics", "key_messages",
        "resource_requirements", "risk_assessment", "ai_suggestions",
        "supporting_facts", "statistics", "target_media", "related_events",
        "dos", "donts", "sample_quotes", "counter_narratives",
        "engagement_history", "key_issues", "actions_taken",
        "ai_recommended_actions", "related_alerts", "related_promises",
        "related_visits", "photos", "videos", "documents",
        "milestones", "specific_locations", "current_challenges",
        "risk_factors", "mitigation_measures", "document_urls",
        "photo_urls", "data_sources", "expected_outcomes", "risks",
    }
    cleaned = {}
    for k, v in row.items():
        if k in JSON_KEYS:
            cleaned[k] = parse_json_field(v)
        elif k in STRING_KEYS:
            cleaned[k] = v if v != "" else None
        elif v == "":
            cleaned[k] = None
        else:
            cleaned[k] = try_coerce(v)
    return cleaned

logger.info("Loading seed data …")
# Guard so data loads only once (not twice when uvicorn spawns workers)
_DATA_LOADED = False
DATA = {
    "overview":        [clean_row(r) for r in load_csv("01_constituency_overview.csv")],
    "kpis":            [clean_row(r) for r in load_csv("02_constituency_kpis.csv")],
    "trends":          [clean_row(r) for r in load_csv("03_constituency_trends.csv")],
    "exec_summary":    [clean_row(r) for r in load_csv("04_executive_summary.csv")],
    "ai_recs":         [clean_row(r) for r in load_csv("05_ai_recommendations.csv")],
    "media":           [clean_row(r) for r in load_csv("06_media_talking_points.csv")],
    "influencers":     [clean_row(r) for r in load_csv("07_influencer_mapping.csv")],
    "visit_plans":     [clean_row(r) for r in load_csv("08_visit_planning.csv")],
    "visits":          [clean_row(r) for r in load_csv("09_visit_records_enhanced.csv")],
    "heatmap":         [clean_row(r) for r in load_csv("10_issue_heatmap.csv")],
    "ward_intel":      [clean_row(r) for r in load_csv("11_ward_intelligence.csv")],
    "visit_stats":     [clean_row(r) for r in load_csv("12_visit_statistics.csv")],
    "booth_analysis":  [clean_row(r) for r in load_csv("13_booth_analysis.csv")],
    "booth_trends":    [clean_row(r) for r in load_csv("14_booth_score_trends.csv")],
    "voter_segments":  [clean_row(r) for r in load_csv("15_voter_segments.csv")],
    "opposition":      [clean_row(r) for r in load_csv("16_opposition_intelligence.csv")],
    "promises":        [clean_row(r) for r in load_csv("17_promises.csv")],
    "promise_updates": [clean_row(r) for r in load_csv("18_promise_updates.csv")],
    "promise_miles":   [clean_row(r) for r in load_csv("19_promise_milestones.csv")],
    "promise_bene":    [clean_row(r) for r in load_csv("20_promise_beneficiaries.csv")],
    "alerts":          [clean_row(r) for r in load_csv("21_alerts.csv")],
    "crisis":          [clean_row(r) for r in load_csv("22_crisis_events.csv")],
    "escalations":     [clean_row(r) for r in load_csv("23_issue_escalations.csv")],
    "metrics":         [clean_row(r) for r in load_csv("24_monitoring_metrics.csv")],
}
logger.info("✅ All seed data loaded!")

# ── Helpers ─────────────────────────────────────────────────────────────────
def ok(data, **meta):
    return {"success": True, "data": data, "metadata": {"total_records": len(data) if isinstance(data, list) else 1, **meta}}

def filter_constituency(rows, cid):
    if not cid:
        return rows
    return [r for r in rows if r.get("constituency_id") == cid]

def paginate(rows, limit, offset):
    return rows[offset: offset + limit]

def safe_float(v, default=0.0):
    try:
        return float(v) if v not in (None, "", "None") else default
    except Exception:
        return default

def safe_int(v, default=0):
    try:
        return int(float(v)) if v not in (None, "", "None") else default
    except Exception:
        return default

# ── App ──────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="GeoDisha Mock API",
    description="Seed-data powered API — no BigQuery needed",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
)

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
app.add_middleware(GZipMiddleware, minimum_size=500)


# ═══════════════════════════════════════════════════════════════════
# HEALTH
# ═══════════════════════════════════════════════════════════════════
@app.get("/health")
def health():
    return {"status": "healthy", "service": "geodisha-mock-api", "version": "1.0.0", "data_source": "seed_csv"}

@app.get("/")
def root():
    return {"message": "GeoDisha Mock API", "docs": "/api/docs", "total_seed_rows": sum(len(v) for v in DATA.values())}


# ═══════════════════════════════════════════════════════════════════
# AUTH  (mock — always succeeds)
# ═══════════════════════════════════════════════════════════════════
@app.post("/api/v1/auth/login")
def login(payload: dict = None):
    return {
        "success": True,
        "data": {
            "access_token": "mock_token_geodisha_2026",
            "token_type": "bearer",
            "user": {
                "id": "user_001", "name": "Demo Admin", "email": "admin@geodisha.in",
                "role": "admin", "constituency_id": "PC01",
                "constituency_name": "Adilabad"
            }
        }
    }

@app.post("/api/v1/auth/register")
def register(payload: dict = None):
    return {"success": True, "data": {"message": "Registration successful (mock)"}}

@app.post("/api/v1/auth/refresh")
def refresh_token():
    return {"success": True, "data": {"access_token": "mock_token_geodisha_refreshed_2026"}}


# ═══════════════════════════════════════════════════════════════════
# CONSTITUENCIES
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/constituencies")
def get_constituencies(user_role: str = Query(default="admin")):
    rows = DATA["overview"]
    result = [
        {
            "id": r["constituency_id"],
            "constituency_id": r["constituency_id"],
            "name": r.get("constituency_name", r["constituency_id"]),
            "constituency_name": r.get("constituency_name", r["constituency_id"]),
            "health_score": safe_float(r.get("health_score")),
            "risk_level": r.get("risk_level", "medium"),
            "total_voters": safe_int(r.get("total_voters")),
            "total_population": safe_int(r.get("total_population")),
            "active_issues": safe_int(r.get("active_issues")),
            "critical_alerts": safe_int(r.get("critical_alerts")),
            "satisfaction_score": safe_float(r.get("satisfaction_score")),
            "last_visit_date": r.get("last_visit_date"),
        }
        for r in rows
    ]
    return ok(result, role=user_role)

@app.get("/api/v1/constituencies/{constituency_id}")
def get_constituency(constituency_id: str):
    rows = filter_constituency(DATA["overview"], constituency_id)
    if not rows:
        return {"success": False, "error": "Constituency not found"}
    r = rows[0]
    return ok(clean_row(r))

@app.get("/api/v1/constituencies/{constituency_id}/stats")
def get_constituency_stats(constituency_id: str):
    rows = filter_constituency(DATA["kpis"], constituency_id)
    return ok(rows[:30])


# ═══════════════════════════════════════════════════════════════════
# MODULE 1: COMMAND CENTER
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/command-center/overview")
def command_overview(
    constituency_id: Optional[str] = None,
    user_role: str = Query(default="admin")
):
    rows = filter_constituency(DATA["overview"], constituency_id)
    return ok(rows, role=user_role)

@app.get("/api/v1/command-center/kpi-trends")
def kpi_trends(
    constituency_id: Optional[str] = None,
    days: int = Query(default=30),
    limit: int = Query(default=60),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["kpis"], constituency_id)
    return ok(paginate(rows, limit, offset), days=days)

@app.get("/api/v1/command-center/executive-summary")
def executive_summary(
    constituency_id: Optional[str] = None,
    period: str = Query(default="monthly"),
    limit: int = Query(default=12)
):
    rows = filter_constituency(DATA["exec_summary"], constituency_id)
    rows = [r for r in rows if r.get("report_period") == period]
    return ok(rows[:limit])

@app.get("/api/v1/command-center/trends-summary")
def trends_summary(
    constituency_id: Optional[str] = None,
    months: int = Query(default=6),
    limit: int = Query(default=60)
):
    rows = filter_constituency(DATA["trends"], constituency_id)
    return ok(rows[:limit])


# ═══════════════════════════════════════════════════════════════════
# MODULE 2: AI INTELLIGENCE HUB
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/ai-intelligence/recommendations")
def ai_recommendations(
    constituency_id: Optional[str] = None,
    priority: Optional[str] = None,
    status: Optional[str] = None,
    limit: int = Query(default=20),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["ai_recs"], constituency_id)
    if priority:
        rows = [r for r in rows if r.get("priority") == priority]
    if status:
        rows = [r for r in rows if r.get("status") == status]
    return ok(paginate(rows, limit, offset))

@app.get("/api/v1/ai-intelligence/media-briefing")
def media_briefing(
    constituency_id: Optional[str] = None,
    topic: Optional[str] = None,
    limit: int = Query(default=20),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["media"], constituency_id)
    if topic:
        rows = [r for r in rows if r.get("topic") == topic]
    return ok(paginate(rows, limit, offset))

@app.get("/api/v1/ai-intelligence/influencer-map")
def influencer_map(
    constituency_id: Optional[str] = None,
    category: Optional[str] = None,
    influence_level: Optional[str] = None,
    limit: int = Query(default=30),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["influencers"], constituency_id)
    if category:
        rows = [r for r in rows if r.get("category") == category]
    if influence_level:
        rows = [r for r in rows if r.get("influence_level") == influence_level]
    return ok(paginate(rows, limit, offset))

@app.get("/api/v1/ai-intelligence/visit-priority-list")
def visit_priority_list(
    constituency_id: Optional[str] = None,
    limit: int = Query(default=20),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["visit_plans"], constituency_id)
    # Sort by priority
    priority_order = {"high": 0, "medium": 1, "low": 2}
    rows = sorted(rows, key=lambda r: priority_order.get(r.get("priority", "low"), 2))
    return ok(paginate(rows, limit, offset))


# ═══════════════════════════════════════════════════════════════════
# MODULE 3: GROUND REALITY
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/ground-reality/visits")
def ground_visits(
    constituency_id: Optional[str] = None,
    visit_type: Optional[str] = None,
    limit: int = Query(default=30),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["visits"], constituency_id)
    if visit_type:
        rows = [r for r in rows if r.get("visit_type") == visit_type]
    return ok(paginate(rows, limit, offset))

@app.get("/api/v1/ground-reality/heatmap")
def heatmap_current(
    constituency_id: Optional[str] = None,
    limit: int = Query(default=50),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["heatmap"], constituency_id)
    # Latest date per ward
    latest: Dict[str, dict] = {}
    for r in rows:
        key = f"{r.get('constituency_id')}_{r.get('location_ward')}"
        if key not in latest or r.get("data_date", "") > latest[key].get("data_date", ""):
            latest[key] = r
    result = list(latest.values())
    result = sorted(result, key=lambda r: safe_float(r.get("intensity_score")), reverse=True)
    return ok(paginate(result, limit, offset))

@app.get("/api/v1/ground-reality/ward-coverage")
def ward_coverage(
    constituency_id: Optional[str] = None,
    limit: int = Query(default=50),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["ward_intel"], constituency_id)
    latest: Dict[str, dict] = {}
    for r in rows:
        key = f"{r.get('constituency_id')}_{r.get('ward_name')}"
        if key not in latest or r.get("report_date", "") > latest[key].get("report_date", ""):
            latest[key] = r
    result = list(latest.values())
    return ok(paginate(result, limit, offset))

@app.get("/api/v1/ground-reality/visit-trends")
def visit_trends(
    constituency_id: Optional[str] = None,
    days: int = Query(default=30),
    limit: int = Query(default=60)
):
    rows = filter_constituency(DATA["visit_stats"], constituency_id)
    return ok(rows[:limit], days=days)


# ═══════════════════════════════════════════════════════════════════
# MODULE 4: ELECTION WAR ROOM
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/election-war-room/booth-scores")
def booth_scores(
    constituency_id: Optional[str] = None,
    risk_level: Optional[str] = None,
    limit: int = Query(default=50),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["booth_analysis"], constituency_id)
    if risk_level:
        rows = [r for r in rows if r.get("risk_level") == risk_level]
    rows = sorted(rows, key=lambda r: safe_float(r.get("booth_score")))
    return ok(paginate(rows, limit, offset))

@app.get("/api/v1/election-war-room/readiness")
def election_readiness(constituency_id: Optional[str] = None):
    overview = filter_constituency(DATA["overview"], constituency_id)
    booths = filter_constituency(DATA["booth_analysis"], constituency_id)
    segments = filter_constituency(DATA["voter_segments"], constituency_id)
    total_booths = len(booths)
    secure = len([b for b in booths if b.get("risk_level") == "secure"])
    vulnerable = len([b for b in booths if b.get("risk_level") == "vulnerable"])
    critical = len([b for b in booths if b.get("risk_level") == "critical"])
    avg_score = sum(safe_float(b.get("booth_score")) for b in booths) / max(total_booths, 1)
    result = {
        "total_booths": total_booths,
        "secure_booths": secure,
        "vulnerable_booths": vulnerable,
        "critical_booths": critical,
        "average_booth_score": round(avg_score, 1),
        "readiness_percentage": round((secure / max(total_booths, 1)) * 100, 1),
        "constituencies": overview[:5],
        "voter_segments_summary": segments[:10],
    }
    return ok(result)

@app.get("/api/v1/election-war-room/risk-matrix")
def booth_risk_matrix(
    constituency_id: Optional[str] = None,
    limit: int = Query(default=50),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["booth_analysis"], constituency_id)
    risk_order = {"critical": 0, "vulnerable": 1, "secure": 2}
    rows = sorted(rows, key=lambda r: risk_order.get(r.get("risk_level", "secure"), 2))
    return ok(paginate(rows, limit, offset))

@app.get("/api/v1/election-war-room/swing-analysis")
def swing_analysis(
    constituency_id: Optional[str] = None,
    limit: int = Query(default=30),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["opposition"], constituency_id)
    return ok(paginate(rows, limit, offset))


# ═══════════════════════════════════════════════════════════════════
# MODULE 5: PROMISES
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/promises/dashboard")
def promises_dashboard(
    constituency_id: Optional[str] = None,
    limit: int = Query(default=30),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["promises"], constituency_id)
    return ok(paginate(rows, limit, offset))

@app.get("/api/v1/promises/overdue")
def promises_overdue(
    constituency_id: Optional[str] = None,
    limit: int = Query(default=20),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["promises"], constituency_id)
    overdue = [r for r in rows if r.get("status") in ("delayed", "overdue", "announced") and
               safe_float(r.get("completion_percentage", 0)) < 50]
    return ok(paginate(overdue, limit, offset))

@app.get("/api/v1/promises/by-category")
def promises_by_category(constituency_id: Optional[str] = None):
    rows = filter_constituency(DATA["promises"], constituency_id)
    cats: Dict[str, list] = {}
    for r in rows:
        cat = r.get("promise_category", "other")
        cats.setdefault(cat, []).append(r)
    result = [
        {
            "category": cat,
            "total": len(items),
            "completed": len([i for i in items if i.get("status") == "completed"]),
            "in_progress": len([i for i in items if i.get("status") == "in_progress"]),
            "delayed": len([i for i in items if i.get("status") in ("delayed", "announced")]),
            "avg_completion": round(sum(safe_float(i.get("completion_percentage")) for i in items) / max(len(items), 1), 1),
        }
        for cat, items in cats.items()
    ]
    return ok(result)

@app.get("/api/v1/promises/completion-rate")
def promise_completion_rate(constituency_id: Optional[str] = None):
    rows = filter_constituency(DATA["promises"], constituency_id)
    total = len(rows)
    completed = len([r for r in rows if r.get("status") == "completed"])
    in_progress = len([r for r in rows if r.get("status") == "in_progress"])
    delayed = len([r for r in rows if r.get("status") in ("delayed", "announced")])
    avg_pct = sum(safe_float(r.get("completion_percentage")) for r in rows) / max(total, 1)
    return ok({
        "total_promises": total,
        "completed": completed,
        "in_progress": in_progress,
        "delayed": delayed,
        "completion_rate": round((completed / max(total, 1)) * 100, 1),
        "average_completion_percentage": round(avg_pct, 1),
    })


# ═══════════════════════════════════════════════════════════════════
# MODULE 6: ALERTS & CRISIS
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/alerts/active")
def alerts_active(
    constituency_id: Optional[str] = None,
    severity: Optional[str] = None,
    limit: int = Query(default=30),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["alerts"], constituency_id)
    rows = [r for r in rows if r.get("status") in ("new", "acknowledged", "in_progress", None)]
    if severity:
        rows = [r for r in rows if r.get("severity") == severity]
    severity_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}
    rows = sorted(rows, key=lambda r: severity_order.get(r.get("severity", "low"), 3))
    return ok(paginate(rows, limit, offset))

@app.get("/api/v1/alerts/statistics")
def alerts_statistics(constituency_id: Optional[str] = None):
    rows = filter_constituency(DATA["alerts"], constituency_id)
    total = len(rows)
    active = len([r for r in rows if r.get("status") in ("new", "acknowledged", "in_progress")])
    resolved = len([r for r in rows if r.get("status") == "resolved"])
    critical = len([r for r in rows if r.get("severity") == "critical"])
    high = len([r for r in rows if r.get("severity") == "high"])
    by_type: Dict[str, int] = {}
    for r in rows:
        t = r.get("alert_type", "other")
        by_type[t] = by_type.get(t, 0) + 1
    by_category: Dict[str, int] = {}
    for r in rows:
        c = r.get("alert_category", "other")
        by_category[c] = by_category.get(c, 0) + 1
    return ok({
        "total_alerts": total,
        "active_alerts": active,
        "resolved_alerts": resolved,
        "critical_alerts": critical,
        "high_alerts": high,
        "by_type": by_type,
        "by_category": by_category,
        "resolution_rate": round((resolved / max(total, 1)) * 100, 1),
    })

@app.get("/api/v1/alerts/crisis-dashboard")
def crisis_dashboard(
    constituency_id: Optional[str] = None,
    limit: int = Query(default=20),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["crisis"], constituency_id)
    active = [r for r in rows if r.get("status") in ("active", "monitoring", "escalated")]
    active = sorted(active, key=lambda r: r.get("severity", ""), reverse=True)
    return ok(paginate(active, limit, offset))

@app.get("/api/v1/alerts/resolution-metrics")
def alert_resolution_metrics(constituency_id: Optional[str] = None):
    rows = filter_constituency(DATA["alerts"], constituency_id)
    resolved = [r for r in rows if r.get("status") == "resolved" and r.get("resolution_time_mins")]
    times = [safe_float(r.get("resolution_time_mins")) for r in resolved]
    avg_time = sum(times) / max(len(times), 1)
    escalations = filter_constituency(DATA["escalations"], constituency_id)
    return ok({
        "total_resolved": len(resolved),
        "average_resolution_time_mins": round(avg_time, 1),
        "average_resolution_time_hours": round(avg_time / 60, 1),
        "escalations_count": len(escalations),
        "resolution_rate": round((len(resolved) / max(len(rows), 1)) * 100, 1),
    })

# Also handle reminder-type endpoint that Flutter calls
@app.get("/api/v1/alerts/reminders")
def alerts_reminders(constituency_id: Optional[str] = None, limit: int = Query(default=20)):
    rows = filter_constituency(DATA["alerts"], constituency_id)
    reminders = [r for r in rows if r.get("requires_followup") == "True"]
    return ok(reminders[:limit])


# ═══════════════════════════════════════════════════════════════════
# LEGACY: VISITS
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/visits")
def get_visits(
    constituency_id: Optional[str] = None,
    limit: int = Query(default=30),
    offset: int = Query(default=0)
):
    rows = filter_constituency(DATA["visits"], constituency_id)
    return ok(paginate(rows, limit, offset))

@app.get("/api/v1/visits/statistics")
def visit_statistics(constituency_id: Optional[str] = None):
    rows = filter_constituency(DATA["visits"], constituency_id)
    total = len(rows)
    total_attendance = sum(safe_int(r.get("total_attendance")) for r in rows)
    total_grievances = sum(safe_int(r.get("grievances_count")) for r in rows)
    return ok({
        "total_visits": total,
        "total_attendance": total_attendance,
        "total_grievances": total_grievances,
        "average_attendance": round(total_attendance / max(total, 1), 1),
        "grievance_resolution_rate": round(
            sum(safe_int(r.get("grievances_resolved_on_spot")) for r in rows) /
            max(total_grievances, 1) * 100, 1)
    })

@app.get("/api/v1/visits/timeline")
def visit_timeline(
    constituency_id: Optional[str] = None,
    days: int = Query(default=30),
    limit: int = Query(default=60)
):
    rows = filter_constituency(DATA["visit_stats"], constituency_id)
    return ok(rows[:limit])

@app.get("/api/v1/visits/search")
def visit_search(q: str = Query(default=""), constituency_id: Optional[str] = None):
    rows = filter_constituency(DATA["visits"], constituency_id)
    if q:
        q_lower = q.lower()
        rows = [r for r in rows if
                q_lower in str(r.get("location_ward", "")).lower() or
                q_lower in str(r.get("visit_type", "")).lower() or
                q_lower in str(r.get("leader_name", "")).lower()]
    return ok(rows[:30])


# ═══════════════════════════════════════════════════════════════════
# GRIEVANCES (mock CRUD)
# ═══════════════════════════════════════════════════════════════════
_grievances_store: List[Dict] = [
    {
        "id": f"grv_{i:04d}", "constituency_id": f"PC0{(i%5)+1}",
        "title": f"Grievance #{i}: {'Water supply issue' if i%3==0 else 'Road repair needed' if i%3==1 else 'Power outage complaint'}",
        "description": "Citizen reported issue requiring immediate attention.",
        "category": ["infrastructure", "water", "electricity", "roads", "healthcare"][i % 5],
        "status": ["open", "in_progress", "resolved", "escalated"][i % 4],
        "priority": ["high", "medium", "low", "critical"][i % 4],
        "created_at": f"2025-{(i%12)+1:02d}-{(i%28)+1:02d}T10:00:00",
        "reported_by": f"citizen_{i:03d}",
        "location_ward": ["Boath", "Nirmal", "Adilabad", "Asifabad", "Mancherial"][i % 5],
    }
    for i in range(1, 51)
]

@app.get("/api/v1/grievances")
def get_grievances(
    constituency_id: Optional[str] = None,
    status: Optional[str] = None,
    category: Optional[str] = None,
    limit: int = Query(default=20),
    offset: int = Query(default=0)
):
    rows = _grievances_store
    if constituency_id:
        rows = [r for r in rows if r.get("constituency_id") == constituency_id]
    if status:
        rows = [r for r in rows if r.get("status") == status]
    if category:
        rows = [r for r in rows if r.get("category") == category]
    return ok(paginate(rows, limit, offset))

@app.post("/api/v1/grievances")
def create_grievance(payload: dict = None):
    new_grv = {**(payload or {}), "id": f"grv_{len(_grievances_store)+1:04d}", "status": "open", "created_at": "2026-05-05T10:00:00"}
    _grievances_store.append(new_grv)
    return ok(new_grv)

@app.get("/api/v1/grievances/stats/summary")
def grievance_stats(constituency_id: Optional[str] = None):
    rows = _grievances_store
    if constituency_id:
        rows = [r for r in rows if r.get("constituency_id") == constituency_id]
    return ok({
        "total": len(rows),
        "open": len([r for r in rows if r.get("status") == "open"]),
        "in_progress": len([r for r in rows if r.get("status") == "in_progress"]),
        "resolved": len([r for r in rows if r.get("status") == "resolved"]),
        "escalated": len([r for r in rows if r.get("status") == "escalated"]),
    })

@app.get("/api/v1/grievances/{grievance_id}")
def get_grievance(grievance_id: str):
    for r in _grievances_store:
        if r.get("id") == grievance_id:
            return ok(r)
    return {"success": False, "error": "Not found"}

@app.patch("/api/v1/grievances/{grievance_id}")
def update_grievance(grievance_id: str, payload: dict = None):
    for r in _grievances_store:
        if r.get("id") == grievance_id:
            r.update(payload or {})
            return ok(r)
    return {"success": False, "error": "Not found"}


# ═══════════════════════════════════════════════════════════════════
# USERS
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/users/me")
def get_me():
    return ok({
        "id": "user_001", "name": "Demo Admin", "email": "admin@geodisha.in",
        "role": "admin", "constituency_id": "PC01", "constituency_name": "Adilabad",
        "phone": "+91 9876543210", "created_at": "2025-01-01T00:00:00"
    })

@app.patch("/api/v1/users/me")
def update_me(payload: dict = None):
    return ok({"message": "Profile updated (mock)", **(payload or {})})


# ═══════════════════════════════════════════════════════════════════
# CONSTITUENCY OVERVIEW & KPIs  (CSV 01, 02, 03)
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/constituency/overview")
def constituency_overview(
    constituency_id: Optional[str] = Query(None),
    limit: int = Query(20), offset: int = Query(0)
):
    rows = filter_constituency(DATA["overview"], constituency_id)
    return ok(paginate(rows, limit, offset), total=len(rows))

@app.get("/api/v1/constituency/kpis")
def constituency_kpis(
    constituency_id: Optional[str] = Query(None),
    period: Optional[str] = Query(None),
    limit: int = Query(30), offset: int = Query(0)
):
    rows = filter_constituency(DATA["kpis"], constituency_id)
    if period:
        rows = [r for r in rows if str(r.get("report_date","")).startswith(period)]
    # Sort by date desc
    rows = sorted(rows, key=lambda r: str(r.get("report_date","")), reverse=True)
    return ok(paginate(rows, limit, offset), total=len(rows))

@app.get("/api/v1/constituency/trends")
def constituency_trends(
    constituency_id: Optional[str] = Query(None),
    metric: Optional[str] = Query(None),
    limit: int = Query(50), offset: int = Query(0)
):
    rows = filter_constituency(DATA["trends"], constituency_id)
    if metric:
        rows = [r for r in rows if r.get("metric_name") == metric]
    rows = sorted(rows, key=lambda r: str(r.get("analysis_date","")), reverse=True)
    return ok(paginate(rows, limit, offset), total=len(rows))


# ═══════════════════════════════════════════════════════════════════
# EXECUTIVE SUMMARY  (CSV 04)
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/executive-summary")
def executive_summary(
    constituency_id: Optional[str] = Query(None),
    period: Optional[str] = Query("monthly"),
    limit: int = Query(12), offset: int = Query(0)
):
    rows = filter_constituency(DATA["exec_summary"], constituency_id)
    rows = [r for r in rows if r.get("report_period") == period or period is None]
    rows = sorted(rows, key=lambda r: str(r.get("report_date","")), reverse=True)
    return ok(paginate(rows, limit, offset), total=len(rows))


# ═══════════════════════════════════════════════════════════════════
# VISIT PLANNING  (CSV 08)
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/ground-reality/visit-planning")
def visit_planning(
    constituency_id: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    limit: int = Query(20), offset: int = Query(0)
):
    rows = filter_constituency(DATA["visit_plans"], constituency_id)
    if status:
        rows = [r for r in rows if r.get("status","").lower() == status.lower()]
    rows = sorted(rows, key=lambda r: str(r.get("plan_date","")), reverse=True)
    return ok(paginate(rows, limit, offset), total=len(rows))


# ═══════════════════════════════════════════════════════════════════
# WARD INTELLIGENCE  (CSV 11)
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/ground-reality/ward-intelligence")
def ward_intelligence(
    constituency_id: Optional[str] = Query(None),
    risk_level: Optional[str] = Query(None),
    limit: int = Query(30), offset: int = Query(0)
):
    rows = filter_constituency(DATA["ward_intel"], constituency_id)
    if risk_level:
        rows = [r for r in rows if r.get("risk_level","").lower() == risk_level.lower()]
    # Sort by overall_health_score asc (worst first)
    rows = sorted(rows, key=lambda r: safe_float(r.get("overall_health_score", 100)))
    return ok(paginate(rows, limit, offset), total=len(rows))


# ═══════════════════════════════════════════════════════════════════
# VISIT STATISTICS  (CSV 12)
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/ground-reality/visit-stats")
def visit_stats(
    constituency_id: Optional[str] = Query(None),
    period_type: Optional[str] = Query("monthly"),
    limit: int = Query(12), offset: int = Query(0)
):
    rows = filter_constituency(DATA["visit_stats"], constituency_id)
    if period_type:
        rows = [r for r in rows if r.get("period_type","").lower() == period_type.lower()]
    rows = sorted(rows, key=lambda r: str(r.get("report_date","")), reverse=True)
    return ok(paginate(rows, limit, offset), total=len(rows))


# ═══════════════════════════════════════════════════════════════════
# VOTER SEGMENTS  (CSV 15)
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/voter-segments")
def voter_segments(
    constituency_id: Optional[str] = Query(None),
    segment_type: Optional[str] = Query(None),
    priority_level: Optional[str] = Query(None),
    limit: int = Query(30), offset: int = Query(0)
):
    rows = filter_constituency(DATA["voter_segments"], constituency_id)
    if segment_type:
        rows = [r for r in rows if r.get("segment_type","").lower() == segment_type.lower()]
    if priority_level:
        rows = [r for r in rows if r.get("priority_level","").lower() == priority_level.lower()]
    # Sort by total_voters desc
    rows = sorted(rows, key=lambda r: safe_int(r.get("total_voters", 0)), reverse=True)
    return ok(paginate(rows, limit, offset), total=len(rows))


# ═══════════════════════════════════════════════════════════════════
# OPPOSITION INTELLIGENCE  (CSV 16)
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/opposition-intelligence")
def opposition_intelligence(
    constituency_id: Optional[str] = Query(None),
    limit: int = Query(20), offset: int = Query(0)
):
    rows = filter_constituency(DATA["opposition"], constituency_id)
    rows = sorted(rows, key=lambda r: safe_float(r.get("overall_strength_score", 0)), reverse=True)
    return ok(paginate(rows, limit, offset), total=len(rows))


# ═══════════════════════════════════════════════════════════════════
# PROMISE UPDATES & MILESTONES & BENEFICIARIES  (CSV 18, 19, 20)
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/promises/updates")
def promise_updates(
    constituency_id: Optional[str] = Query(None),
    promise_id: Optional[str] = Query(None),
    limit: int = Query(30), offset: int = Query(0)
):
    rows = filter_constituency(DATA["promise_updates"], constituency_id)
    if promise_id:
        rows = [r for r in rows if r.get("promise_id") == promise_id]
    rows = sorted(rows, key=lambda r: str(r.get("update_date","")), reverse=True)
    return ok(paginate(rows, limit, offset), total=len(rows))

@app.get("/api/v1/promises/milestones")
def promise_milestones(
    constituency_id: Optional[str] = Query(None),
    promise_id: Optional[str] = Query(None),
    limit: int = Query(50), offset: int = Query(0)
):
    rows = filter_constituency(DATA["promise_miles"], constituency_id)
    if promise_id:
        rows = [r for r in rows if r.get("promise_id") == promise_id]
    rows = sorted(rows, key=lambda r: safe_int(r.get("milestone_order", 99)))
    return ok(paginate(rows, limit, offset), total=len(rows))

@app.get("/api/v1/promises/beneficiaries")
def promise_beneficiaries(
    constituency_id: Optional[str] = Query(None),
    limit: int = Query(20), offset: int = Query(0)
):
    rows = filter_constituency(DATA["promise_bene"], constituency_id)
    rows = sorted(rows, key=lambda r: safe_int(r.get("total_beneficiaries", 0)), reverse=True)
    return ok(paginate(rows, limit, offset), total=len(rows))


# ═══════════════════════════════════════════════════════════════════
# ALERTS — ESCALATIONS  (CSV 23)
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/alerts/escalations")
def alert_escalations(
    constituency_id: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    sla_breached: Optional[bool] = Query(None),
    limit: int = Query(20), offset: int = Query(0)
):
    rows = filter_constituency(DATA["escalations"], constituency_id)
    if status:
        rows = [r for r in rows if r.get("status","").lower() == status.lower()]
    if sla_breached is not None:
        rows = [r for r in rows if (str(r.get("sla_breached","")).lower() in ("1","true","yes")) == sla_breached]
    rows = sorted(rows, key=lambda r: str(r.get("escalated_at","")), reverse=True)
    return ok(paginate(rows, limit, offset), total=len(rows))


# ═══════════════════════════════════════════════════════════════════
# MONITORING METRICS  (CSV 24)
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/monitoring/metrics")
def monitoring_metrics(
    constituency_id: Optional[str] = Query(None),
    limit: int = Query(30), offset: int = Query(0)
):
    rows = filter_constituency(DATA["metrics"], constituency_id)
    rows = sorted(rows, key=lambda r: str(r.get("measurement_date","")), reverse=True)

    # Parse JSON sub-fields
    json_subfields = ["alert_counts","crisis_counts","response_performance","health_scores","trends","hotspot_wards","alerts_by_category","risk_indicators","capacity_status"]
    result = []
    for r in paginate(rows, limit, offset):
        row = dict(r)
        for f in json_subfields:
            if isinstance(row.get(f), str):
                row[f] = parse_json_field(row[f])
        result.append(row)
    return ok(result, total=len(rows))

@app.get("/api/v1/monitoring/latest")
def monitoring_latest(constituency_id: Optional[str] = Query("PC01")):
    rows = filter_constituency(DATA["metrics"], constituency_id)
    rows = sorted(rows, key=lambda r: str(r.get("measurement_date","")), reverse=True)
    if not rows:
        return ok({})
    row = dict(rows[0])
    json_subfields = ["alert_counts","crisis_counts","response_performance","health_scores","trends","hotspot_wards","alerts_by_category","risk_indicators","capacity_status"]
    for f in json_subfields:
        if isinstance(row.get(f), str):
            row[f] = parse_json_field(row[f])
    return ok(row)


# ═══════════════════════════════════════════════════════════════════
# BOOTH SCORES & TRENDS  (CSV 13, 14)  — richer endpoints
# ═══════════════════════════════════════════════════════════════════
@app.get("/api/v1/booth-scores")
def booth_scores(
    constituency_id: Optional[str] = Query(None),
    risk_level: Optional[str] = Query(None),
    limit: int = Query(30), offset: int = Query(0)
):
    rows = filter_constituency(DATA["booth_analysis"], constituency_id)
    if risk_level:
        rows = [r for r in rows if r.get("risk_level","").lower() == risk_level.lower()]
    rows = sorted(rows, key=lambda r: safe_float(r.get("booth_score", 100)))
    return ok(paginate(rows, limit, offset), total=len(rows))

@app.get("/api/v1/booth-scores/trends")
def booth_score_trends(
    constituency_id: Optional[str] = Query(None),
    booth_id: Optional[str] = Query(None),
    limit: int = Query(30), offset: int = Query(0)
):
    rows = filter_constituency(DATA["booth_trends"], constituency_id)
    if booth_id:
        rows = [r for r in rows if r.get("booth_id") == booth_id]
    rows = sorted(rows, key=lambda r: str(r.get("measurement_date","")), reverse=True)
    return ok(paginate(rows, limit, offset), total=len(rows))


# ═══════════════════════════════════════════════════════════════════
# BOOT
# ═══════════════════════════════════════════════════════════════════
if __name__ == "__main__":
    uvicorn.run(
        app,           # pass the app object directly — avoids double-import reload
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info",
        workers=1,
    )
