#!/usr/bin/env python3
"""
BigQuery Table Creation Script
Creates all 24 tables across 6 modules for GeoDisha Mobile App
"""

import os
import sys
from pathlib import Path
from google.cloud import bigquery
from google.api_core import exceptions
import time

# BigQuery Configuration
PROJECT_ID = "geo-pulse-463507"
DATASET_ID = "geo_pulse_data"

# Schema files directory
SCHEMA_DIR = Path(__file__).parent.parent / "sql" / "schema"

# Schema files in order
SCHEMA_FILES = [
    "01_command_center_tables.sql",
    "02_ai_intelligence_tables.sql",
    "03_ground_reality_tables.sql",
    "04_election_war_room_tables.sql",
    "05_promises_tables.sql",
    "06_alerts_tables.sql"
]

def initialize_bigquery_client():
    """Initialize BigQuery client with proper credentials"""
    try:
        client = bigquery.Client(project=PROJECT_ID)
        print(f"✓ Connected to BigQuery project: {PROJECT_ID}")
        return client
    except Exception as e:
        print(f"❌ Error connecting to BigQuery: {e}")
        print("\nMake sure you have:")
        print("1. Set GOOGLE_APPLICATION_CREDENTIALS environment variable")
        print("2. Or authenticated with: gcloud auth application-default login")
        sys.exit(1)

def ensure_dataset_exists(client):
    """Ensure the dataset exists, create if it doesn't"""
    dataset_ref = f"{PROJECT_ID}.{DATASET_ID}"
    
    try:
        client.get_dataset(dataset_ref)
        print(f"✓ Dataset {DATASET_ID} already exists")
        return True
    except exceptions.NotFound:
        print(f"⚠️  Dataset {DATASET_ID} not found, creating...")
        
        dataset = bigquery.Dataset(dataset_ref)
        dataset.location = "US"  # Change if needed
        dataset.description = "GeoDisha Mobile App - Political Analytics Data"
        
        try:
            dataset = client.create_dataset(dataset, timeout=30)
            print(f"✓ Created dataset {DATASET_ID}")
            return True
        except Exception as e:
            print(f"❌ Error creating dataset: {e}")
            return False

def parse_sql_file(file_path):
    """Parse SQL file and extract individual CREATE TABLE statements"""
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Split by CREATE TABLE statements
    statements = []
    current_statement = []
    in_create_statement = False
    paren_count = 0
    
    for line in content.split('\n'):
        stripped = line.strip()
        
        # Skip comments and empty lines
        if stripped.startswith('--') or not stripped:
            continue
            
        # Check if this is start of CREATE TABLE
        if 'CREATE TABLE' in line.upper() or 'CREATE OR REPLACE TABLE' in line.upper():
            if current_statement:
                statements.append('\n'.join(current_statement))
            current_statement = [line]
            in_create_statement = True
            paren_count = 0
        elif in_create_statement:
            current_statement.append(line)
            # Count parentheses to know when statement ends
            paren_count += line.count('(') - line.count(')')
            
            # Check if statement is complete (ends with semicolon and balanced parens)
            if ';' in line and paren_count <= 0:
                statements.append('\n'.join(current_statement))
                current_statement = []
                in_create_statement = False
    
    # Add last statement if exists
    if current_statement:
        statements.append('\n'.join(current_statement))
    
    return statements

def extract_table_name(sql_statement):
    """Extract table name from CREATE TABLE statement"""
    import re
    # Match: CREATE TABLE [IF NOT EXISTS] `project.dataset.table_name`
    match = re.search(r'CREATE\s+(?:OR\s+REPLACE\s+)?TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?`?([^`\s]+)`?', 
                     sql_statement, re.IGNORECASE)
    if match:
        full_name = match.group(1)
        # Extract just the table name (last part after dots)
        return full_name.split('.')[-1]
    return "Unknown"

def execute_sql_statement(client, sql_statement, table_name):
    """Execute a single SQL statement in BigQuery"""
    try:
        query_job = client.query(sql_statement)
        query_job.result()  # Wait for completion
        print(f"  ✓ Created table: {table_name}")
        return True
    except exceptions.Conflict:
        print(f"  ℹ️  Table {table_name} already exists, skipping")
        return True
    except Exception as e:
        print(f"  ❌ Error creating table {table_name}: {e}")
        return False

def create_tables_from_file(client, file_path):
    """Create all tables defined in a SQL file"""
    print(f"\n📄 Processing: {file_path.name}")
    print("=" * 60)
    
    if not file_path.exists():
        print(f"❌ File not found: {file_path}")
        return 0, 0
    
    statements = parse_sql_file(file_path)
    
    if not statements:
        print("⚠️  No CREATE TABLE statements found")
        return 0, 0
    
    success_count = 0
    total_count = len(statements)
    
    for i, statement in enumerate(statements, 1):
        table_name = extract_table_name(statement)
        print(f"\n[{i}/{total_count}] Creating table: {table_name}")
        
        if execute_sql_statement(client, statement, table_name):
            success_count += 1
            time.sleep(0.5)  # Small delay to avoid rate limits
    
    return success_count, total_count

def main():
    """Main function to create all BigQuery tables"""
    print("=" * 70)
    print("  GeoDisha BigQuery Tables Creation")
    print("  Creating 24 tables across 6 modules")
    print("=" * 70)
    
    # Initialize BigQuery client
    client = initialize_bigquery_client()
    
    # Ensure dataset exists
    if not ensure_dataset_exists(client):
        sys.exit(1)
    
    # Track overall statistics
    total_success = 0
    total_tables = 0
    failed_files = []
    
    # Process each schema file
    for schema_file in SCHEMA_FILES:
        file_path = SCHEMA_DIR / schema_file
        
        success, total = create_tables_from_file(client, file_path)
        total_success += success
        total_tables += total
        
        if success < total:
            failed_files.append(schema_file)
    
    # Print summary
    print("\n" + "=" * 70)
    print("  SUMMARY")
    print("=" * 70)
    print(f"✓ Successfully created: {total_success}/{total_tables} tables")
    
    if failed_files:
        print(f"\n⚠️  Files with errors:")
        for file in failed_files:
            print(f"  - {file}")
    
    if total_success == total_tables:
        print("\n🎉 All tables created successfully!")
        return 0
    else:
        print(f"\n⚠️  {total_tables - total_success} table(s) failed to create")
        return 1

if __name__ == "__main__":
    sys.exit(main())
