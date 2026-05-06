#!/usr/bin/env python3
"""
Load CSV data into BigQuery tables
Loads all 24 CSV files from backend/scripts/sql/seed/ into geo_pulse_data dataset
"""

import os
import sys
from google.cloud import bigquery
from google.cloud.exceptions import NotFound
from pathlib import Path

# Force output to flush immediately
sys.stdout.flush()
sys.stderr.flush()

# Configuration
PROJECT_ID = "geo-pulse-463507"
DATASET_ID = "geo_pulse_data"
# CSV files are in backend/sql/seed, not backend/scripts/sql/seed
CSV_DIR = Path(__file__).parent.parent / "sql" / "seed"

# Mapping of CSV files to table names
TABLE_MAPPING = {
    # Module 1: Command Center
    "01_constituency_overview.csv": "constituency_overview",
    "02_constituency_kpis.csv": "constituency_kpis",
    "03_constituency_trends.csv": "constituency_trends",
    "04_executive_summary.csv": "executive_summary",
    
    # Module 2: AI Intelligence Hub
    "05_ai_recommendations.csv": "ai_recommendations",
    "06_media_talking_points.csv": "media_talking_points",
    "07_influencer_mapping.csv": "influencer_mapping",
    "08_visit_planning.csv": "visit_planning",
    
    # Module 3: Ground Reality
    "09_visit_records_enhanced.csv": "visit_records_enhanced",
    "10_issue_heatmap.csv": "issue_heatmap",
    "11_ward_intelligence.csv": "ward_intelligence",
    "12_visit_statistics.csv": "visit_statistics",
    
    # Module 4: Election War Room
    "13_booth_analysis.csv": "booth_analysis",
    "14_booth_score_trends.csv": "booth_score_trends",
    "15_voter_segments.csv": "voter_segments",
    "16_opposition_intelligence.csv": "opposition_intelligence",
    
    # Module 5: Promises
    "17_promises.csv": "promises",
    "18_promise_updates.csv": "promise_updates",
    "19_promise_milestones.csv": "promise_milestones",
    "20_promise_beneficiaries.csv": "promise_beneficiaries",
    
    # Module 6: Alerts & Crisis
    "21_alerts.csv": "alerts",
    "22_crisis_events.csv": "crisis_events",
    "23_issue_escalations.csv": "issue_escalations",
    "24_monitoring_metrics.csv": "monitoring_metrics",
}

def load_csv_to_bigquery(client, csv_file, table_name):
    """Load a CSV file into a BigQuery table"""
    
    table_id = f"{PROJECT_ID}.{DATASET_ID}.{table_name}"
    csv_path = CSV_DIR / csv_file
    
    if not csv_path.exists():
        print(f"  ⚠️  CSV file not found: {csv_path}")
        return False
    
    # Configure the load job
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,  # Skip header row
        autodetect=True,  # Auto-detect schema from CSV
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,  # Replace existing data
        allow_jagged_rows=True,  # Allow rows with missing trailing columns
        allow_quoted_newlines=True,  # Allow newlines in quoted fields
        max_bad_records=10,  # Allow up to 10 bad records
    )
    
    try:
        # Load the CSV file
        with open(csv_path, "rb") as source_file:
            job = client.load_table_from_file(
                source_file,
                table_id,
                job_config=job_config
            )
        
        # Wait for the job to complete
        job.result()
        
        # Get the loaded table
        table = client.get_table(table_id)
        
        print(f"  ✅ Loaded {table.num_rows:,} rows into {table_name}")
        return True
        
    except Exception as e:
        print(f"  ❌ Error loading {csv_file}: {str(e)}")
        if hasattr(e, 'errors') and e.errors:
            for error in e.errors:
                print(f"     - {error.get('message', str(error))}")
        return False

def main():
    """Main function to load all CSV files"""
    
    print("=" * 70)
    print("📊 Loading CSV Data into BigQuery Tables")
    print("=" * 70)
    print(f"Project: {PROJECT_ID}")
    print(f"Dataset: {DATASET_ID}")
    print(f"CSV Directory: {CSV_DIR}")
    print(f"Total Files: {len(TABLE_MAPPING)}")
    print("=" * 70)
    
    # Initialize BigQuery client
    try:
        client = bigquery.Client(project=PROJECT_ID)
        print("✅ BigQuery client initialized\n")
    except Exception as e:
        print(f"❌ Failed to initialize BigQuery client: {e}")
        return
    
    # Verify dataset exists
    try:
        dataset = client.get_dataset(f"{PROJECT_ID}.{DATASET_ID}")
        print(f"✅ Dataset '{DATASET_ID}' found\n")
    except NotFound:
        print(f"❌ Dataset '{DATASET_ID}' not found")
        return
    
    # Load each CSV file
    success_count = 0
    failed_count = 0
    
    for idx, (csv_file, table_name) in enumerate(TABLE_MAPPING.items(), 1):
        print(f"[{idx}/{len(TABLE_MAPPING)}] Loading: {csv_file} → {table_name}")
        
        if load_csv_to_bigquery(client, csv_file, table_name):
            success_count += 1
        else:
            failed_count += 1
        print()
    
    # Summary
    print("=" * 70)
    print("📊 LOAD SUMMARY")
    print("=" * 70)
    print(f"✅ Successfully loaded: {success_count} tables")
    if failed_count > 0:
        print(f"❌ Failed to load: {failed_count} tables")
    print(f"📦 Total rows loaded across all tables")
    print("=" * 70)
    
    # Get total row count
    try:
        total_rows = 0
        for table_name in TABLE_MAPPING.values():
            table = client.get_table(f"{PROJECT_ID}.{DATASET_ID}.{table_name}")
            total_rows += table.num_rows
        print(f"\n🎉 Total: {total_rows:,} rows loaded successfully!")
    except Exception as e:
        print(f"\n⚠️  Could not calculate total rows: {e}")

if __name__ == "__main__":
    main()
