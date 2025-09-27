#!/usr/bin/env python3
"""
Electra PostgreSQL Database Creation Script - Python Version

Standalone script to create local PostgreSQL database and user for Electra.
This is the Python equivalent of create_local_postgres_db.ps1.
"""

import os
import sys
import argparse
import subprocess
import getpass
from pathlib import Path

def run_command(command, capture_output=True, env=None):
    """Run a system command and return the result."""
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=capture_output,
            text=True,
            env=env
        )
        return result
    except Exception as e:
        print(f"Error running command '{command}': {e}")
        return subprocess.CompletedProcess(
            args=command, returncode=1, stdout="", stderr=str(e)
        )

def test_postgresql_available():
    """Check if PostgreSQL tools are available."""
    result = run_command("psql --version")
    return result.returncode == 0

def test_postgresql_connection(admin_user, host, port):
    """Test PostgreSQL connection."""
    result = run_command(f'psql -U {admin_user} -h {host} -p {port} -c "SELECT version();" -t')
    return result.returncode == 0

def create_postgresql_database(database_name, database_user, database_password, 
                             admin_user, host, port):
    """Create PostgreSQL database and user."""
    print("🔧 Creating PostgreSQL database and user...")
    print(f"  Database: {database_name}")
    print(f"  User: {database_user}")
    print(f"  Host: {host}")
    print(f"  Port: {port}")
    print()
    
    try:
        # Check if database already exists
        print("📋 Checking if database exists...")
        result = run_command(f'psql -U {admin_user} -h {host} -p {port} -lqt')
        
        if result.returncode == 0 and database_name in result.stdout:
            print(f"ℹ️  Database '{database_name}' already exists")
        else:
            print(f"📦 Creating database '{database_name}'...")
            result = run_command(f'psql -U {admin_user} -h {host} -p {port} -c "CREATE DATABASE \\"{database_name}\\";')
            
            if result.returncode == 0:
                print(f"✅ Database '{database_name}' created successfully")
            else:
                print(f"❌ Failed to create database: {result.stderr}")
                return False
        
        # Check if user already exists
        print("👤 Checking if user exists...")
        result = run_command(f'psql -U {admin_user} -h {host} -p {port} -c "SELECT 1 FROM pg_roles WHERE rolname=\'{database_user}\';" -t')
        
        if result.returncode == 0 and "1" in result.stdout:
            print(f"ℹ️  User '{database_user}' already exists")
        else:
            print(f"👤 Creating user '{database_user}'...")
            result = run_command(f'psql -U {admin_user} -h {host} -p {port} -c "CREATE USER \\"{database_user}\\" WITH PASSWORD \'{database_password}\';"')
            
            if result.returncode == 0:
                print(f"✅ User '{database_user}' created successfully")
            else:
                print(f"❌ Failed to create user: {result.stderr}")
                return False
        
        # Grant privileges
        print("🔐 Granting privileges...")
        result = run_command(f'psql -U {admin_user} -h {host} -p {port} -c "GRANT ALL PRIVILEGES ON DATABASE \\"{database_name}\\" TO \\"{database_user}\\";')
        
        if result.returncode == 0:
            print("✅ Privileges granted successfully")
        else:
            print(f"⚠️  Warning: Failed to grant privileges: {result.stderr}")
        
        # Create required extensions
        print("🔧 Creating database extensions...")
        extensions = ["uuid-ossp", "pgcrypto"]
        
        for extension in extensions:
            result = run_command(f'psql -U {admin_user} -h {host} -p {port} -d {database_name} -c "CREATE EXTENSION IF NOT EXISTS \\"{extension}\\";')
            
            if result.returncode == 0:
                print(f"✅ Extension '{extension}' created")
            else:
                print(f"⚠️  Warning: Could not create extension '{extension}': {result.stderr}")
        
        # Test connection with new user
        print("🔍 Testing database connection...")
        env = os.environ.copy()
        env['PGPASSWORD'] = database_password
        
        result = run_command(f'psql -U {database_user} -h {host} -p {port} -d {database_name} -c "SELECT current_database(), current_user;" -t', env=env)
        
        if result.returncode == 0:
            print("✅ Database connection test successful")
            print(f"   {result.stdout.strip()}")
        else:
            print(f"⚠️  Warning: Database connection test failed: {result.stderr}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error during database creation: {e}")
        return False

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Create local PostgreSQL database and user for Electra",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python setup/create_local_postgres_db.py
  python setup/create_local_postgres_db.py --database-name electra_prod --database-user electra_prod
  python setup/create_local_postgres_db.py --host remote-host --port 5433

Prerequisites:
  - PostgreSQL server installed and running
  - psql command-line tool available in PATH
  - Admin access to PostgreSQL server
        """
    )
    
    parser.add_argument(
        '--database-name',
        default='electra_debug',
        help='Name of the database to create (default: electra_debug)'
    )
    
    parser.add_argument(
        '--database-user',
        default='electra_debug',
        help='Name of the database user to create (default: electra_debug)'
    )
    
    parser.add_argument(
        '--database-password',
        help='Password for the database user (will prompt if not provided)'
    )
    
    parser.add_argument(
        '--admin-user',
        default='postgres',
        help='PostgreSQL admin user (default: postgres)'
    )
    
    parser.add_argument(
        '--host',
        default='localhost',
        help='PostgreSQL host (default: localhost)'
    )
    
    parser.add_argument(
        '--port',
        type=int,
        default=5432,
        help='PostgreSQL port (default: 5432)'
    )
    
    args = parser.parse_args()
    
    print("🐘 Electra PostgreSQL Database Setup")
    print("====================================")
    print()
    
    # Check if PostgreSQL tools are available
    if not test_postgresql_available():
        print("❌ PostgreSQL command-line tools (psql) not found in PATH")
        print()
        print("Please install PostgreSQL and ensure psql is available:")
        print("1. Download PostgreSQL from: https://www.postgresql.org/download/")
        print("2. Install PostgreSQL with default settings")
        print("3. Add PostgreSQL bin directory to your PATH")
        print("4. Restart your terminal and try again")
        sys.exit(1)
    
    print("✅ PostgreSQL tools found")
    
    # Test PostgreSQL connection
    print("🔍 Testing PostgreSQL connection...")
    if not test_postgresql_connection(args.admin_user, args.host, args.port):
        print("❌ Cannot connect to PostgreSQL server")
        print()
        print("Please ensure:")
        print("1. PostgreSQL server is running")
        print("2. Connection parameters are correct:")
        print(f"   - Host: {args.host}")
        print(f"   - Port: {args.port}")
        print(f"   - Admin User: {args.admin_user}")
        print(f"3. You have permission to connect as '{args.admin_user}'")
        sys.exit(1)
    
    print("✅ PostgreSQL server is accessible")
    
    # Get password if not provided
    database_password = args.database_password
    if not database_password:
        database_password = getpass.getpass(f"Enter password for database user '{args.database_user}': ")
        
        if not database_password:
            print("❌ Password is required")
            sys.exit(1)
    
    # Create database and user
    success = create_postgresql_database(
        args.database_name,
        args.database_user,
        database_password,
        args.admin_user,
        args.host,
        args.port
    )
    
    if success:
        print()
        print("🎉 Database setup completed successfully!")
        print()
        print("Connection details:")
        print(f"  Database: {args.database_name}")
        print(f"  User: {args.database_user}")
        print(f"  Host: {args.host}")
        print(f"  Port: {args.port}")
        print(f"  Connection URL: postgresql://{args.database_user}:[PASSWORD]@{args.host}:{args.port}/{args.database_name}")
        print()
        print("You can now use this database in your .env file:")
        print(f"DATABASE_URL=postgresql://{args.database_user}:[PASSWORD]@{args.host}:{args.port}/{args.database_name}")
        sys.exit(0)
    else:
        print()
        print("❌ Database setup failed")
        print("Please check the error messages above and try again.")
        sys.exit(1)

if __name__ == '__main__':
    main()