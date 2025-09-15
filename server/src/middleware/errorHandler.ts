import { Request, Response, NextFunction } from 'express';
import { LoggerService } from '../services/LoggerService';
import { Prisma } from '../types/prisma';

const logger = new LoggerService();

interface ErrorResponse {
  error: string;
  message: string;
  code?: string;
  details?: any;
  timestamp: string;
  path: string;
  method: string;
  stack?: string;
}

export class AppError extends Error {
  public statusCode: number;
  public code?: string;
  public isOperational: boolean;
  public details?: any;

  constructor(message: string, statusCode: number = 500, code?: string, details?: any) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = true;
    this.details = details;

    Error.captureStackTrace(this, this.constructor);
  }
}

// Validation error class
export class ValidationError extends AppError {
  constructor(message: string, details?: any) {
    super(message, 400, 'VALIDATION_ERROR', details);
  }
}

// Authentication error class
export class AuthenticationError extends AppError {
  constructor(message: string = 'Authentication failed', code: string = 'AUTH_ERROR') {
    super(message, 401, code);
  }
}

// Authorization error class
export class AuthorizationError extends AppError {
  constructor(message: string = 'Access denied', code: string = 'ACCESS_DENIED') {
    super(message, 403, code);
  }
}

// Not found error class
export class NotFoundError extends AppError {
  constructor(message: string = 'Resource not found', resource?: string) {
    super(message, 404, 'NOT_FOUND', { resource });
  }
}

// Conflict error class
export class ConflictError extends AppError {
  constructor(message: string, details?: any) {
    super(message, 409, 'CONFLICT', details);
  }
}

// Rate limiting error class
export class RateLimitError extends AppError {
  constructor(message: string = 'Rate limit exceeded') {
    super(message, 429, 'RATE_LIMIT_EXCEEDED');
  }
}

// Database error handler
const handleDatabaseError = (error: any): AppError => {
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    switch (error.code) {
      case 'P2002':
        // Unique constraint violation
        const target = error.meta?.target as string[] || [];
        const field = target.length > 0 ? target[0] : 'field';
        return new ConflictError(`${field} already exists`, {
          field,
          value: error.meta?.target,
        });
      
      case 'P2025':
        // Record not found
        return new NotFoundError('Record not found');
      
      case 'P2003':
        // Foreign key constraint violation
        return new ValidationError('Invalid reference to related record', {
          field: error.meta?.field_name,
        });
      
      case 'P2014':
        // Required relation violation
        return new ValidationError('Required relation is missing', {
          relation: error.meta?.relation_name,
        });
      
      default:
        logger.error('Unhandled Prisma error', error);
        return new AppError('Database operation failed', 500, 'DATABASE_ERROR');
    }
  }

  if (error instanceof Prisma.PrismaClientUnknownRequestError) {
    logger.error('Unknown Prisma error', error);
    return new AppError('Database operation failed', 500, 'DATABASE_ERROR');
  }

  if (error instanceof Prisma.PrismaClientRustPanicError) {
    logger.error('Prisma client panic', error);
    return new AppError('Database connection error', 503, 'DATABASE_CONNECTION_ERROR');
  }

  if (error instanceof Prisma.PrismaClientInitializationError) {
    logger.error('Prisma initialization error', error);
    return new AppError('Database initialization failed', 503, 'DATABASE_INIT_ERROR');
  }

  if (error instanceof Prisma.PrismaClientValidationError) {
    return new ValidationError('Invalid data provided', {
      details: error.message,
    });
  }

  return new AppError('Database error', 500, 'DATABASE_ERROR');
};

// JWT error handler
const handleJWTError = (error: any): AppError => {
  if (error.name === 'JsonWebTokenError') {
    return new AuthenticationError('Invalid token', 'INVALID_TOKEN');
  }
  
  if (error.name === 'TokenExpiredError') {
    return new AuthenticationError('Token expired', 'TOKEN_EXPIRED');
  }
  
  if (error.name === 'NotBeforeError') {
    return new AuthenticationError('Token not active', 'TOKEN_NOT_ACTIVE');
  }

  return new AuthenticationError('Token verification failed', 'TOKEN_ERROR');
};

// Multer error handler (for file uploads)
const handleMulterError = (error: any): AppError => {
  switch (error.code) {
    case 'LIMIT_FILE_SIZE':
      return new ValidationError('File size too large', {
        maxSize: error.limit,
      });
    
    case 'LIMIT_FILE_COUNT':
      return new ValidationError('Too many files', {
        maxCount: error.limit,
      });
    
    case 'LIMIT_UNEXPECTED_FILE':
      return new ValidationError('Unexpected file field', {
        field: error.field,
      });
    
    case 'LIMIT_PART_COUNT':
      return new ValidationError('Too many parts');
    
    case 'LIMIT_FIELD_KEY':
      return new ValidationError('Field name too long');
    
    case 'LIMIT_FIELD_VALUE':
      return new ValidationError('Field value too long');
    
    case 'LIMIT_FIELD_COUNT':
      return new ValidationError('Too many fields');
    
    default:
      return new ValidationError('File upload error', {
        code: error.code,
      });
  }
};

// Format error response
const formatErrorResponse = (error: AppError, req: Request): ErrorResponse => {
  const response: ErrorResponse = {
    error: error.name || 'Error',
    message: error.message,
    timestamp: new Date().toISOString(),
    path: req.originalUrl || req.url,
    method: req.method,
  };

  if (error.code) {
    response.code = error.code;
  }

  if (error.details) {
    response.details = error.details;
  }

  // Include stack trace in development
  if (process.env.NODE_ENV === 'development' && error.stack) {
    response.stack = error.stack;
  }

  return response;
};

// Main error handling middleware
export const errorHandler = (
  error: any,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  let appError: AppError;

  // Convert known errors to AppError instances
  if (error instanceof AppError) {
    appError = error;
  } else if (error.name?.includes('Prisma') || error.code?.startsWith('P')) {
    appError = handleDatabaseError(error);
  } else if (error.name?.includes('JsonWebToken') || error.name?.includes('Token')) {
    appError = handleJWTError(error);
  } else if (error.code?.startsWith('LIMIT_')) {
    appError = handleMulterError(error);
  } else if (error.name === 'ValidationError') {
    appError = new ValidationError(error.message, error.details);
  } else if (error.name === 'CastError') {
    appError = new ValidationError('Invalid ID format', { value: error.value });
  } else if (error.code === 'ENOENT') {
    appError = new NotFoundError('File not found');
  } else if (error.code === 'EACCES') {
    appError = new AppError('Permission denied', 403, 'PERMISSION_DENIED');
  } else {
    // Unknown error
    appError = new AppError(
      process.env.NODE_ENV === 'development' ? error.message : 'Internal server error',
      500,
      'INTERNAL_ERROR'
    );
  }

  // Log error details
  const logLevel = appError.statusCode >= 500 ? 'error' : 'warn';
  logger[logLevel]('Request error', error, {
    statusCode: appError.statusCode,
    code: appError.code,
    userId: req.user?.id,
    ip: req.ip,
    userAgent: req.headers['user-agent'],
    path: req.originalUrl,
    method: req.method,
    body: req.body,
    params: req.params,
    query: req.query,
  });

  // Format and send error response
  const errorResponse = formatErrorResponse(appError, req);
  res.status(appError.statusCode).json(errorResponse);
};

// Async error wrapper for route handlers
export const asyncHandler = (fn: Function) => {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// Not found middleware (404 handler)
export const notFound = (req: Request, res: Response, next: NextFunction) => {
  const error = new NotFoundError(`Route not found: ${req.method} ${req.originalUrl}`);
  next(error);
};

// Validation middleware wrapper
export const validateRequest = (schema: any, property: 'body' | 'query' | 'params' = 'body') => {
  return (req: Request, res: Response, next: NextFunction) => {
    const { error, value } = schema.validate(req[property], {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const details = error.details.map((detail: any) => ({
        field: detail.path.join('.'),
        message: detail.message,
        value: detail.context?.value,
      }));

      return next(new ValidationError('Validation failed', { details }));
    }

    // Replace the request property with the validated and sanitized value
    req[property] = value;
    next();
  };
};