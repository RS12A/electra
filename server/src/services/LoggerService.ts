import fs from 'fs';
import path from 'path';

export enum LogLevel {
  ERROR = 0,
  WARN = 1,
  INFO = 2,
  DEBUG = 3,
}

interface LogEntry {
  timestamp: string;
  level: string;
  message: string;
  meta?: any;
  stack?: string;
}

export class LoggerService {
  private logLevel: LogLevel;
  private logFilePath: string;

  constructor() {
    // Determine log level from environment
    const level = (process.env.LOG_LEVEL || 'info').toLowerCase();
    this.logLevel = this.parseLogLevel(level);
    
    // Set log file path
    this.logFilePath = process.env.LOG_FILE_PATH || './logs/app.log';
    
    // Ensure logs directory exists
    const logsDir = path.dirname(this.logFilePath);
    if (!fs.existsSync(logsDir)) {
      fs.mkdirSync(logsDir, { recursive: true });
    }
  }

  private parseLogLevel(level: string): LogLevel {
    switch (level) {
      case 'error': return LogLevel.ERROR;
      case 'warn': return LogLevel.WARN;
      case 'info': return LogLevel.INFO;
      case 'debug': return LogLevel.DEBUG;
      default: return LogLevel.INFO;
    }
  }

  private shouldLog(level: LogLevel): boolean {
    return level <= this.logLevel;
  }

  private formatLogEntry(level: string, message: string, meta?: any, stack?: string): LogEntry {
    return {
      timestamp: new Date().toISOString(),
      level,
      message,
      ...(meta && { meta }),
      ...(stack && { stack }),
    };
  }

  private writeToFile(entry: LogEntry) {
    try {
      const logLine = JSON.stringify(entry) + '\n';
      fs.appendFileSync(this.logFilePath, logLine);
    } catch (error) {
      console.error('Failed to write to log file:', error);
    }
  }

  private writeToConsole(entry: LogEntry) {
    const { timestamp, level, message, meta, stack } = entry;
    const colorMap = {
      ERROR: '\x1b[31m', // Red
      WARN: '\x1b[33m',  // Yellow
      INFO: '\x1b[36m',  // Cyan
      DEBUG: '\x1b[90m', // Gray
    };
    
    const color = colorMap[level as keyof typeof colorMap] || '';
    const reset = '\x1b[0m';
    
    let output = `${color}[${timestamp}] ${level}:${reset} ${message}`;
    
    if (meta) {
      output += `\n${color}Meta:${reset} ${JSON.stringify(meta, null, 2)}`;
    }
    
    if (stack) {
      output += `\n${color}Stack:${reset} ${stack}`;
    }
    
    console.log(output);
  }

  private log(level: LogLevel, levelName: string, message: string, meta?: any, error?: Error) {
    if (!this.shouldLog(level)) return;

    const stack = error?.stack;
    const entry = this.formatLogEntry(levelName, message, meta, stack);

    // Always write to console in development, or if no log file configured
    if (process.env.NODE_ENV === 'development' || !this.logFilePath) {
      this.writeToConsole(entry);
    }

    // Write to file if configured
    if (this.logFilePath) {
      this.writeToFile(entry);
    }
  }

  error(message: string, error?: Error | any, meta?: any) {
    if (error instanceof Error) {
      this.log(LogLevel.ERROR, 'ERROR', message, meta, error);
    } else if (typeof error === 'object') {
      this.log(LogLevel.ERROR, 'ERROR', message, { ...meta, error });
    } else {
      this.log(LogLevel.ERROR, 'ERROR', `${message} ${error || ''}`, meta);
    }
  }

  warn(message: string, meta?: any) {
    this.log(LogLevel.WARN, 'WARN', message, meta);
  }

  info(message: string, meta?: any) {
    this.log(LogLevel.INFO, 'INFO', message, meta);
  }

  debug(message: string, meta?: any) {
    this.log(LogLevel.DEBUG, 'DEBUG', message, meta);
  }

  // Structured logging for specific events
  logHttpRequest(method: string, url: string, statusCode: number, responseTime: number, userAgent?: string, ip?: string) {
    this.info('HTTP Request', {
      method,
      url,
      statusCode,
      responseTime: `${responseTime}ms`,
      userAgent,
      ip,
    });
  }

  logAuthenticationAttempt(matricNumber: string, success: boolean, ip?: string, userAgent?: string) {
    const level = success ? 'info' : 'warn';
    const message = `Authentication ${success ? 'successful' : 'failed'}`;
    
    this[level](message, {
      matricNumber,
      success,
      ip,
      userAgent,
    });
  }

  logVoteCast(electionId: string, voterId: string, candidateId: string, ip?: string) {
    this.info('Vote cast', {
      electionId,
      voterId,
      candidateId,
      ip,
      event: 'VOTE_CAST',
    });
  }

  logSecurityEvent(event: string, severity: 'low' | 'medium' | 'high' | 'critical', details: any) {
    const level = severity === 'critical' || severity === 'high' ? 'error' : 
                 severity === 'medium' ? 'warn' : 'info';
    
    this[level](`Security Event: ${event}`, {
      event,
      severity,
      ...details,
    });
  }

  logDatabaseOperation(operation: string, table: string, duration: number, success: boolean, error?: string) {
    const level = success ? 'debug' : 'error';
    this[level](`Database ${operation}`, {
      operation,
      table,
      duration: `${duration}ms`,
      success,
      ...(error && { error }),
    });
  }

  logSystemEvent(event: string, details?: any) {
    this.info(`System Event: ${event}`, {
      event,
      ...details,
    });
  }

  // Performance logging
  createTimer(name: string) {
    const startTime = process.hrtime.bigint();
    
    return {
      end: () => {
        const endTime = process.hrtime.bigint();
        const duration = Number(endTime - startTime) / 1000000; // Convert to milliseconds
        this.debug(`Timer: ${name}`, { duration: `${duration.toFixed(2)}ms` });
        return duration;
      }
    };
  }

  // Log rotation (simple implementation)
  rotateLog() {
    if (!fs.existsSync(this.logFilePath)) return;

    try {
      const stats = fs.statSync(this.logFilePath);
      const maxSize = 10 * 1024 * 1024; // 10MB
      
      if (stats.size > maxSize) {
        const rotatedPath = `${this.logFilePath}.${Date.now()}`;
        fs.renameSync(this.logFilePath, rotatedPath);
        this.info('Log file rotated', { oldFile: rotatedPath });
        
        // Keep only last 5 rotated logs
        this.cleanupOldLogs();
      }
    } catch (error) {
      console.error('Failed to rotate log file:', error);
    }
  }

  private cleanupOldLogs() {
    try {
      const logsDir = path.dirname(this.logFilePath);
      const fileName = path.basename(this.logFilePath);
      const files = fs.readdirSync(logsDir);
      
      const logFiles = files
        .filter(file => file.startsWith(fileName) && file !== fileName)
        .map(file => ({
          name: file,
          path: path.join(logsDir, file),
          time: fs.statSync(path.join(logsDir, file)).mtime
        }))
        .sort((a, b) => b.time.getTime() - a.time.getTime());

      // Keep only the 5 most recent rotated logs
      logFiles.slice(5).forEach(file => {
        fs.unlinkSync(file.path);
        this.debug('Deleted old log file', { file: file.name });
      });
    } catch (error) {
      console.error('Failed to cleanup old logs:', error);
    }
  }

  // Audit logging
  logAuditEvent(userId: string | undefined, action: string, resource: string, resourceId?: string, details?: any, ip?: string) {
    this.info('Audit Event', {
      userId,
      action,
      resource,
      resourceId,
      details,
      ip,
      type: 'AUDIT',
    });
  }

  // Error aggregation for monitoring
  logErrorForMonitoring(error: Error, context?: any) {
    this.error('Application Error', error, {
      ...context,
      errorCode: error.name,
      monitoring: true,
    });
  }
}

// Singleton instance
const logger = new LoggerService();
export default logger;