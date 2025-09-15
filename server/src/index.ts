import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
import { createServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';
import path from 'path';
import fs from 'fs';

// Import routes
import authRoutes from './routes/auth';
import electionRoutes from './routes/elections';
import candidateRoutes from './routes/candidates';
import voteRoutes from './routes/votes';
import adminRoutes from './routes/admin';
import userRoutes from './routes/users';
import auditRoutes from './routes/audit';

// Import middleware
import { errorHandler } from './middleware/errorHandler';
import { authMiddleware } from './middleware/auth';
import { auditLogger } from './middleware/auditLogger';

// Import services
import { DatabaseService } from './services/DatabaseService';
import { SecurityService } from './services/SecurityService';
import { LoggerService } from './services/LoggerService';

// Load environment variables
dotenv.config();

class ElectraServer {
  private app: express.Application;
  private server: any;
  private io: SocketIOServer;
  private logger: LoggerService;

  constructor() {
    this.app = express();
    this.logger = new LoggerService();
    this.initializeDatabase();
    this.initializeMiddleware();
    this.initializeRoutes();
    this.initializeWebSocket();
    this.initializeErrorHandling();
    this.createDirectories();
  }

  private async initializeDatabase() {
    try {
      await DatabaseService.initialize();
      this.logger.info('Database initialized successfully');
    } catch (error) {
      this.logger.error('Database initialization failed:', error);
      process.exit(1);
    }
  }

  private initializeMiddleware() {
    // Security middleware
    this.app.use(helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          styleSrc: ["'self'", "'unsafe-inline'"],
          scriptSrc: ["'self'"],
          imgSrc: ["'self'", "data:", "https:"],
          fontSrc: ["'self'"],
          connectSrc: ["'self'", "ws:", "wss:"],
        },
      },
      hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true,
      },
    }));

    // CORS configuration
    const corsOptions = {
      origin: process.env.CORS_ORIGINS?.split(',') || ['http://localhost:3000'],
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    };
    this.app.use(cors(corsOptions));

    // Rate limiting
    const limiter = rateLimit({
      windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000'), // 15 minutes
      max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100'),
      message: {
        error: 'Too many requests from this IP',
        code: 'RATE_LIMIT_EXCEEDED',
      },
      standardHeaders: true,
      legacyHeaders: false,
    });
    this.app.use('/api/', limiter);

    // Request logging
    if (process.env.ENABLE_REQUEST_LOGGING === 'true') {
      this.app.use(morgan('combined', {
        stream: {
          write: (message) => this.logger.info(message.trim()),
        },
      }));
    }

    // Body parsing and compression
    this.app.use(compression());
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true, limit: '10mb' }));

    // Static files
    this.app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

    // Audit logging middleware
    this.app.use(auditLogger);
  }

  private initializeRoutes() {
    const apiRouter = express.Router();

    // Public routes
    apiRouter.use('/auth', authRoutes);
    
    // Protected routes
    apiRouter.use('/users', authMiddleware, userRoutes);
    apiRouter.use('/elections', authMiddleware, electionRoutes);
    apiRouter.use('/candidates', authMiddleware, candidateRoutes);
    apiRouter.use('/votes', authMiddleware, voteRoutes);
    apiRouter.use('/admin', authMiddleware, adminRoutes);
    apiRouter.use('/audit', authMiddleware, auditRoutes);

    // Health check
    apiRouter.get('/health', (req, res) => {
      res.json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        version: process.env.npm_package_version || '1.0.0',
        environment: process.env.NODE_ENV || 'development',
      });
    });

    // API documentation
    if (process.env.ENABLE_SWAGGER_DOCS === 'true') {
      apiRouter.get('/docs', (req, res) => {
        res.json({
          message: 'API Documentation',
          endpoints: {
            auth: '/api/v1/auth/*',
            users: '/api/v1/users/*',
            elections: '/api/v1/elections/*',
            candidates: '/api/v1/candidates/*',
            votes: '/api/v1/votes/*',
            admin: '/api/v1/admin/*',
            audit: '/api/v1/audit/*',
          },
        });
      });
    }

    this.app.use(`/api/${process.env.API_VERSION || 'v1'}`, apiRouter);

    // Root endpoint
    this.app.get('/', (req, res) => {
      res.json({
        name: 'Electra Voting System API',
        version: '1.0.0',
        description: 'Secure university voting system backend',
        documentation: `/api/${process.env.API_VERSION || 'v1'}/docs`,
        health: `/api/${process.env.API_VERSION || 'v1'}/health`,
      });
    });
  }

  private initializeWebSocket() {
    this.server = createServer(this.app);
    this.io = new SocketIOServer(this.server, {
      cors: {
        origin: process.env.CORS_ORIGINS?.split(',') || ['http://localhost:3000'],
        credentials: true,
      },
    });

    // WebSocket authentication middleware
    this.io.use(async (socket, next) => {
      try {
        const token = socket.handshake.auth.token || socket.handshake.query.token;
        if (token) {
          const user = await SecurityService.verifyJwtToken(token as string);
          socket.data.user = user;
          next();
        } else {
          next(new Error('Authentication required'));
        }
      } catch (error) {
        next(new Error('Invalid token'));
      }
    });

    this.io.on('connection', (socket) => {
      const user = socket.data.user;
      this.logger.info(`User connected via WebSocket: ${user.id}`);

      // Join user-specific room
      socket.join(`user:${user.id}`);

      // Join role-specific room
      socket.join(`role:${user.role}`);

      // Handle disconnection
      socket.on('disconnect', () => {
        this.logger.info(`User disconnected from WebSocket: ${user.id}`);
      });

      // Real-time election updates
      socket.on('subscribe:election', (electionId: string) => {
        socket.join(`election:${electionId}`);
        this.logger.info(`User ${user.id} subscribed to election ${electionId}`);
      });

      socket.on('unsubscribe:election', (electionId: string) => {
        socket.leave(`election:${electionId}`);
        this.logger.info(`User ${user.id} unsubscribed from election ${electionId}`);
      });
    });

    // Store socket.io instance globally for use in other services
    global.io = this.io;
  }

  private initializeErrorHandling() {
    // 404 handler
    this.app.use('*', (req, res) => {
      res.status(404).json({
        error: 'Not Found',
        message: 'The requested endpoint does not exist',
        path: req.originalUrl,
      });
    });

    // Global error handler
    this.app.use(errorHandler);

    // Graceful shutdown
    process.on('SIGTERM', () => {
      this.logger.info('SIGTERM received, shutting down gracefully');
      this.shutdown();
    });

    process.on('SIGINT', () => {
      this.logger.info('SIGINT received, shutting down gracefully');
      this.shutdown();
    });

    // Handle uncaught exceptions
    process.on('uncaughtException', (error) => {
      this.logger.error('Uncaught Exception:', error);
      this.shutdown(1);
    });

    // Handle unhandled rejections
    process.on('unhandledRejection', (reason, promise) => {
      this.logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
      this.shutdown(1);
    });
  }

  private createDirectories() {
    const directories = [
      './uploads',
      './logs',
      './keys',
    ];

    directories.forEach(dir => {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
        this.logger.info(`Created directory: ${dir}`);
      }
    });
  }

  public start() {
    const port = process.env.PORT || 3000;
    
    this.server.listen(port, () => {
      this.logger.info(`🚀 Electra Server running on port ${port}`);
      this.logger.info(`📚 Environment: ${process.env.NODE_ENV || 'development'}`);
      this.logger.info(`📖 API Documentation: http://localhost:${port}/api/v1/docs`);
      this.logger.info(`💚 Health Check: http://localhost:${port}/api/v1/health`);
    });
  }

  private shutdown(code: number = 0) {
    this.logger.info('Shutting down server...');
    
    this.server.close(() => {
      this.logger.info('HTTP server closed');
      DatabaseService.disconnect();
      process.exit(code);
    });

    // Force close after 10 seconds
    setTimeout(() => {
      this.logger.error('Could not close connections in time, forcefully shutting down');
      process.exit(1);
    }, 10000);
  }
}

// Start the server
const server = new ElectraServer();
server.start();

export default ElectraServer;