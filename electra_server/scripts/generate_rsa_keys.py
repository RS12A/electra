#!/usr/bin/env python3
"""
RSA Key Generation Script for Electra Server.
Generates secure 4096-bit RSA key pairs for digital signatures.

Usage: python scripts/generate_rsa_keys.py
"""

import os
import sys
import argparse
from pathlib import Path
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend


def generate_rsa_keys(key_size=4096, keys_dir="keys"):
    """
    Generate RSA key pair with specified key size.
    
    Args:
        key_size (int): RSA key size in bits (default: 4096)
        keys_dir (str): Directory to store keys (default: keys)
    """
    
    print(f"🔐 Generating {key_size}-bit RSA key pair...")
    
    # Create keys directory if it doesn't exist
    keys_path = Path(keys_dir)
    keys_path.mkdir(mode=0o700, exist_ok=True)
    
    private_key_path = keys_path / "private.pem"
    public_key_path = keys_path / "public.pem"
    
    # Check if keys already exist
    if private_key_path.exists() or public_key_path.exists():
        print("⚠️  RSA keys already exist!")
        response = input("Do you want to overwrite them? (y/N): ").lower()
        if response != 'y':
            print("❌ Operation cancelled.")
            return False
        
        # Backup existing keys
        if private_key_path.exists():
            backup_path = keys_path / f"private.pem.backup.{os.getpid()}"
            private_key_path.rename(backup_path)
            print(f"📦 Backed up existing private key to {backup_path}")
        
        if public_key_path.exists():
            backup_path = keys_path / f"public.pem.backup.{os.getpid()}"
            public_key_path.rename(backup_path)
            print(f"📦 Backed up existing public key to {backup_path}")
    
    try:
        # Generate private key
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=key_size,
            backend=default_backend()
        )
        
        # Get public key
        public_key = private_key.public_key()
        
        # Serialize private key
        private_pem = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        )
        
        # Serialize public key
        public_pem = public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
        
        # Write private key
        with open(private_key_path, 'wb') as f:
            f.write(private_pem)
        
        # Set restrictive permissions on private key
        os.chmod(private_key_path, 0o600)
        
        # Write public key
        with open(public_key_path, 'wb') as f:
            f.write(public_pem)
        
        # Set appropriate permissions on public key
        os.chmod(public_key_path, 0o644)
        
        print(f"✅ RSA key pair generated successfully!")
        print(f"🔑 Private key: {private_key_path} (permissions: 600)")
        print(f"🔓 Public key:  {public_key_path} (permissions: 644)")
        
        # Display key fingerprints
        private_key_fingerprint = hash(private_pem) & 0xFFFFFFFF
        public_key_fingerprint = hash(public_pem) & 0xFFFFFFFF
        
        print(f"🔍 Private key fingerprint: {private_key_fingerprint:08X}")
        print(f"🔍 Public key fingerprint:  {public_key_fingerprint:08X}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error generating RSA keys: {e}")
        return False


def validate_keys(keys_dir="keys"):
    """
    Validate that RSA keys exist and are properly formatted.
    
    Args:
        keys_dir (str): Directory containing keys
    """
    
    print("🔍 Validating RSA keys...")
    
    keys_path = Path(keys_dir)
    private_key_path = keys_path / "private.pem"
    public_key_path = keys_path / "public.pem"
    
    if not private_key_path.exists():
        print(f"❌ Private key not found: {private_key_path}")
        return False
    
    if not public_key_path.exists():
        print(f"❌ Public key not found: {public_key_path}")
        return False
    
    try:
        # Load and validate private key
        with open(private_key_path, 'rb') as f:
            private_key = serialization.load_pem_private_key(
                f.read(),
                password=None,
                backend=default_backend()
            )
        
        # Load and validate public key
        with open(public_key_path, 'rb') as f:
            public_key = serialization.load_pem_public_key(
                f.read(),
                backend=default_backend()
            )
        
        # Verify key pair match
        private_public_key = private_key.public_key()
        
        # Compare public key numbers
        if (private_public_key.public_numbers().n == public_key.public_numbers().n and
            private_public_key.public_numbers().e == public_key.public_numbers().e):
            
            key_size = private_key.key_size
            print(f"✅ RSA key pair is valid ({key_size}-bit)")
            print(f"🔑 Private key: {private_key_path}")
            print(f"🔓 Public key:  {public_key_path}")
            
            # Check file permissions
            private_perms = oct(os.stat(private_key_path).st_mode)[-3:]
            public_perms = oct(os.stat(public_key_path).st_mode)[-3:]
            
            print(f"🔒 File permissions: private ({private_perms}), public ({public_perms})")
            
            if private_perms != '600':
                print("⚠️  Warning: Private key should have 600 permissions")
            
            return True
        else:
            print("❌ Private and public keys do not match!")
            return False
            
    except Exception as e:
        print(f"❌ Error validating keys: {e}")
        return False


def print_security_notes():
    """Print important security notes about key management."""
    
    print("\n" + "="*60)
    print("🔐 IMPORTANT SECURITY NOTES")
    print("="*60)
    print("1. Private key (private.pem) should never be shared or committed to version control")
    print("2. Private key has restrictive permissions (600) - only owner can read/write")
    print("3. Public key (public.pem) can be shared and has standard permissions (644)")
    print("4. Store private key backups in a secure location")
    print("5. Rotate keys regularly according to your security policy")
    print("6. For production, consider using hardware security modules (HSM)")
    print("\n🔄 Key Rotation Procedure:")
    print("   1. Generate new key pair with this script")
    print("   2. Update application configuration")
    print("   3. Restart application services")
    print("   4. Securely delete old private key")
    print("   5. Update any systems that use the public key")
    print("="*60)


def main():
    """Main function."""
    
    parser = argparse.ArgumentParser(
        description='Generate RSA key pairs for Electra Server digital signatures'
    )
    
    parser.add_argument(
        '--key-size',
        type=int,
        default=4096,
        choices=[2048, 3072, 4096],
        help='RSA key size in bits (default: 4096)'
    )
    
    parser.add_argument(
        '--keys-dir',
        type=str,
        default='keys',
        help='Directory to store keys (default: keys)'
    )
    
    parser.add_argument(
        '--validate',
        action='store_true',
        help='Validate existing keys instead of generating new ones'
    )
    
    parser.add_argument(
        '--force',
        action='store_true',
        help='Force overwrite existing keys without prompting'
    )
    
    args = parser.parse_args()
    
    if args.validate:
        success = validate_keys(args.keys_dir)
        sys.exit(0 if success else 1)
    
    # Set force flag for non-interactive mode
    if args.force:
        # Temporarily override input to always return 'y'
        import builtins
        builtins.input = lambda _: 'y'
    
    success = generate_rsa_keys(args.key_size, args.keys_dir)
    
    if success:
        print_security_notes()
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == '__main__':
    main()