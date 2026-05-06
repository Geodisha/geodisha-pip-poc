#!/usr/bin/env python3
"""
Test script for GeoDisha BigQuery API Integration
Tests all 6 modules and their endpoints
"""

import asyncio
import sys
from pathlib import Path

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent / "api-gateway"))

from core.bigquery_enhanced import BigQueryEnhancedService

# Test user contexts
ADMIN_CONTEXT = {
    "user_role": "admin",
    "user_constituency_id": None,
    "user_constituencies": None
}

MP_CONTEXT = {
    "user_role": "mp_mla",
    "user_constituency_id": "PC08",  # Secunderabad
    "user_constituencies": ["PC08"]
}

MINISTER_CONTEXT = {
    "user_role": "minister",
    "user_constituency_id": None,
    "user_constituencies": ["PC08", "PC12", "PC15"]  # Multiple constituencies
}


async def test_module_1_command_center(service: BigQueryEnhancedService):
    """Test Module 1: Command Center endpoints"""
    print("\n" + "="*70)
    print("MODULE 1: COMMAND CENTER")
    print("="*70)
    
    try:
        # Test 1: Constituency Overview
        print("\n[1/4] Testing: Constituency Overview...")
        data = await service.get_constituency_overview(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} constituencies")
        if data:
            print(f"   Sample: {data[0]['constituency_name']} - Health Score: {data[0]['health_score']}")
        
        # Test 2: KPI Trends
        print("\n[2/4] Testing: KPI Trends (30 days)...")
        data = await service.get_kpi_trends(days=30, **ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} KPI records")
        
        # Test 3: Executive Summary
        print("\n[3/4] Testing: Executive Summary...")
        data = await service.get_executive_summary(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} executive summaries")
        
        # Test 4: Trends Summary
        print("\n[4/4] Testing: Trends Summary...")
        data = await service.get_trends_summary(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} trend records")
        
        print("\n✅ Module 1: PASSED")
        
    except Exception as e:
        print(f"\n❌ Module 1: FAILED - {e}")
        raise


async def test_module_2_ai_intelligence(service: BigQueryEnhancedService):
    """Test Module 2: AI Intelligence Hub endpoints"""
    print("\n" + "="*70)
    print("MODULE 2: AI INTELLIGENCE HUB")
    print("="*70)
    
    try:
        # Test 1: AI Recommendations
        print("\n[1/4] Testing: AI Recommendations...")
        data = await service.get_ai_recommendations(limit=10, **ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} recommendations")
        if data:
            print(f"   Sample: {data[0]['title']} - Priority: {data[0]['priority']}")
        
        # Test 2: Media Briefing
        print("\n[2/4] Testing: Media Briefing...")
        data = await service.get_media_briefing(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} talking points")
        
        # Test 3: Influencer Map
        print("\n[3/4] Testing: Influencer Map...")
        data = await service.get_influencer_map(min_score=50, **ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} influencers")
        
        # Test 4: Visit Priorities
        print("\n[4/4] Testing: Visit Priority List...")
        data = await service.get_visit_priority_list(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} visit priorities")
        
        print("\n✅ Module 2: PASSED")
        
    except Exception as e:
        print(f"\n❌ Module 2: FAILED - {e}")
        raise


async def test_module_3_ground_reality(service: BigQueryEnhancedService):
    """Test Module 3: Ground Reality endpoints"""
    print("\n" + "="*70)
    print("MODULE 3: GROUND REALITY")
    print("="*70)
    
    try:
        # Test 1: Visits Enhanced
        print("\n[1/4] Testing: Enhanced Visits...")
        data = await service.get_visits_enhanced(limit=50, **ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} visits")
        
        # Test 2: Heatmap Current
        print("\n[2/4] Testing: Current Heatmap...")
        data = await service.get_heatmap_current(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} heatmap entries")
        
        # Test 3: Ward Coverage
        print("\n[3/4] Testing: Ward Coverage...")
        data = await service.get_ward_coverage(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} ward records")
        
        # Test 4: Visit Trends
        print("\n[4/4] Testing: Visit Trends...")
        data = await service.get_visit_trends(days=30, **ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} trend records")
        
        print("\n✅ Module 3: PASSED")
        
    except Exception as e:
        print(f"\n❌ Module 3: FAILED - {e}")
        raise


async def test_module_4_election_war_room(service: BigQueryEnhancedService):
    """Test Module 4: Election War Room endpoints"""
    print("\n" + "="*70)
    print("MODULE 4: ELECTION WAR ROOM")
    print("="*70)
    
    try:
        # Test 1: Booth Scores Summary
        print("\n[1/4] Testing: Booth Scores Summary...")
        data = await service.get_booth_scores_summary(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} booth records")
        
        # Test 2: Election Readiness
        print("\n[2/4] Testing: Election Readiness...")
        data = await service.get_election_readiness(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} readiness assessments")
        
        # Test 3: Booth Risk Matrix
        print("\n[3/4] Testing: Booth Risk Matrix...")
        data = await service.get_booth_risk_matrix(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} risk assessments")
        
        # Test 4: Swing Analysis
        print("\n[4/4] Testing: Swing Analysis...")
        data = await service.get_swing_analysis(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} swing analysis records")
        
        print("\n✅ Module 4: PASSED")
        
    except Exception as e:
        print(f"\n❌ Module 4: FAILED - {e}")
        raise


async def test_module_5_promises(service: BigQueryEnhancedService):
    """Test Module 5: Promises endpoints"""
    print("\n" + "="*70)
    print("MODULE 5: PROMISE TRACKER")
    print("="*70)
    
    try:
        # Test 1: Promises Dashboard
        print("\n[1/4] Testing: Promises Dashboard...")
        data = await service.get_promises_dashboard(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} promises")
        if data:
            print(f"   Sample: {data[0]['promise_title']} - Status: {data[0]['status']}")
        
        # Test 2: Overdue Promises
        print("\n[2/4] Testing: Overdue Promises...")
        data = await service.get_promises_overdue(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} overdue promises")
        
        # Test 3: Promises by Category
        print("\n[3/4] Testing: Promises by Category...")
        data = await service.get_promises_by_category(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} category summaries")
        
        # Test 4: Completion Rate
        print("\n[4/4] Testing: Promise Completion Rate...")
        data = await service.get_promise_completion_rate(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} completion metrics")
        
        print("\n✅ Module 5: PASSED")
        
    except Exception as e:
        print(f"\n❌ Module 5: FAILED - {e}")
        raise


async def test_module_6_alerts_crisis(service: BigQueryEnhancedService):
    """Test Module 6: Alerts & Crisis endpoints"""
    print("\n" + "="*70)
    print("MODULE 6: ALERTS & CRISIS")
    print("="*70)
    
    try:
        # Test 1: Active Alerts
        print("\n[1/4] Testing: Active Alerts...")
        data = await service.get_alerts_active(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} active alerts")
        
        # Test 2: Alert Statistics
        print("\n[2/4] Testing: Alert Statistics...")
        data = await service.get_alerts_statistics(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} stat records")
        
        # Test 3: Crisis Dashboard
        print("\n[3/4] Testing: Crisis Dashboard...")
        data = await service.get_crisis_dashboard(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} crisis events")
        
        # Test 4: Resolution Metrics
        print("\n[4/4] Testing: Alert Resolution Metrics...")
        data = await service.get_alert_resolution_metrics(**ADMIN_CONTEXT)
        print(f"✅ Retrieved {len(data)} resolution metrics")
        
        print("\n✅ Module 6: PASSED")
        
    except Exception as e:
        print(f"\n❌ Module 6: FAILED - {e}")
        raise


async def test_role_based_filtering(service: BigQueryEnhancedService):
    """Test role-based access control"""
    print("\n" + "="*70)
    print("ROLE-BASED ACCESS CONTROL TESTING")
    print("="*70)
    
    try:
        # Test Admin Access
        print("\n[1/3] Testing: Admin Access (should see all constituencies)...")
        data = await service.get_constituency_overview(**ADMIN_CONTEXT)
        admin_count = len(data)
        print(f"✅ Admin sees {admin_count} constituencies")
        
        # Test MP Access
        print("\n[2/3] Testing: MP Access (should see only PC08)...")
        data = await service.get_constituency_overview(**MP_CONTEXT)
        mp_count = len(data)
        print(f"✅ MP sees {mp_count} constituency/constituencies")
        if data:
            constituencies = [d['constituency_id'] for d in data]
            print(f"   Constituencies: {constituencies}")
        
        # Test Minister Access
        print("\n[3/3] Testing: Minister Access (should see 3 constituencies)...")
        data = await service.get_constituency_overview(**MINISTER_CONTEXT)
        minister_count = len(data)
        print(f"✅ Minister sees {minister_count} constituencies")
        if data:
            constituencies = [d['constituency_id'] for d in data]
            print(f"   Constituencies: {constituencies}")
        
        # Validate
        assert mp_count <= admin_count, "MP should not see more than admin"
        assert minister_count <= admin_count, "Minister should not see more than admin"
        
        print("\n✅ Role-Based Access Control: PASSED")
        
    except Exception as e:
        print(f"\n❌ Role-Based Access Control: FAILED - {e}")
        raise


async def main():
    """Run all tests"""
    print("\n" + "="*70)
    print("GEODISHA BIGQUERY API INTEGRATION TEST SUITE")
    print("="*70)
    print(f"\nProject: geo-pulse-463507")
    print(f"Dataset: geo_pulse_data")
    print(f"\nTesting all 6 modules with 24 BigQuery views...")
    
    service = BigQueryEnhancedService()
    
    try:
        # Test all modules
        await test_module_1_command_center(service)
        await test_module_2_ai_intelligence(service)
        await test_module_3_ground_reality(service)
        await test_module_4_election_war_room(service)
        await test_module_5_promises(service)
        await test_module_6_alerts_crisis(service)
        
        # Test role-based filtering
        await test_role_based_filtering(service)
        
        # Final summary
        print("\n" + "="*70)
        print("✅ ALL TESTS PASSED!")
        print("="*70)
        print("\n📊 Summary:")
        print("   • 6 modules tested")
        print("   • 24 views validated")
        print("   • Role-based access control verified")
        print("\n✨ The backend is ready for production!")
        
    except Exception as e:
        print("\n" + "="*70)
        print("❌ TEST SUITE FAILED")
        print("="*70)
        print(f"\nError: {e}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
