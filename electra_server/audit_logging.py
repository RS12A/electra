"""
Tamper-proof audit logging system for Electra.
Creates immutable, signed audit logs for security-critical events.
"""
import json
import hashlib
import logging
import uuid
from datetime import datetime, timezone
from typing import Dict, Any, Optional
from pathlib import Path
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.backends import default_backend
from django.conf import settings
from django.utils import timezone as django_timezone

logger = logging.getLogger(__name__)


class TamperProofAuditLogger:
    """
    Tamper-proof audit logger that creates signed, immutable log entries.
    """
    
    def __init__(self):
        self.private_key = None
        self.public_key = None
        self.log_directory = Path(settings.BASE_DIR) / 'audit_logs'
        self.log_directory.mkdir(exist_ok=True)
        self._load_or_generate_keys()
    
    def _load_or_generate_keys(self):
        """Load existing RSA key pair or generate new ones."""
        private_key_path = Path(settings.BASE_DIR) / 'keys' / 'audit_private.pem'
        public_key_path = Path(settings.BASE_DIR) / 'keys' / 'audit_public.pem'
        
        # Create keys directory if it doesn't exist
        private_key_path.parent.mkdir(exist_ok=True)
        
        try:
            if private_key_path.exists() and public_key_path.exists():
                # Load existing keys
                with open(private_key_path, 'rb') as f:
                    self.private_key = serialization.load_pem_private_key(
                        f.read(),
                        password=None,
                        backend=default_backend()
                    )
                
                with open(public_key_path, 'rb') as f:
                    self.public_key = serialization.load_pem_public_key(
                        f.read(),
                        backend=default_backend()
                    )
                logger.info("Loaded existing RSA key pair for audit logging")
            else:
                # Generate new key pair
                self._generate_key_pair(private_key_path, public_key_path)
                logger.info("Generated new RSA key pair for audit logging")
        except Exception as e:
            logger.error(f"Failed to load/generate RSA keys: {e}")
            raise
    
    def _generate_key_pair(self, private_path: Path, public_path: Path):
        """Generate new RSA key pair for signing."""
        # Generate private key
        self.private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
            backend=default_backend()
        )
        
        # Get public key
        self.public_key = self.private_key.public_key()
        
        # Save private key
        private_pem = self.private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        )
        
        with open(private_path, 'wb') as f:
            f.write(private_pem)
        
        # Save public key
        public_pem = self.public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
        
        with open(public_path, 'wb') as f:
            f.write(public_pem)
        
        # Set secure permissions
        private_path.chmod(0o600)
        public_path.chmod(0o644)
    
    def _create_log_entry(self, event_type: str, data: Dict[str, Any], 
                         user_id: Optional[str] = None) -> Dict[str, Any]:
        """Create a structured audit log entry."""
        entry = {
            'id': str(uuid.uuid4()),
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'event_type': event_type,
            'user_id': user_id,
            'data': data,
            'version': '1.0',
            'system': 'electra'
        }
        
        # Add data integrity hash
        entry_json = json.dumps(entry, sort_keys=True)
        entry['content_hash'] = hashlib.sha256(entry_json.encode()).hexdigest()
        
        return entry
    
    def _sign_entry(self, entry: Dict[str, Any]) -> str:
        """Sign the audit log entry with RSA private key."""
        try:
            entry_json = json.dumps(entry, sort_keys=True)
            signature = self.private_key.sign(
                entry_json.encode(),
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA256()
            )
            return signature.hex()
        except Exception as e:
            logger.error(f"Failed to sign audit entry: {e}")
            raise
    
    def _write_log_entry(self, entry: Dict[str, Any], signature: str):
        """Write signed audit entry to immutable log file."""
        # Create daily log file
        date_str = datetime.now().strftime('%Y-%m-%d')
        log_file = self.log_directory / f'audit-{date_str}.jsonl'
        
        # Prepare final log entry with signature
        final_entry = {
            **entry,
            'signature': signature,
            'signed_at': datetime.now(timezone.utc).isoformat()
        }
        
        try:
            # Append to log file (append-only)
            with open(log_file, 'a', encoding='utf-8') as f:
                f.write(json.dumps(final_entry) + '\n')
            
            # Set file to read-only after first write
            if log_file.stat().st_size == len(json.dumps(final_entry)) + 1:
                log_file.chmod(0o444)  # Read-only
            
        except Exception as e:
            logger.error(f"Failed to write audit log entry: {e}")
            raise
    
    def log_vote_cast(self, election_id: str, voter_id: str, 
                     ballot_hash: str, timestamp: Optional[datetime] = None):
        """Log a vote casting event."""
        data = {
            'election_id': election_id,
            'voter_id': self._anonymize_voter_id(voter_id),
            'ballot_hash': ballot_hash,
            'cast_timestamp': (timestamp or django_timezone.now()).isoformat(),
            'event_category': 'voting',
            'security_level': 'critical'
        }
        
        entry = self._create_log_entry('vote_cast', data, voter_id)
        signature = self._sign_entry(entry)
        self._write_log_entry(entry, signature)
        
        logger.info(f"Audit log created for vote cast: {entry['id']}")
    
    def log_election_event(self, event_type: str, election_id: str, 
                          admin_user_id: str, details: Dict[str, Any]):
        """Log election management events."""
        data = {
            'election_id': election_id,
            'admin_user_id': admin_user_id,
            'details': details,
            'event_category': 'election_management',
            'security_level': 'high'
        }
        
        entry = self._create_log_entry(f'election_{event_type}', data, admin_user_id)
        signature = self._sign_entry(entry)
        self._write_log_entry(entry, signature)
        
        logger.info(f"Audit log created for election event: {entry['id']}")
    
    def log_security_event(self, event_type: str, user_id: Optional[str], 
                          source_ip: str, details: Dict[str, Any]):
        """Log security-related events."""
        data = {
            'source_ip': self._anonymize_ip(source_ip),
            'user_id': user_id,
            'details': details,
            'event_category': 'security',
            'security_level': 'critical'
        }
        
        entry = self._create_log_entry(f'security_{event_type}', data, user_id)
        signature = self._sign_entry(entry)
        self._write_log_entry(entry, signature)
        
        logger.warning(f"Security audit log created: {entry['id']}")
    
    def log_data_access(self, resource_type: str, resource_id: str, 
                       user_id: str, action: str, result: str):
        """Log data access events."""
        data = {
            'resource_type': resource_type,
            'resource_id': resource_id,
            'action': action,
            'result': result,
            'event_category': 'data_access',
            'security_level': 'medium'
        }
        
        entry = self._create_log_entry('data_access', data, user_id)
        signature = self._sign_entry(entry)
        self._write_log_entry(entry, signature)
    
    def _anonymize_voter_id(self, voter_id: str) -> str:
        """Anonymize voter ID for privacy while maintaining uniqueness."""
        # Use SHA-256 hash with salt for anonymization
        salt = "electra_audit_salt_2024"
        return hashlib.sha256(f"{voter_id}{salt}".encode()).hexdigest()[:16]
    
    def _anonymize_ip(self, ip_address: str) -> str:
        """Anonymize IP address for privacy."""
        if ':' in ip_address:  # IPv6
            parts = ip_address.split(':')
            return ':'.join(parts[:4] + ['xxxx'] * (len(parts) - 4))
        else:  # IPv4
            parts = ip_address.split('.')
            return '.'.join(parts[:3] + ['xxx'])
    
    def verify_log_integrity(self, log_date: str) -> bool:
        """Verify the integrity of audit logs for a specific date."""
        log_file = self.log_directory / f'audit-{log_date}.jsonl'
        
        if not log_file.exists():
            logger.error(f"Audit log file not found: {log_file}")
            return False
        
        try:
            with open(log_file, 'r', encoding='utf-8') as f:
                for line_num, line in enumerate(f, 1):
                    entry = json.loads(line.strip())
                    
                    # Verify signature
                    signature = entry.pop('signature')
                    signed_at = entry.pop('signed_at')
                    
                    entry_json = json.dumps(entry, sort_keys=True)
                    
                    try:
                        self.public_key.verify(
                            bytes.fromhex(signature),
                            entry_json.encode(),
                            padding.PSS(
                                mgf=padding.MGF1(hashes.SHA256()),
                                salt_length=padding.PSS.MAX_LENGTH
                            ),
                            hashes.SHA256()
                        )
                    except Exception as e:
                        logger.error(f"Signature verification failed for line {line_num}: {e}")
                        return False
            
            logger.info(f"Audit log integrity verified for {log_date}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to verify audit log integrity: {e}")
            return False


# Global audit logger instance
audit_logger = TamperProofAuditLogger()