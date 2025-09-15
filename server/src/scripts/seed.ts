import { DatabaseService } from '../services/DatabaseService';
import { SecurityService } from '../services/SecurityService';
import { LoggerService } from '../services/LoggerService';
import { UserRole } from '../types/prisma';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const logger = new LoggerService();

async function seedDatabase() {
  try {
    logger.info('Starting database seeding...');
    
    await DatabaseService.initialize();
    
    // Seed system configuration
    await seedSystemConfig();
    
    // Seed admin user
    await seedAdminUser();
    
    // Seed sample election data (for development)
    if (process.env.NODE_ENV === 'development') {
      await seedSampleElection();
    }
    
    logger.info('Database seeding completed successfully!');
    
  } catch (error) {
    logger.error('Database seeding failed:', error);
    process.exit(1);
  } finally {
    await DatabaseService.disconnect();
  }
}

async function seedSystemConfig() {
  logger.info('Seeding system configuration...');
  
  const configs = [
    {
      key: 'UNIVERSITY_NAME',
      value: 'Kwara State University',
      description: 'Full name of the university'
    },
    {
      key: 'UNIVERSITY_ACRONYM',
      value: 'KWASU',
      description: 'University acronym for branding'
    },
    {
      key: 'THEME_PRIMARY_COLOR',
      value: '#1B4332',
      description: 'Primary brand color for KWASU theme'
    },
    {
      key: 'THEME_SECONDARY_COLOR',
      value: '#40916C',
      description: 'Secondary brand color for KWASU theme'
    },
    {
      key: 'THEME_ACCENT_COLOR',
      value: '#95D5B2',
      description: 'Accent color for KWASU theme'
    },
    {
      key: 'MAX_CONCURRENT_ELECTIONS',
      value: '5',
      description: 'Maximum number of concurrent elections'
    },
    {
      key: 'VOTE_ENCRYPTION_ENABLED',
      value: 'true',
      description: 'Enable vote encryption (production should be true)'
    }
  ];

  for (const config of configs) {
    await DatabaseService.setSystemConfig(config.key, config.value, config.description);
  }
  
  logger.info(`Seeded ${configs.length} system configuration entries`);
}

async function seedAdminUser() {
  logger.info('Creating admin user...');
  
  // Check if admin already exists
  const existingAdmin = await DatabaseService.getUserByMatricNumber('ADMIN001');
  if (existingAdmin) {
    logger.info('Admin user already exists, skipping creation');
    return;
  }
  
  const adminPassword = process.env.ADMIN_DEFAULT_PASSWORD || 'Admin@123';
  const hashedPassword = await SecurityService.hashPassword(adminPassword);
  
  const db = DatabaseService.getClient();
  const adminUser = await db.user.create({
    data: {
      matricNumber: 'ADMIN001',
      email: process.env.ADMIN_EMAIL || 'admin@kwasu.edu.ng',
      passwordHash: hashedPassword,
      firstName: 'System',
      lastName: 'Administrator',
      role: UserRole.ADMIN,
      isActive: true,
      isVerified: true,
      faculty: 'Administration',
      department: 'IT Services'
    }
  });
  
  logger.info(`Admin user created with ID: ${adminUser.id}`);
  logger.info(`Default admin credentials:`);
  logger.info(`  Matric: ADMIN001`);
  logger.info(`  Email: ${adminUser.email}`);
  logger.info(`  Password: ${adminPassword}`);
  logger.info(`⚠️  CHANGE THE DEFAULT PASSWORD IMMEDIATELY IN PRODUCTION!`);
}

async function seedSampleElection() {
  logger.info('Creating sample election data...');
  
  const db = DatabaseService.getClient();
  
  // Create sample students
  const students = [];
  for (let i = 1; i <= 5; i++) {
    const studentPassword = `Student${i}@123`;
    const hashedPassword = await SecurityService.hashPassword(studentPassword);
    
    const student = await db.user.create({
      data: {
        matricNumber: `KWASU/2023/${i.toString().padStart(4, '0')}`,
        email: `student${i}@kwasu.edu.ng`,
        passwordHash: hashedPassword,
        firstName: `Student`,
        lastName: `Number${i}`,
        role: UserRole.STUDENT,
        isActive: true,
        isVerified: true,
        faculty: 'Engineering',
        department: 'Computer Science',
        yearOfStudy: 3
      }
    });
    
    students.push(student);
  }
  
  // Create sample election
  const adminUser = await DatabaseService.getUserByMatricNumber('ADMIN001');
  
  const election = await db.election.create({
    data: {
      title: 'Student Union President Election 2024',
      description: 'Annual election for Student Union President position',
      category: 'Student Union',
      startDate: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
      endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // Next week
      isActive: false, // Will be activated manually
      allowDelayedReveal: false,
      maxVotesPerUser: 1,
      eligibleFaculties: ['Engineering', 'Sciences', 'Law', 'Medicine'],
      eligibleYears: [2, 3, 4, 5],
      createdById: adminUser!.id
    }
  });
  
  // Create sample candidates
  const candidates = [];
  for (let i = 0; i < 2; i++) {
    const candidate = await db.candidate.create({
      data: {
        electionId: election.id,
        userId: students[i].id,
        manifesto: `I am ${students[i].firstName} ${students[i].lastName}, and I promise to represent all students with integrity and dedication. My key promises include: 1) Better student facilities, 2) Improved communication between administration and students, 3) More extracurricular activities.`,
        isApproved: true,
        voteCount: 0
      }
    });
    
    candidates.push(candidate);
  }
  
  logger.info(`Created sample election: ${election.title}`);
  logger.info(`Created ${students.length} sample students`);
  logger.info(`Created ${candidates.length} sample candidates`);
}

// Run seeding
if (require.main === module) {
  seedDatabase();
}