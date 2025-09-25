#!/usr/bin/env python3
"""
Audit log integrity verification script for Electra.
Verifies the cryptographic signatures of audit log entries.
"""
import argparse
import json
import sys
from datetime import datetime, timedelta
from pathlib import Path
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.backends import default_backend


class AuditLogVerifier:
    """Verifies the integrity of Electra audit logs."""
    
    def __init__(self, public_key_path: str, log_directory: str):
        self.public_key = self._load_public_key(public_key_path)
        self.log_directory = Path(log_directory)
    
    def _load_public_key(self, key_path: str):
        """Load the RSA public key for verification."""
        try:
            with open(key_path, 'rb') as f:
                return serialization.load_pem_public_key(
                    f.read(),
                    backend=default_backend()
                )
        except Exception as e:
            print(f"Error loading public key: {e}")
            sys.exit(1)
    
    def verify_log_file(self, log_file: Path) -> tuple[bool, int, int]:
        """
        Verify a single log file.
        Returns (success, total_entries, verified_entries)
        """
        if not log_file.exists():
            print(f"Log file not found: {log_file}")
            return False, 0, 0
        
        total_entries = 0
        verified_entries = 0
        
        try:
            with open(log_file, 'r', encoding='utf-8') as f:
                for line_num, line in enumerate(f, 1):
                    total_entries += 1
                    line = line.strip()
                    
                    if not line:
                        continue
                    
                    try:
                        entry = json.loads(line)
                        
                        if self._verify_entry(entry):
                            verified_entries += 1
                        else:
                            print(f"❌ Verification failed for entry at line {line_num}")
                            print(f"   Entry ID: {entry.get('id', 'unknown')}")
                            print(f"   Timestamp: {entry.get('timestamp', 'unknown')}")
                    
                    except json.JSONDecodeError as e:
                        print(f"❌ JSON decode error at line {line_num}: {e}")
                    except Exception as e:
                        print(f"❌ Error verifying entry at line {line_num}: {e}")
        
        except Exception as e:
            print(f"Error reading log file {log_file}: {e}")
            return False, 0, 0
        
        return verified_entries == total_entries, total_entries, verified_entries
    
    def _verify_entry(self, entry: dict) -> bool:
        """Verify a single audit log entry."""
        try:
            # Extract signature and signed_at
            signature = entry.pop('signature', None)
            signed_at = entry.pop('signed_at', None)
            
            if not signature:
                print("❌ Missing signature in entry")
                return False
            
            # Recreate the entry JSON for verification
            entry_json = json.dumps(entry, sort_keys=True)
            
            # Verify the signature
            self.public_key.verify(
                bytes.fromhex(signature),
                entry_json.encode(),
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA256()
            )
            
            return True
            
        except Exception as e:
            print(f"❌ Signature verification failed: {e}")
            return False
    
    def verify_date_range(self, start_date: str, end_date: str) -> dict:
        """Verify audit logs for a date range."""
        start = datetime.strptime(start_date, '%Y-%m-%d')
        end = datetime.strptime(end_date, '%Y-%m-%d')
        
        results = {
            'total_files': 0,
            'verified_files': 0,
            'total_entries': 0,
            'verified_entries': 0,
            'failed_files': []
        }
        
        current_date = start
        while current_date <= end:
            date_str = current_date.strftime('%Y-%m-%d')
            log_file = self.log_directory / f'audit-{date_str}.jsonl'
            
            if log_file.exists():
                results['total_files'] += 1
                success, total, verified = self.verify_log_file(log_file)
                
                results['total_entries'] += total
                results['verified_entries'] += verified
                
                if success:
                    results['verified_files'] += 1
                    print(f"✅ {date_str}: {verified}/{total} entries verified")
                else:
                    results['failed_files'].append(date_str)
                    print(f"❌ {date_str}: {verified}/{total} entries verified")
            
            current_date += timedelta(days=1)
        
        return results
    
    def generate_report(self, results: dict) -> str:
        """Generate a verification report."""
        report = []
        report.append("=" * 60)
        report.append("ELECTRA AUDIT LOG VERIFICATION REPORT")
        report.append("=" * 60)
        report.append(f"Generated at: {datetime.now().isoformat()}")
        report.append("")
        
        report.append("SUMMARY:")
        report.append(f"  Total log files: {results['total_files']}")
        report.append(f"  Verified files: {results['verified_files']}")
        report.append(f"  Failed files: {len(results['failed_files'])}")
        report.append("")
        
        report.append(f"  Total log entries: {results['total_entries']}")
        report.append(f"  Verified entries: {results['verified_entries']}")
        report.append(f"  Failed entries: {results['total_entries'] - results['verified_entries']}")
        report.append("")
        
        if results['failed_files']:
            report.append("FAILED FILES:")
            for failed_file in results['failed_files']:
                report.append(f"  - {failed_file}")
            report.append("")
        
        # Overall status
        if results['verified_files'] == results['total_files'] and results['verified_entries'] == results['total_entries']:
            report.append("✅ OVERALL STATUS: ALL LOGS VERIFIED SUCCESSFULLY")
        else:
            report.append("❌ OVERALL STATUS: VERIFICATION FAILURES DETECTED")
        
        report.append("=" * 60)
        
        return "\n".join(report)


def main():
    parser = argparse.ArgumentParser(description='Verify Electra audit log integrity')
    parser.add_argument('--public-key', required=True, 
                       help='Path to RSA public key file')
    parser.add_argument('--log-dir', required=True,
                       help='Path to audit logs directory')
    parser.add_argument('--date', 
                       help='Specific date to verify (YYYY-MM-DD)')
    parser.add_argument('--start-date',
                       help='Start date for range verification (YYYY-MM-DD)')
    parser.add_argument('--end-date',
                       help='End date for range verification (YYYY-MM-DD)')
    parser.add_argument('--report-file',
                       help='Path to save verification report')
    parser.add_argument('--quiet', action='store_true',
                       help='Suppress verbose output')
    
    args = parser.parse_args()
    
    # Initialize verifier
    verifier = AuditLogVerifier(args.public_key, args.log_dir)
    
    if args.date:
        # Verify single date
        log_file = Path(args.log_dir) / f'audit-{args.date}.jsonl'
        success, total, verified = verifier.verify_log_file(log_file)
        
        if not args.quiet:
            if success:
                print(f"✅ {args.date}: All {total} entries verified successfully")
            else:
                print(f"❌ {args.date}: {verified}/{total} entries verified")
        
        sys.exit(0 if success else 1)
    
    elif args.start_date and args.end_date:
        # Verify date range
        results = verifier.verify_date_range(args.start_date, args.end_date)
        
        # Generate report
        report = verifier.generate_report(results)
        
        if not args.quiet:
            print(report)
        
        # Save report if requested
        if args.report_file:
            with open(args.report_file, 'w') as f:
                f.write(report)
            print(f"\nReport saved to: {args.report_file}")
        
        # Exit with appropriate code
        all_verified = (results['verified_files'] == results['total_files'] and 
                       results['verified_entries'] == results['total_entries'])
        sys.exit(0 if all_verified else 1)
    
    else:
        # Verify last 7 days by default
        end_date = datetime.now().strftime('%Y-%m-%d')
        start_date = (datetime.now() - timedelta(days=7)).strftime('%Y-%m-%d')
        
        print(f"Verifying audit logs from {start_date} to {end_date}")
        
        results = verifier.verify_date_range(start_date, end_date)
        report = verifier.generate_report(results)
        
        if not args.quiet:
            print(report)
        
        all_verified = (results['verified_files'] == results['total_files'] and 
                       results['verified_entries'] == results['total_entries'])
        sys.exit(0 if all_verified else 1)


if __name__ == '__main__':
    main()