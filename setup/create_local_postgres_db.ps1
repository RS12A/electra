# Electra PostgreSQL Database Creation Script - PowerShell
# Standalone script to create local PostgreSQL database and user for Electra

param(
    [Parameter(HelpMessage="Database name")]
    [string]$DatabaseName = "electra_debug",
    
    [Parameter(HelpMessage="Database user")]
    [string]$DatabaseUser = "electra_debug",
    
    [Parameter(HelpMessage="Database password")]
    [string]$DatabasePassword,
    
    [Parameter(HelpMessage="PostgreSQL admin user")]
    [string]$AdminUser = "postgres",
    
    [Parameter(HelpMessage="PostgreSQL host")]
    [string]$Host = "localhost",
    
    [Parameter(HelpMessage="PostgreSQL port")]
    [int]$Port = 5432,
    
    [Parameter(HelpMessage="Show help information")]
    [switch]$Help
)

function Show-Help {
    @"
Electra PostgreSQL Database Creation Script

DESCRIPTION:
    Creates a local PostgreSQL database and user for the Electra project.
    This script can be run standalone or as part of the main setup process.

USAGE:
    PowerShell -ExecutionPolicy Bypass -File setup/create_local_postgres_db.ps1 [parameters]

PARAMETERS:
    -DatabaseName <string>     Name of the database to create (default: electra_debug)
    -DatabaseUser <string>     Name of the database user to create (default: electra_debug)
    -DatabasePassword <string> Password for the database user (will prompt if not provided)
    -AdminUser <string>        PostgreSQL admin user (default: postgres)
    -Host <string>            PostgreSQL host (default: localhost)
    -Port <int>               PostgreSQL port (default: 5432)
    -Help                     Show this help information

EXAMPLES:
    # Create default debug database
    PowerShell -ExecutionPolicy Bypass -File setup/create_local_postgres_db.ps1
    
    # Create production database
    PowerShell -ExecutionPolicy Bypass -File setup/create_local_postgres_db.ps1 -DatabaseName electra_prod -DatabaseUser electra_prod
    
    # Create with custom parameters
    PowerShell -ExecutionPolicy Bypass -File setup/create_local_postgres_db.ps1 -DatabaseName mydb -DatabaseUser myuser -Host remote-host

PREREQUISITES:
    - PostgreSQL server installed and running
    - psql command-line tool available in PATH
    - Admin access to PostgreSQL server

"@
}

function Test-PostgreSQLAvailable {
    try {
        $null = Get-Command psql -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Test-PostgreSQLConnection {
    param(
        [string]$AdminUser,
        [string]$Host,
        [int]$Port
    )
    
    try {
        $result = psql -U $AdminUser -h $Host -p $Port -c "SELECT version();" -t 2>&1
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function New-PostgreSQLDatabase {
    param(
        [string]$DatabaseName,
        [string]$DatabaseUser,
        [string]$DatabasePassword,
        [string]$AdminUser,
        [string]$Host,
        [int]$Port
    )
    
    Write-Host "🔧 Creating PostgreSQL database and user..." -ForegroundColor Yellow
    Write-Host "  Database: $DatabaseName"
    Write-Host "  User: $DatabaseUser"
    Write-Host "  Host: $Host"
    Write-Host "  Port: $Port"
    Write-Host ""
    
    try {
        # Check if database already exists
        Write-Host "📋 Checking if database exists..." -ForegroundColor Cyan
        $dbExists = psql -U $AdminUser -h $Host -p $Port -lqt 2>$null | Select-String -Pattern "^\s*$DatabaseName\s"
        
        if ($dbExists) {
            Write-Host "ℹ️  Database '$DatabaseName' already exists" -ForegroundColor Blue
        } else {
            Write-Host "📦 Creating database '$DatabaseName'..." -ForegroundColor Yellow
            $result = psql -U $AdminUser -h $Host -p $Port -c "CREATE DATABASE `"$DatabaseName`";" 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Database '$DatabaseName' created successfully" -ForegroundColor Green
            } else {
                Write-Host "❌ Failed to create database: $result" -ForegroundColor Red
                return $false
            }
        }
        
        # Check if user already exists
        Write-Host "👤 Checking if user exists..." -ForegroundColor Cyan
        $userExists = psql -U $AdminUser -h $Host -p $Port -c "SELECT 1 FROM pg_roles WHERE rolname='$DatabaseUser';" -t 2>$null | Select-String -Pattern "1"
        
        if ($userExists) {
            Write-Host "ℹ️  User '$DatabaseUser' already exists" -ForegroundColor Blue
        } else {
            Write-Host "👤 Creating user '$DatabaseUser'..." -ForegroundColor Yellow
            $result = psql -U $AdminUser -h $Host -p $Port -c "CREATE USER `"$DatabaseUser`" WITH PASSWORD '$DatabasePassword';" 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ User '$DatabaseUser' created successfully" -ForegroundColor Green
            } else {
                Write-Host "❌ Failed to create user: $result" -ForegroundColor Red
                return $false
            }
        }
        
        # Grant privileges
        Write-Host "🔐 Granting privileges..." -ForegroundColor Yellow
        $result = psql -U $AdminUser -h $Host -p $Port -c "GRANT ALL PRIVILEGES ON DATABASE `"$DatabaseName`" TO `"$DatabaseUser`";" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Privileges granted successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Warning: Failed to grant privileges: $result" -ForegroundColor Yellow
        }
        
        # Create required extensions if needed
        Write-Host "🔧 Creating database extensions..." -ForegroundColor Yellow
        $extensions = @("uuid-ossp", "pgcrypto")
        
        foreach ($extension in $extensions) {
            $result = psql -U $AdminUser -h $Host -p $Port -d $DatabaseName -c "CREATE EXTENSION IF NOT EXISTS `"$extension`";" 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Extension '$extension' created" -ForegroundColor Green
            } else {
                Write-Host "⚠️  Warning: Could not create extension '$extension': $result" -ForegroundColor Yellow
            }
        }
        
        # Test connection with new user
        Write-Host "🔍 Testing database connection..." -ForegroundColor Cyan
        $env:PGPASSWORD = $DatabasePassword
        $testResult = psql -U $DatabaseUser -h $Host -p $Port -d $DatabaseName -c "SELECT current_database(), current_user;" -t 2>&1
        $env:PGPASSWORD = $null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Database connection test successful" -ForegroundColor Green
            Write-Host "   $($testResult.Trim())" -ForegroundColor Gray
        } else {
            Write-Host "⚠️  Warning: Database connection test failed: $testResult" -ForegroundColor Yellow
        }
        
        return $true
    }
    catch {
        Write-Host "❌ Error during database creation: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Write-Host "🐘 Electra PostgreSQL Database Setup" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

# Check if PostgreSQL tools are available
if (-not (Test-PostgreSQLAvailable)) {
    Write-Host "❌ PostgreSQL command-line tools (psql) not found in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install PostgreSQL and ensure psql is available:" -ForegroundColor Yellow
    Write-Host "1. Download PostgreSQL from: https://www.postgresql.org/download/windows/" -ForegroundColor Yellow
    Write-Host "2. Install PostgreSQL with default settings" -ForegroundColor Yellow
    Write-Host "3. Add PostgreSQL bin directory to your PATH" -ForegroundColor Yellow
    Write-Host "4. Restart PowerShell and try again" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ PostgreSQL tools found" -ForegroundColor Green

# Test PostgreSQL connection
Write-Host "🔍 Testing PostgreSQL connection..." -ForegroundColor Cyan
if (-not (Test-PostgreSQLConnection -AdminUser $AdminUser -Host $Host -Port $Port)) {
    Write-Host "❌ Cannot connect to PostgreSQL server" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure:" -ForegroundColor Yellow
    Write-Host "1. PostgreSQL server is running" -ForegroundColor Yellow
    Write-Host "2. Connection parameters are correct:" -ForegroundColor Yellow
    Write-Host "   - Host: $Host" -ForegroundColor Yellow
    Write-Host "   - Port: $Port" -ForegroundColor Yellow
    Write-Host "   - Admin User: $AdminUser" -ForegroundColor Yellow
    Write-Host "3. You have permission to connect as '$AdminUser'" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ PostgreSQL server is accessible" -ForegroundColor Green

# Get password if not provided
if (-not $DatabasePassword) {
    $DatabasePassword = Read-Host -Prompt "Enter password for database user '$DatabaseUser'" -AsSecureString
    $DatabasePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($DatabasePassword))
    
    if (-not $DatabasePassword) {
        Write-Host "❌ Password is required" -ForegroundColor Red
        exit 1
    }
}

# Create database and user
$success = New-PostgreSQLDatabase -DatabaseName $DatabaseName -DatabaseUser $DatabaseUser -DatabasePassword $DatabasePassword -AdminUser $AdminUser -Host $Host -Port $Port

if ($success) {
    Write-Host ""
    Write-Host "🎉 Database setup completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Connection details:" -ForegroundColor Cyan
    Write-Host "  Database: $DatabaseName"
    Write-Host "  User: $DatabaseUser" 
    Write-Host "  Host: $Host"
    Write-Host "  Port: $Port"
    Write-Host "  Connection URL: postgresql://$DatabaseUser:[PASSWORD]@${Host}:$Port/$DatabaseName"
    Write-Host ""
    Write-Host "You can now use this database in your .env file:" -ForegroundColor Yellow
    Write-Host "DATABASE_URL=postgresql://$DatabaseUser:[PASSWORD]@${Host}:$Port/$DatabaseName" -ForegroundColor Gray
    exit 0
} else {
    Write-Host ""
    Write-Host "❌ Database setup failed" -ForegroundColor Red
    Write-Host "Please check the error messages above and try again." -ForegroundColor Yellow
    exit 1
}