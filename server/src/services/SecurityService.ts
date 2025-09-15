import jwt from 'jsonwebtoken';
import argon2 from 'argon2';
import crypto from 'crypto';
import { User, UserRole } from '../types/prisma';
import { LoggerService } from './LoggerService';
import fs from 'fs';
import path from 'path';

interface JwtPayload {
  id: string;
  matricNumber: string;
  role: UserRole;
  iat?: number;
  exp?: number;
}

interface VoteEncryption {
  encryptedData: string;
  signature: string;
  publicKey: string;
}

export class SecurityService {
  private static logger: LoggerService = new LoggerService();
  private static privateKey: string | null = null;
  private static publicKey: string | null = null;

  static async initialize() {
    try {
      await this.loadRSAKeys();
      this.logger.info('Security service initialized');
    } catch (error) {
      this.logger.error('Security service initialization failed:', error);
      throw error;
    }
  }

  private static async loadRSAKeys() {
    const privateKeyPath = process.env.VOTE_SIGNING_PRIVATE_KEY_PATH || './keys/private.pem';
    const publicKeyPath = process.env.VOTE_SIGNING_PUBLIC_KEY_PATH || './keys/public.pem';

    try {
      if (fs.existsSync(privateKeyPath) && fs.existsSync(publicKeyPath)) {
        this.privateKey = fs.readFileSync(privateKeyPath, 'utf8');
        this.publicKey = fs.readFileSync(publicKeyPath, 'utf8');
        this.logger.info('RSA keys loaded successfully');
      } else {
        this.logger.warn('RSA keys not found, generating new keys...');
        await this.generateRSAKeys();
      }
    } catch (error) {
      this.logger.error('Failed to load RSA keys:', error);
      throw error;
    }
  }

  static async generateRSAKeys() {
    return new Promise<void>((resolve, reject) => {
      crypto.generateKeyPair('rsa', {
        modulusLength: 4096,
        publicKeyEncoding: {
          type: 'spki',
          format: 'pem'
        },
        privateKeyEncoding: {
          type: 'pkcs8',
          format: 'pem'
        }
      }, (err, publicKey, privateKey) => {
        if (err) {
          this.logger.error('RSA key generation failed:', err);
          reject(err);
          return;
        }

        try {
          // Ensure keys directory exists
          const keysDir = path.dirname(process.env.VOTE_SIGNING_PRIVATE_KEY_PATH || './keys/private.pem');
          if (!fs.existsSync(keysDir)) {
            fs.mkdirSync(keysDir, { recursive: true });
          }

          // Save keys to files
          fs.writeFileSync(process.env.VOTE_SIGNING_PRIVATE_KEY_PATH || './keys/private.pem', privateKey);
          fs.writeFileSync(process.env.VOTE_SIGNING_PUBLIC_KEY_PATH || './keys/public.pem', publicKey);

          this.privateKey = privateKey;
          this.publicKey = publicKey;

          this.logger.info('RSA keys generated and saved successfully');
          resolve();
        } catch (error) {
          this.logger.error('Failed to save RSA keys:', error);
          reject(error);
        }
      });
    });
  }

  // Password hashing
  static async hashPassword(password: string): Promise<string> {
    try {
      return await argon2.hash(password, {
        type: argon2.argon2id,
        memoryCost: 65536, // 64 MB
        timeCost: 3,
        parallelism: 4,
      });
    } catch (error) {
      this.logger.error('Password hashing failed:', error);
      throw new Error('Password hashing failed');
    }
  }

  static async verifyPassword(hashedPassword: string, plainPassword: string): Promise<boolean> {
    try {
      return await argon2.verify(hashedPassword, plainPassword);
    } catch (error) {
      this.logger.error('Password verification failed:', error);
      return false;
    }
  }

  // JWT token management
  static generateJwtToken(user: User): string {
    const payload: JwtPayload = {
      id: user.id,
      matricNumber: user.matricNumber,
      role: user.role,
    };

    const secret = process.env.JWT_SECRET;
    if (!secret) {
      throw new Error('JWT_SECRET environment variable is required');
    }

    return jwt.sign(payload, secret, {
      expiresIn: process.env.JWT_ACCESS_TOKEN_EXPIRY || '15m',
    } as jwt.SignOptions);
  }

  static generateRefreshToken(user: User): string {
    const payload: JwtPayload = {
      id: user.id,
      matricNumber: user.matricNumber,
      role: user.role,
    };

    const secret = process.env.JWT_REFRESH_SECRET;
    if (!secret) {
      throw new Error('JWT_REFRESH_SECRET environment variable is required');
    }

    return jwt.sign(payload, secret, {
      expiresIn: process.env.JWT_REFRESH_TOKEN_EXPIRY || '7d',
    } as jwt.SignOptions);
  }

  static async verifyJwtToken(token: string): Promise<JwtPayload> {
    try {
      return jwt.verify(token, process.env.JWT_SECRET!) as JwtPayload;
    } catch (error) {
      throw new Error('Invalid or expired token');
    }
  }

  static async verifyRefreshToken(token: string): Promise<JwtPayload> {
    try {
      return jwt.verify(token, process.env.JWT_REFRESH_SECRET!) as JwtPayload;
    } catch (error) {
      throw new Error('Invalid or expired refresh token');
    }
  }

  // Vote encryption and signing
  static encryptVote(voteData: object): VoteEncryption {
    if (!this.publicKey || !this.privateKey) {
      throw new Error('RSA keys not loaded');
    }

    try {
      // Convert vote data to JSON string
      const voteJson = JSON.stringify(voteData);

      // Generate AES key and IV for this vote
      const aesKey = Buffer.from(process.env.VOTE_ENCRYPTION_KEY!, 'hex');
      const iv = crypto.randomBytes(16);

      // Encrypt vote with AES-256-GCM
      const cipher = crypto.createCipheriv('aes-256-gcm', aesKey, iv);
      let encrypted = cipher.update(voteJson, 'utf8', 'hex');
      encrypted += cipher.final('hex');
      const authTag = cipher.getAuthTag();

      const encryptedData = {
        data: encrypted,
        iv: iv.toString('hex'),
        authTag: authTag.toString('hex'),
      };

      // Sign the encrypted data with RSA private key
      const sign = crypto.createSign('sha512');
      sign.update(JSON.stringify(encryptedData));
      const signatureHex = sign.sign(this.privateKey, 'hex');

      return {
        encryptedData: JSON.stringify(encryptedData),
        signature: signatureHex,
        publicKey: this.publicKey,
      };
    } catch (error) {
      this.logger.error('Vote encryption failed:', error);
      throw new Error('Vote encryption failed');
    }
  }

  static verifyVoteSignature(encryptedData: string, signature: string): boolean {
    if (!this.publicKey) {
      throw new Error('Public key not loaded');
    }

    try {
      const verify = crypto.createVerify('sha512');
      verify.update(Buffer.from(encryptedData));
      return verify.verify(this.publicKey, signature, 'hex');
    } catch (error) {
      this.logger.error('Vote signature verification failed:', error);
      return false;
    }
  }

  static decryptVote(encryptedData: string): object {
    try {
      const data = JSON.parse(encryptedData);
      const aesKey = Buffer.from(process.env.VOTE_ENCRYPTION_KEY!, 'hex');
      const iv = Buffer.from(data.iv, 'hex');
      
      const decipher = crypto.createDecipheriv('aes-256-gcm', aesKey, iv);
      decipher.setAuthTag(Buffer.from(data.authTag, 'hex'));

      let decrypted = decipher.update(data.data, 'hex', 'utf8');
      decrypted += decipher.final('utf8');

      return JSON.parse(decrypted);
    } catch (error) {
      this.logger.error('Vote decryption failed:', error);
      throw new Error('Vote decryption failed');
    }
  }

  // Utility functions
  static generateSecureToken(length: number = 32): string {
    return crypto.randomBytes(length).toString('hex');
  }

  static generateOTP(length: number = 6): string {
    const digits = '0123456789';
    let otp = '';
    for (let i = 0; i < length; i++) {
      otp += digits[crypto.randomInt(0, digits.length)];
    }
    return otp;
  }

  static hashData(data: string): string {
    return crypto.createHash('sha512').update(data).digest('hex');
  }

  static verifyHash(data: string, hash: string): boolean {
    const computedHash = this.hashData(data);
    return crypto.timingSafeEqual(Buffer.from(computedHash), Buffer.from(hash));
  }

  // Device security
  static async verifyDeviceIntegrity(attestationToken?: string): Promise<boolean> {
    // In a real implementation, this would verify SafetyNet/DeviceCheck tokens
    // For now, we'll return true in development and false if no token provided
    if (process.env.NODE_ENV === 'development') {
      return true;
    }

    if (!attestationToken) {
      return false;
    }

    // TODO: Implement actual device attestation verification
    // This would involve calling Google SafetyNet API or Apple DeviceCheck API
    return true;
  }

  static detectSuspiciousActivity(ipAddress: string, userAgent: string, userId: string): boolean {
    // Basic suspicious activity detection
    // In a real implementation, this would be more sophisticated
    
    // Check for common bot user agents
    const suspiciousUserAgents = [
      'curl', 'wget', 'python', 'postman', 'insomnia',
      'bot', 'crawler', 'spider', 'scraper'
    ];

    const lowerUserAgent = userAgent.toLowerCase();
    const isSuspiciousUserAgent = suspiciousUserAgents.some(agent => 
      lowerUserAgent.includes(agent)
    );

    if (isSuspiciousUserAgent) {
      this.logger.warn(`Suspicious user agent detected: ${userAgent} for user ${userId}`);
      return true;
    }

    // Check for private IP ranges (potential local testing)
    const privateIpPatterns = [
      /^127\./, // Localhost
      /^192\.168\./, // Private range
      /^10\./, // Private range
      /^172\.1[6-9]\./, // Private range
      /^172\.2[0-9]\./, // Private range
      /^172\.3[0-1]\./, // Private range
    ];

    const isPrivateIp = privateIpPatterns.some(pattern => pattern.test(ipAddress));
    if (isPrivateIp && process.env.NODE_ENV === 'production') {
      this.logger.warn(`Private IP detected in production: ${ipAddress} for user ${userId}`);
      return true;
    }

    return false;
  }

  // Rate limiting helpers
  static createRateLimitKey(identifier: string, action: string): string {
    return `rate_limit:${action}:${identifier}`;
  }

  // Audit trail helpers
  static createAuditHash(previousHash: string, data: object): string {
    const dataString = JSON.stringify(data);
    const combinedData = previousHash + dataString + Date.now().toString();
    return this.hashData(combinedData);
  }

  static verifyAuditChain(logs: Array<{ previousHash: string | null; currentHash: string; createdAt: Date }>): boolean {
    if (logs.length === 0) return true;

    for (let i = 0; i < logs.length; i++) {
      const currentLog = logs[i];
      
      if (i === 0) {
        // First log should have null previous hash
        if (currentLog.previousHash !== null) {
          return false;
        }
      } else {
        const previousLog = logs[i - 1];
        if (currentLog.previousHash !== previousLog.currentHash) {
          return false;
        }
      }
    }

    return true;
  }

  // Security headers
  static getSecurityHeaders() {
    return {
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
      'Content-Security-Policy': "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';",
      'Referrer-Policy': 'strict-origin-when-cross-origin',
    };
  }
}

export { JwtPayload, VoteEncryption };