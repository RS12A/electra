import { Request, Response, NextFunction } from 'express';
import { SecurityService } from '../services/SecurityService';
import { DatabaseService } from '../services/DatabaseService';
import { LoggerService } from '../services/LoggerService';
import { UserRole } from '../types/prisma';

// Extend Express Request interface to include user data
declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        matricNumber: string;
        role: UserRole;
        email?: string;
        firstName?: string;
        lastName?: string;
      };
    }
  }
}

interface AuthRequest extends Request {
  user: NonNullable<Request['user']>;
}

const logger = new LoggerService();

export const authMiddleware = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Authorization header is required',
        code: 'MISSING_AUTH_HEADER',
      });
    }

    const token = authHeader.startsWith('Bearer ') 
      ? authHeader.slice(7) 
      : authHeader;

    if (!token) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Access token is required',
        code: 'MISSING_TOKEN',
      });
    }

    // Verify JWT token
    const payload = await SecurityService.verifyJwtToken(token);
    
    // Get user from database to ensure they still exist and are active
    const user = await DatabaseService.getUserById(payload.id);
    
    if (!user || !user.isActive) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'User account is inactive or not found',
        code: 'INACTIVE_USER',
      });
    }

    // Attach user to request object
    req.user = {
      id: user.id,
      matricNumber: user.matricNumber,
      role: user.role,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
    };

    // Log successful authentication
    logger.debug('User authenticated', {
      userId: user.id,
      matricNumber: user.matricNumber,
      role: user.role,
      endpoint: req.path,
    });

    next();
  } catch (error) {
    logger.warn('Authentication failed', {
      error: error instanceof Error ? error.message : 'Unknown error',
      token: req.headers.authorization ? 'present' : 'missing',
      endpoint: req.path,
      ip: req.ip,
      userAgent: req.headers['user-agent'],
    });

    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid or expired access token',
      code: 'INVALID_TOKEN',
    });
  }
};

// Role-based authorization middleware
export const requireRole = (...roles: UserRole[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction): void => {
    if (!req.user) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Authentication required',
        code: 'UNAUTHENTICATED',
      });
    }

    if (!roles.includes(req.user.role)) {
      logger.warn('Authorization failed - insufficient role', {
        userId: req.user.id,
        userRole: req.user.role,
        requiredRoles: roles,
        endpoint: req.path,
      });

      return res.status(403).json({
        error: 'Forbidden',
        message: `Access denied. Required roles: ${roles.join(', ')}`,
        code: 'INSUFFICIENT_ROLE',
      });
    }

    next();
  };
};

// Admin-only middleware
export const requireAdmin = requireRole(UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE);

// Student or higher middleware (students, candidates, admins, committee)
export const requireStudent = requireRole(
  UserRole.STUDENT, 
  UserRole.CANDIDATE, 
  UserRole.ADMIN, 
  UserRole.ELECTORAL_COMMITTEE
);

// Electoral committee or admin only
export const requireCommitteeOrAdmin = requireRole(UserRole.ELECTORAL_COMMITTEE, UserRole.ADMIN);

// Optional authentication middleware (doesn't fail if no token)
export const optionalAuth = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader) {
      const token = authHeader.startsWith('Bearer ') 
        ? authHeader.slice(7) 
        : authHeader;

      if (token) {
        const payload = await SecurityService.verifyJwtToken(token);
        const user = await DatabaseService.getUserById(payload.id);
        
        if (user && user.isActive) {
          req.user = {
            id: user.id,
            matricNumber: user.matricNumber,
            role: user.role,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
          };
        }
      }
    }
  } catch (error) {
    // Silently continue without authentication
    logger.debug('Optional authentication failed', {
      error: error instanceof Error ? error.message : 'Unknown error',
      endpoint: req.path,
    });
  }
  
  next();
};

// Device security middleware
export const requireDeviceAttestation = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const attestationToken = req.headers['x-device-attestation'] as string;
    
    // Skip device attestation in development
    if (process.env.NODE_ENV === 'development') {
      return next();
    }

    const isDeviceValid = await SecurityService.verifyDeviceIntegrity(attestationToken);
    
    if (!isDeviceValid) {
      logger.logSecurityEvent('DEVICE_ATTESTATION_FAILED', 'high', {
        userId: req.user?.id,
        ip: req.ip,
        userAgent: req.headers['user-agent'],
        endpoint: req.path,
      });

      return res.status(403).json({
        error: 'Device Security Check Failed',
        message: 'Your device failed security verification. Please use a secure device.',
        code: 'DEVICE_ATTESTATION_FAILED',
      });
    }

    next();
  } catch (error) {
    logger.error('Device attestation error', error);
    return res.status(500).json({
      error: 'Internal Server Error',
      message: 'Device security check failed',
      code: 'DEVICE_ATTESTATION_ERROR',
    });
  }
};

// Suspicious activity detection middleware
export const detectSuspiciousActivity = (req: Request, res: Response, next: NextFunction): void => {
  const ipAddress = req.ip || req.connection.remoteAddress || 'unknown';
  const userAgent = req.headers['user-agent'] || 'unknown';
  const userId = req.user?.id || 'anonymous';

  const isSuspicious = SecurityService.detectSuspiciousActivity(ipAddress, userAgent, userId);

  if (isSuspicious) {
    logger.logSecurityEvent('SUSPICIOUS_ACTIVITY_DETECTED', 'medium', {
      userId,
      ipAddress,
      userAgent,
      endpoint: req.path,
      method: req.method,
    });

    // Don't block in development, but log the activity
    if (process.env.NODE_ENV !== 'development') {
      return res.status(403).json({
        error: 'Suspicious Activity Detected',
        message: 'Your request has been flagged for security review',
        code: 'SUSPICIOUS_ACTIVITY',
      });
    }
  }

  next();
};

// API key validation middleware (for external integrations)
export const validateApiKey = (req: Request, res: Response, next: NextFunction): void => {
  const apiKey = req.headers['x-api-key'] as string;
  
  if (!apiKey) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'API key is required',
      code: 'MISSING_API_KEY',
    });
  }

  // In a real implementation, validate against stored API keys
  // For now, just check if it matches the development key
  const validApiKey = process.env.API_KEY || 'dev-api-key';
  
  if (apiKey !== validApiKey) {
    logger.logSecurityEvent('INVALID_API_KEY', 'high', {
      apiKey: apiKey.substring(0, 8) + '***', // Log partial key for security
      ip: req.ip,
      endpoint: req.path,
    });

    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid API key',
      code: 'INVALID_API_KEY',
    });
  }

  next();
};

// Export types for use in route handlers
export type { AuthRequest };