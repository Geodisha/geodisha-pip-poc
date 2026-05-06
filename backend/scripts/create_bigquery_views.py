#!/usr/bin/env python3
"""
Create BigQuery Views for all 6 modules
Executes view creation SQL scripts for GeoDisha Mobile App
"""

import sys
import os
from pathlib import Path
from google.cloud import bigquery
from google.cloud.exceptions import NotFound

# Force output to flush immediately
sys.stdout.flush()
sys.stderr.flush()

# Configuration
PROJECT_ID = "geo-pulse-463507"
DATASET_ID = "geo_pulse_data"
VIEWS_DIR = Path(__file__).parent.parent / "sql" / "views"

# View SQL files in order
VIEW_FILES = [
    "01_command_center_views.sql",
    "02_ai_intelligence_views.sql",
    "03_ground_reality_views.sql",
    "04_election_war_room_views.sql",
    "05_promises_views.sql",
    "06_alerts_views.sql",
]

def extract_view_statements(sql_content):
    """
    Extract individual CREATE VIEW statements from SQL file
    Returns list of (view_name, sql_statement) tuples
    """
    statements = []
    current_statement = []
    view_name = None
    
    lines = sql_content.split('\n')
    in_statement = False
    
    for line in lines:
        # Skip comments and empty lines when not in a statement
        if not in_statement and (line.strip().startswith('--') or not line.strip()):
            continue
        
        # Check if this is the start of a CREATE VIEW statement
        if line.strip().upper().startswith('CREATE OR REPLACE VIEW'):
            in_statement = True
            current_statement = [line]
            # Extract view name
            parts = line.split('`')
            if len(parts) >= 2:
                view_name = parts[-2].split('.')[-1]
        elif in_statement:
            current_statement.append(line)
            # Check if statement ends with semicolon
            if line.strip().endswith(';'):
                statements.append((view_name, '\n'.join(current_statement)))
                current_statement = []
                view_name = None
                in_statement = False
    
    return statements

def create_view(client, view_name, sql_statement):
    """Create or replace a BigQuery view"""
    try:
        # Execute the CREATE OR REPLACE VIEW statement
        query_job = client.query(sql_statement)
        query_job.result()  # Wait for completion
        
        print(f"  ✅ Created view: {view_name}")
        return True
        
    except Exception as e:
        print(f"  ❌ Error creating view {view_name}: {str(e)}")
        # Print first few lines of error for debugging
        error_lines = str(e).split('\n')[:3]
        for line in error_lines:
            print(f"     {line}")
        return False

def process_view_file(client, file_path):
    """Process a single view SQL file"""
    file_name = file_path.name
    print(f"\n📄 Processing: {file_name}")
    
    if not file_path.exists():
        print(f"  ⚠️  File not found: {file_path}")
        return 0, 0
    
    try:
        # Read SQL file
        with open(file_path, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        # Extract view statements
        view_statements = extract_view_statements(sql_content)
        
        if not view_statements:
            print(f"  ⚠️  No view statements found in {file_name}")
            return 0, 0
        
        print(f"  Found {len(view_statements)} view(s) to create")
        
        # Create each view
        success_count = 0
        failed_count = 0
        
        for view_name, sql_statement in view_statements:
            if create_view(client, view_name, sql_statement):
                success_count += 1
            else:
                failed_count += 1
        
        return success_count, failed_count
        
    except Exception as e:
        print(f"  ❌ Error processing file: {e}")
        return 0, 1

def main():
    """Main function to create all views"""
    
    print("=" * 70)
    print("🔭 Creating BigQuery Views for GeoDisha Mobile App")
    print("=" * 70)
    print(f"Project: {PROJECT_ID}")
    print(f"Dataset: {DATASET_ID}")
    print(f"Views Directory: {VIEWS_DIR}")
    print(f"Total Files: {len(VIEW_FILES)}")
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
    
    # Process each view file
    total_success = 0
    total_failed = 0
    modules_processed = 0
    
    for idx, file_name in enumerate(VIEW_FILES, 1):
        file_path = VIEWS_DIR / file_name
        
        # Extract module name from filename
        module_num = file_name.split('_')[0]
        module_name = ' '.join(file_name.replace('.sql', '').split('_')[1:]).title()
        
        print(f"\n{'=' * 70}")
        print(f"MODULE {module_num}: {module_name}")
        print(f"[{idx}/{len(VIEW_FILES)}]")
        print(f"{'=' * 70}")
        
        success, failed = process_view_file(client, file_path)
        total_success += success
        total_failed += failed
        
        if success > 0 or failed == 0:
            modules_processed += 1
    
    # Summary
    print("\n" + "=" * 70)
    print("📊 VIEW CREATION SUMMARY")
    print("=" * 70)
    print(f"✅ Modules processed: {modules_processed}/{len(VIEW_FILES)}")
    print(f"✅ Views created successfully: {total_success}")
    if total_failed > 0:
        print(f"❌ Views failed: {total_failed}")
    print("=" * 70)
    
    if total_success > 0:
        print(f"\n🎉 Successfully created {total_success} BigQuery views!")
        print(f"📍 Dataset: {PROJECT_ID}.{DATASET_ID}")
        print(f"\nYou can now query these views in your BigQuery console:")
        print(f"https://console.cloud.google.com/bigquery?project={PROJECT_ID}&ws=!1m4!1m3!3m2!1s{PROJECT_ID}!2s{DATASET_ID}")
    
    if total_failed > 0:
        print(f"\n⚠️  {total_failed} view(s) failed to create. Check the errors above for details.")

if __name__ == "__main__":
    main()
