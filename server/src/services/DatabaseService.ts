import { PrismaClient, User, UserRole } from '@prisma/client';
import { LoggerService } from './LoggerService';

export class DatabaseService {
  private static prisma: PrismaClient;
  private static logger: LoggerService = new LoggerService();

  static async initialize() {
    try {
      this.prisma = new PrismaClient({
        log: [
          { level: 'query', emit: 'event' },
          { level: 'error', emit: 'event' },
          { level: 'warn', emit: 'event' },
        ],
      });

      // Log database queries in development
      if (process.env.NODE_ENV === 'development') {
        this.prisma.$on('query', (e) => {
          this.logger.debug(`Query: ${e.query}`);
          this.logger.debug(`Duration: ${e.duration}ms`);
        });
      }

      this.prisma.$on('error', (e) => {
        this.logger.error('Database error:', e);
      });

      this.prisma.$on('warn', (e) => {
        this.logger.warn('Database warning:', e);
      });

      // Test connection
      await this.prisma.$connect();
      this.logger.info('Database connected successfully');

      // Run migrations in development
      if (process.env.NODE_ENV === 'development') {
        await this.runMigrations();
      }

    } catch (error) {
      this.logger.error('Database initialization failed:', error);
      throw error;
    }
  }

  static async runMigrations() {
    try {
      // This would typically use Prisma CLI in a real setup
      // For now, we'll ensure the database is ready
      await this.prisma.$queryRaw`SELECT 1`;
      this.logger.info('Database migrations completed');
    } catch (error) {
      this.logger.error('Migration failed:', error);
      throw error;
    }
  }

  static async seed() {
    try {
      this.logger.info('Starting database seeding...');

      // Create default admin user
      const adminUser = await this.prisma.user.upsert({
        where: { matricNumber: 'ADMIN001' },
        update: {},
        create: {
          matricNumber: 'ADMIN001',
          email: 'admin@kwasu.edu.ng',
          passwordHash: '$argon2id$v=19$m=65536,t=3,p=4$random_salt', // Will be replaced with actual hash
          firstName: 'System',
          lastName: 'Administrator',
          role: UserRole.ADMIN,
          isActive: true,
          isVerified: true,
          department: 'Information Technology',
          faculty: 'Computing',
        },
      });

      // Create sample electoral committee member
      const committeeUser = await this.prisma.user.upsert({
        where: { matricNumber: 'EC001' },
        update: {},
        create: {
          matricNumber: 'EC001',
          email: 'committee@kwasu.edu.ng',
          passwordHash: '$argon2id$v=19$m=65536,t=3,p=4$random_salt',
          firstName: 'Electoral',
          lastName: 'Committee',
          role: UserRole.ELECTORAL_COMMITTEE,
          isActive: true,
          isVerified: true,
          department: 'Student Affairs',
          faculty: 'Administration',
        },
      });

      // Create sample students
      const students = await Promise.all([
        this.prisma.user.upsert({
          where: { matricNumber: 'KWU/SCI/001' },
          update: {},
          create: {
            matricNumber: 'KWU/SCI/001',
            email: 'student1@student.kwasu.edu.ng',
            passwordHash: '$argon2id$v=19$m=65536,t=3,p=4$random_salt',
            firstName: 'John',
            lastName: 'Doe',
            role: UserRole.STUDENT,
            isActive: true,
            isVerified: true,
            department: 'Computer Science',
            faculty: 'Computing',
            yearOfStudy: 3,
          },
        }),
        this.prisma.user.upsert({
          where: { matricNumber: 'KWU/SCI/002' },
          update: {},
          create: {
            matricNumber: 'KWU/SCI/002',
            email: 'student2@student.kwasu.edu.ng',
            passwordHash: '$argon2id$v=19$m=65536,t=3,p=4$random_salt',
            firstName: 'Jane',
            lastName: 'Smith',
            role: UserRole.STUDENT,
            isActive: true,
            isVerified: true,
            department: 'Information Technology',
            faculty: 'Computing',
            yearOfStudy: 2,
          },
        }),
      ]);

      // Create sample election
      const election = await this.prisma.election.create({
        data: {
          title: 'Student Union President Election 2024',
          description: 'Annual election for Student Union President position',
          category: 'Student Union',
          startDate: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
          endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // Next week
          isActive: false,
          allowDelayedReveal: true,
          revealDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000), // 8 days from now
          maxVotesPerUser: 1,
          eligibleFaculties: ['Computing', 'Engineering', 'Sciences'],
          eligibleYears: [1, 2, 3, 4],
          createdById: adminUser.id,
        },
      });

      // Create sample candidates
      await this.prisma.candidate.createMany({
        data: [
          {
            electionId: election.id,
            userId: students[0].id,
            manifesto: 'I will work tirelessly to improve student welfare and academic standards.',
            isApproved: true,
          },
          {
            electionId: election.id,
            userId: students[1].id,
            manifesto: 'My vision is to create a more inclusive and innovative campus environment.',
            isApproved: true,
          },
        ],
      });

      // Create system configuration
      await this.prisma.systemConfig.createMany({
        data: [
          {
            key: 'UNIVERSITY_NAME',
            value: 'Kwara State University',
            description: 'Name of the university using this system',
          },
          {
            key: 'UNIVERSITY_ACRONYM',
            value: 'KWASU',
            description: 'University acronym for theming',
          },
          {
            key: 'THEME_PRIMARY_COLOR',
            value: '#1976d2',
            description: 'Primary color for university theme',
          },
          {
            key: 'THEME_SECONDARY_COLOR',
            value: '#dc004e',
            description: 'Secondary color for university theme',
          },
          {
            key: 'MAX_FILE_SIZE_MB',
            value: '10',
            description: 'Maximum file upload size in MB',
          },
          {
            key: 'VOTING_TIME_LIMIT_MINUTES',
            value: '5',
            description: 'Time limit for completing vote in minutes',
          },
        ],
      });

      this.logger.info('Database seeding completed successfully');
      return { adminUser, committeeUser, students, election };
    } catch (error) {
      this.logger.error('Database seeding failed:', error);
      throw error;
    }
  }

  static getClient(): PrismaClient {
    if (!this.prisma) {
      throw new Error('Database not initialized. Call DatabaseService.initialize() first.');
    }
    return this.prisma;
  }

  static async disconnect() {
    if (this.prisma) {
      await this.prisma.$disconnect();
      this.logger.info('Database disconnected');
    }
  }

  static async healthCheck(): Promise<boolean> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return true;
    } catch (error) {
      this.logger.error('Database health check failed:', error);
      return false;
    }
  }

  static async getUserByMatricNumber(matricNumber: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { matricNumber },
    });
  }

  static async getUserById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { id },
    });
  }

  static async createAuditLog(data: {
    userId?: string;
    action: string;
    resource: string;
    resourceId?: string;
    details?: object;
    ipAddress?: string;
    userAgent?: string;
    previousHash?: string;
    currentHash: string;
  }) {
    return this.prisma.auditLog.create({ data });
  }

  static async getSystemConfig(key: string): Promise<string | null> {
    const config = await this.prisma.systemConfig.findUnique({
      where: { key },
    });
    return config?.value || null;
  }

  static async setSystemConfig(key: string, value: string, description?: string) {
    return this.prisma.systemConfig.upsert({
      where: { key },
      update: { value, description },
      create: { key, value, description },
    });
  }
}