#!/usr/bin/env python3
"""
Apply fixed Ground Reality views to BigQuery
Fixes correlated subquery issues in JOIN predicates
"""

from google.cloud import bigquery
import os

# Initialize BigQuery client
client = bigquery.Client(project="geo-pulse-463507")

def apply_fixed_views():
    """Apply the fixed view definitions"""
    
    sql_file = "/Users/conglomerateit/Documents/GEODISHA/Code/gd_playground/geodisha-mobile-app/backend/sql/views/03_ground_reality_views_fixed.sql"
    
    print("=" * 80)
    print("Applying Fixed Ground Reality Views to BigQuery")
    print("=" * 80)
    
    # Read the SQL file
    with open(sql_file, 'r') as f:
        sql_content = f.read()
    
    # Split by CREATE OR REPLACE VIEW statements
    view_statements = []
    current_statement = []
    
    for line in sql_content.split('\n'):
        if line.strip().startswith('CREATE OR REPLACE VIEW') and current_statement:
            view_statements.append('\n'.join(current_statement))
            current_statement = [line]
        else:
            current_statement.append(line)
    
    # Add the last statement
    if current_statement:
        view_statements.append('\n'.join(current_statement))
    
    # Filter out comments and empty statements
    view_statements = [stmt for stmt in view_statements if 'CREATE OR REPLACE VIEW' in stmt]
    
    print(f"\nFound {len(view_statements)} view definitions to apply\n")
    
    # Apply each view
    success_count = 0
    error_count = 0
    
    for i, statement in enumerate(view_statements, 1):
        # Extract view name
        view_name = statement.split('`')[1].split('.')[-1] if '`' in statement else f"view_{i}"
        
        print(f"[{i}/{len(view_statements)}] Creating view: {view_name}...")
        
        try:
            # Execute the query
            query_job = client.query(statement)
            query_job.result()  # Wait for completion
            
            print(f"    ✅ SUCCESS: {view_name} created/updated")
            success_count += 1
            
        except Exception as e:
            print(f"    ❌ ERROR: Failed to create {view_name}")
            print(f"    Error: {str(e)}")
            error_count += 1
    
    print("\n" + "=" * 80)
    print(f"Summary: {success_count} successful, {error_count} failed")
    print("=" * 80)
    
    if error_count == 0:
        print("✅ All views applied successfully!")
    else:
        print(f"⚠️  {error_count} views failed. Check errors above.")

if __name__ == "__main__":
    apply_fixed_views()
