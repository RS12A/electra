import { Request, Response, NextFunction } from 'express';
import { DatabaseService } from '../services/DatabaseService';
import { SecurityService } from '../services/SecurityService';
import { LoggerService } from '../services/LoggerService';

const logger = new LoggerService();

// Store the last audit log hash in memory (in production, use Redis or database)
let lastAuditHash: string | null = null;

interface AuditLogData {
  userId?: string;
  action: string;
  resource: string;
  resourceId?: string;
  details?: object;
  ipAddress?: string;
  userAgent?: string;
}

// Map HTTP methods to actions
const actionMap: Record<string, string> = {
  GET: 'READ',
  POST: 'CREATE',
  PUT: 'UPDATE',
  PATCH: 'UPDATE',
  DELETE: 'DELETE',
};

// Extract resource name from path
const extractResourceFromPath = (path: string): string => {
  const segments = path.split('/').filter(Boolean);
  if (segments.length >= 2) {
    // Remove 'api' and version if present
    const resourceSegments = segments.filter(segment => 
      !['api', 'v1', 'v2'].includes(segment.toLowerCase())
    );
    return resourceSegments[0] || 'unknown';
  }
  return 'unknown';
};

// Extract resource ID from path
const extractResourceIdFromPath = (path: string, params: any): string | undefined => {
  // Look for UUID pattern in path or params
  const uuidRegex = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i;
  
  // Check path for UUID
  const pathMatch = path.match(uuidRegex);
  if (pathMatch) {
    return pathMatch[0];
  }

  // Check params for common ID fields
  const idFields = ['id', 'electionId', 'candidateId', 'userId', 'voteId'];
  for (const field of idFields) {
    if (params[field] && typeof params[field] === 'string') {
      return params[field];
    }
  }

  return undefined;
};

// Check if route should be audited
const shouldAuditRoute = (path: string, method: string): boolean => {
  // Skip health checks and static files
  const skipPatterns = [
    '/health',
    '/docs',
    '/uploads',
    '/favicon.ico',
    '/robots.txt',
  ];

  const skipExtensions = ['.css', '.js', '.png', '.jpg', '.ico'];
  
  // Check skip patterns
  for (const pattern of skipPatterns) {
    if (path.includes(pattern)) {
      return false;
    }
  }

  // Check skip extensions
  for (const extension of skipExtensions) {
    if (path.endsWith(extension)) {
      return false;
    }
  }

  // Only audit API routes
  return path.includes('/api/');
};

// Create audit log entry
export const createAuditLog = async (data: AuditLogData): Promise<void> => {
  try {
    // Create hash chain
    const auditData = {
      ...data,
      timestamp: new Date().toISOString(),
    };

    const currentHash = SecurityService.createAuditHash(
      lastAuditHash || '',
      auditData
    );

    // Save to database
    await DatabaseService.createAuditLog({
      userId: data.userId,
      action: data.action,
      resource: data.resource,
      resourceId: data.resourceId,
      details: data.details,
      ipAddress: data.ipAddress,
      userAgent: data.userAgent,
      previousHash: lastAuditHash || undefined,
      currentHash,
    });

    // Update last hash
    lastAuditHash = currentHash;

    // Log to application logs
    logger.logAuditEvent(
      data.userId,
      data.action,
      data.resource,
      data.resourceId,
      data.details,
      data.ipAddress
    );
  } catch (error) {
    logger.error('Failed to create audit log', error);
    // Don't throw error to avoid breaking the request
  }
};

// Pre-request audit middleware
export const auditLogger = async (req: Request, res: Response, next: NextFunction) => {
  const path = req.path;
  const method = req.method;

  // Skip non-auditable routes
  if (!shouldAuditRoute(path, method)) {
    return next();
  }

  // Store request start time for performance logging
  req.startTime = Date.now();

  // Store original response methods to capture response data
  const originalSend = res.send;
  const originalJson = res.json;
  
  let responseData: any = null;

  // Override response methods to capture data
  res.send = function(body: any) {
    responseData = body;
    return originalSend.call(this, body);
  };

  res.json = function(body: any) {
    responseData = body;
    return originalJson.call(this, body);
  };

  // Wait for response to complete, then create audit log
  res.on('finish', async () => {
    try {
      const action = actionMap[method] || method;
      const resource = extractResourceFromPath(path);
      const resourceId = extractResourceIdFromPath(path, req.params);
      const duration = Date.now() - (req.startTime || Date.now());

      // Extract relevant request details
      const details: any = {
        method,
        path,
        statusCode: res.statusCode,
        duration: `${duration}ms`,
      };

      // Add query parameters if present
      if (Object.keys(req.query).length > 0) {
        details.query = req.query;
      }

      // Add request body for non-GET requests (excluding sensitive data)
      if (method !== 'GET' && req.body && Object.keys(req.body).length > 0) {
        const sanitizedBody = sanitizeRequestBody(req.body, path);
        if (Object.keys(sanitizedBody).length > 0) {
          details.requestBody = sanitizedBody;
        }
      }

      // Add response data for important operations (excluding sensitive data)
      if (shouldIncludeResponseData(path, method, res.statusCode)) {
        details.responseData = sanitizeResponseData(responseData, path);
      }

      // Add error details if request failed
      if (res.statusCode >= 400) {
        details.error = true;
        if (typeof responseData === 'object' && responseData?.message) {
          details.errorMessage = responseData.message;
        }
      }

      // Create audit log
      await createAuditLog({
        userId: req.user?.id,
        action,
        resource,
        resourceId,
        details,
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'],
      });
    } catch (error) {
      logger.error('Audit logging failed', error);
    }
  });

  next();
};

// Sanitize request body to remove sensitive information
const sanitizeRequestBody = (body: any, path: string): any => {
  if (!body || typeof body !== 'object') {
    return {};
  }

  const sensitiveFields = ['password', 'token', 'secret', 'key', 'auth', 'credential'];
  const sanitized: any = {};

  for (const [key, value] of Object.entries(body)) {
    const keyLower = key.toLowerCase();
    
    // Skip sensitive fields
    if (sensitiveFields.some(field => keyLower.includes(field))) {
      sanitized[key] = '[REDACTED]';
    } else if (typeof value === 'object' && value !== null) {
      // Recursively sanitize nested objects
      sanitized[key] = sanitizeRequestBody(value, path);
    } else {
      sanitized[key] = value;
    }
  }

  return sanitized;
};

// Sanitize response data to remove sensitive information
const sanitizeResponseData = (data: any, path: string): any => {
  if (!data || typeof data !== 'object') {
    return data;
  }

  const sensitiveFields = ['password', 'token', 'secret', 'key', 'hash'];
  
  if (Array.isArray(data)) {
    return data.map(item => sanitizeResponseData(item, path));
  }

  const sanitized: any = {};
  for (const [key, value] of Object.entries(data)) {
    const keyLower = key.toLowerCase();
    
    if (sensitiveFields.some(field => keyLower.includes(field))) {
      sanitized[key] = '[REDACTED]';
    } else if (typeof value === 'object' && value !== null) {
      sanitized[key] = sanitizeResponseData(value, path);
    } else {
      sanitized[key] = value;
    }
  }

  return sanitized;
};

// Determine if response data should be included in audit log
const shouldIncludeResponseData = (path: string, method: string, statusCode: number): boolean => {
  // Include response data for successful CREATE, UPDATE, DELETE operations
  if (method === 'GET') {
    return false; // Skip GET responses to avoid logging sensitive data
  }

  // Include for successful operations
  if (statusCode >= 200 && statusCode < 300) {
    return true;
  }

  // Include for client errors (4xx) to capture validation errors
  if (statusCode >= 400 && statusCode < 500) {
    return true;
  }

  return false;
};

// Manual audit logging for specific events
export const logSpecificEvent = async (
  req: Request,
  action: string,
  resource: string,
  resourceId?: string,
  additionalDetails?: object
) => {
  try {
    const details = {
      method: req.method,
      path: req.path,
      ...additionalDetails,
    };

    await createAuditLog({
      userId: req.user?.id,
      action,
      resource,
      resourceId,
      details,
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });
  } catch (error) {
    logger.error('Manual audit logging failed', error);
  }
};

// Extend Express Request interface for startTime
declare global {
  namespace Express {
    interface Request {
      startTime?: number;
    }
  }
}

// Initialize audit system
export const initializeAuditSystem = async () => {
  try {
    // Get the last audit log hash from database
    const db = DatabaseService.getClient();
    const lastLog = await db.auditLog.findFirst({
      orderBy: { createdAt: 'desc' },
      select: { currentHash: true },
    });

    if (lastLog && lastLog.currentHash) {
      lastAuditHash = lastLog.currentHash;
      logger.info('Audit system initialized', { lastHash: lastAuditHash ? lastAuditHash.substring(0, 8) + '...' : 'none' });
    } else {
      logger.info('Audit system initialized - no previous logs found');
    }
  } catch (error) {
    logger.error('Failed to initialize audit system', error);
    throw error;
  }
};

export { AuditLogData };