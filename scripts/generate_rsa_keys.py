#!/usr/bin/env python3
"""
RSA Key Generation Script for JWT Signing

This script generates RSA public/private key pairs for JWT token signing.
The keys are stored in the keys/ directory and should be kept secure.

Usage:
    python scripts/generate_rsa_keys.py [--key-size 4096] [--output-dir keys/]

Key Rotation Procedure:
1. Generate new key pair with this script
2. Update environment variables to point to new keys
3. Restart the application
4. Old keys can be kept for a grace period to verify existing tokens
5. Remove old keys after grace period expires

Security Notes:
- Private keys should never be committed to version control
- Keys should be stored with appropriate file permissions (600)
- Consider using hardware security modules (HSM) for production
- Regularly rotate keys (recommended: every 6-12 months)
"""

import os
import sys
import argparse
from pathlib import Path
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend


def generate_rsa_keypair(key_size=4096):
    """
    Generate RSA public/private key pair.
    
    Args:
        key_size (int): RSA key size in bits (default: 4096)
    
    Returns:
        tuple: (private_key, public_key) objects
    """
    print(f"Generating {key_size}-bit RSA key pair...")
    
    # Generate private key
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=key_size,
        backend=default_backend()
    )
    
    # Get public key from private key
    public_key = private_key.public_key()
    
    return private_key, public_key


def save_keys(private_key, public_key, output_dir="keys"):
    """
    Save RSA keys to PEM files.
    
    Args:
        private_key: RSA private key object
        public_key: RSA public key object
        output_dir (str): Directory to save keys
    """
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)
    
    # Private key file
    private_key_path = output_path / "private_key.pem"
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    
    # Public key file
    public_key_path = output_path / "public_key.pem"
    public_pem = public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )
    
    # Write private key
    with open(private_key_path, 'wb') as f:
        f.write(private_pem)
    
    # Write public key
    with open(public_key_path, 'wb') as f:
        f.write(public_pem)
    
    # Set secure file permissions (Unix-like systems)
    if hasattr(os, 'chmod'):
        os.chmod(private_key_path, 0o600)  # Read/write for owner only
        os.chmod(public_key_path, 0o644)   # Read for everyone, write for owner
    
    print(f"Keys saved:")
    print(f"  Private key: {private_key_path}")
    print(f"  Public key:  {public_key_path}")
    
    return private_key_path, public_key_path


def verify_keys(private_key_path, public_key_path):
    """
    Verify that the generated keys are valid and can be loaded.
    
    Args:
        private_key_path: Path to private key file
        public_key_path: Path to public key file
    """
    try:
        # Load private key
        with open(private_key_path, 'rb') as f:
            private_pem = f.read()
        
        private_key = serialization.load_pem_private_key(
            private_pem,
            password=None,
            backend=default_backend()
        )
        
        # Load public key
        with open(public_key_path, 'rb') as f:
            public_pem = f.read()
        
        public_key = serialization.load_pem_public_key(
            public_pem,
            backend=default_backend()
        )
        
        # Verify key sizes match
        private_key_size = private_key.key_size
        public_key_size = public_key.key_size
        
        if private_key_size != public_key_size:
            raise ValueError(f"Key size mismatch: private={private_key_size}, public={public_key_size}")
        
        print(f"✓ Key verification successful ({private_key_size} bits)")
        return True
        
    except Exception as e:
        print(f"✗ Key verification failed: {e}")
        return False


def create_gitignore(output_dir):
    """
    Create .gitignore file in keys directory to prevent accidental commits.
    
    Args:
        output_dir (str): Directory containing keys
    """
    gitignore_path = Path(output_dir) / ".gitignore"
    gitignore_content = """# RSA Keys - DO NOT COMMIT
*.pem
*.key
private_key*
public_key*

# Keep this directory structure
!.gitignore
"""
    
    with open(gitignore_path, 'w') as f:
        f.write(gitignore_content)
    
    print(f"Created .gitignore in {output_dir}")


def main():
    """Main function."""
    parser = argparse.ArgumentParser(
        description="Generate RSA keys for JWT signing",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Security Guidelines:
1. Never commit private keys to version control
2. Store keys with secure file permissions
3. Use environment variables to reference key paths
4. Rotate keys regularly (every 6-12 months)
5. Consider using HSM or key management services in production

Example usage:
    python scripts/generate_rsa_keys.py
    python scripts/generate_rsa_keys.py --key-size 2048 --output-dir /secure/keys/
        """
    )
    
    parser.add_argument(
        '--key-size',
        type=int,
        default=4096,
        help='RSA key size in bits (default: 4096)'
    )
    
    parser.add_argument(
        '--output-dir',
        type=str,
        default='keys',
        help='Directory to save keys (default: keys/)'
    )
    
    parser.add_argument(
        '--force',
        action='store_true',
        help='Overwrite existing keys without prompting'
    )
    
    args = parser.parse_args()
    
    # Validate key size
    if args.key_size < 2048:
        print("Error: Key size must be at least 2048 bits for security")
        sys.exit(1)
    
    output_path = Path(args.output_dir)
    private_key_path = output_path / "private_key.pem"
    public_key_path = output_path / "public_key.pem"
    
    # Check if keys already exist
    if (private_key_path.exists() or public_key_path.exists()) and not args.force:
        response = input(f"Keys already exist in {args.output_dir}. Overwrite? [y/N]: ")
        if response.lower() != 'y':
            print("Key generation cancelled.")
            sys.exit(0)
    
    try:
        # Generate keys
        private_key, public_key = generate_rsa_keypair(args.key_size)
        
        # Save keys
        saved_private_path, saved_public_path = save_keys(
            private_key, public_key, args.output_dir
        )
        
        # Verify keys
        if verify_keys(saved_private_path, saved_public_path):
            print("✓ RSA key generation completed successfully!")
        else:
            print("✗ Key generation completed but verification failed!")
            sys.exit(1)
        
        # Create .gitignore to prevent accidental commits
        create_gitignore(args.output_dir)
        
        print("\nNext steps:")
        print("1. Update your .env file with the key paths:")
        print(f"   RSA_PRIVATE_KEY_PATH={saved_private_path}")
        print(f"   RSA_PUBLIC_KEY_PATH={saved_public_path}")
        print("2. Restart your application")
        print("3. Test JWT token generation/verification")
        print("\n⚠️  IMPORTANT: Never commit these keys to version control!")
        
    except Exception as e:
        print(f"Error generating keys: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()