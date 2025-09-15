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
  logger.info('Creating admin and electoral committee users...');
  
  const db = DatabaseService.getClient();
  
  // Create admin user if not exists
  const existingAdmin = await DatabaseService.getUserByMatricNumber('ADMIN001');
  if (!existingAdmin) {
    const adminPassword = process.env.ADMIN_DEFAULT_PASSWORD || 'SecureAdmin123!';
    const hashedPassword = await SecurityService.hashPassword(adminPassword);
    
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
    
    logger.info(`Admin user created: ${adminUser.email} / ${adminPassword}`);
  } else {
    logger.info('Admin user already exists');
  }
  
  // Create electoral committee user if not exists
  const existingEC = await DatabaseService.getUserByMatricNumber('EC001');
  if (!existingEC) {
    const ecPassword = 'SecureEC123!';
    const hashedPassword = await SecurityService.hashPassword(ecPassword);
    
    const ecUser = await db.user.create({
      data: {
        matricNumber: 'EC001',
        email: 'electoral.committee@kwasu.edu.ng',
        passwordHash: hashedPassword,
        firstName: 'Electoral',
        lastName: 'Committee',
        role: UserRole.ELECTORAL_COMMITTEE,
        isActive: true,
        isVerified: true,
        faculty: 'Administration',
        department: 'Student Affairs'
      }
    });
    
    logger.info(`Electoral Committee user created: ${ecUser.email} / ${ecPassword}`);
  } else {
    logger.info('Electoral Committee user already exists');
  }
}

async function seedSampleElection() {
  logger.info('Creating sample election data...');
  
  const db = DatabaseService.getClient();
  
  // Create sample students from different faculties
  const studentData = [
    { matric: 'KWS/18/CSC/001', email: 'john.doe@student.kwasu.edu.ng', name: 'John Doe', faculty: 'School of ICT', dept: 'Computer Science', year: 4 },
    { matric: 'KWS/19/CSC/102', email: 'jane.smith@student.kwasu.edu.ng', name: 'Jane Smith', faculty: 'School of ICT', dept: 'Computer Science', year: 3 },
    { matric: 'KWS/20/ENG/203', email: 'mike.johnson@student.kwasu.edu.ng', name: 'Michael Johnson', faculty: 'School of Engineering', dept: 'Electrical Engineering', year: 2 },
    { matric: 'KWS/18/BUS/304', email: 'sarah.wilson@student.kwasu.edu.ng', name: 'Sarah Wilson', faculty: 'School of Management Sciences', dept: 'Business Administration', year: 4 },
    { matric: 'KWS/17/MED/405', email: 'david.brown@student.kwasu.edu.ng', name: 'David Brown', faculty: 'School of Medicine', dept: 'Medicine', year: 5 },
  ];
  
  const students = [];
  for (const data of studentData) {
    // Check if student already exists
    const existing = await DatabaseService.getUserByMatricNumber(data.matric);
    if (existing) {
      students.push(existing);
      continue;
    }
    
    const [firstName, lastName] = data.name.split(' ');
    const hashedPassword = await SecurityService.hashPassword('Password123!');
    
    const student = await db.user.create({
      data: {
        matricNumber: data.matric,
        email: data.email,
        passwordHash: hashedPassword,
        firstName,
        lastName,
        role: UserRole.STUDENT,
        isActive: true,
        isVerified: true,
        faculty: data.faculty,
        department: data.dept,
        yearOfStudy: data.year
      }
    });
    
    students.push(student);
    logger.info(`Created student: ${data.name} (${data.matric})`);
  }
  
  // Create sample elections
  const adminUser = await DatabaseService.getUserByMatricNumber('ADMIN001');
  
  if (!adminUser) {
    logger.error('Admin user not found, cannot create elections');
    return;
  }
  
  const elections = [
    {
      title: 'Student Union Government Elections 2024',
      description: 'Annual election for Student Union Government positions including President, Vice President, Secretary General, and other executive positions.',
      category: 'Student Union',
      startDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
      endDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000), // 10 days from now
      eligibleFaculties: [],
      eligibleYears: [2, 3, 4, 5],
    },
    {
      title: 'School of ICT Representative Election',
      description: 'Election for School of ICT representative to the Academic Board.',
      category: 'Faculty Representative',
      startDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000), // 14 days from now
      endDate: new Date(Date.now() + 16 * 24 * 60 * 60 * 1000), // 16 days from now
      eligibleFaculties: ['School of ICT'],
      eligibleYears: [1, 2, 3, 4],
    },
  ];
  
  for (const electionData of elections) {
    // Check if election already exists
    const existing = await db.election.findFirst({
      where: { title: electionData.title }
    });
    
    if (existing) {
      logger.info(`Election already exists: ${electionData.title}`);
      continue;
    }
    
    const election = await db.election.create({
      data: {
        ...electionData,
        isActive: false, // Will be activated manually
        allowDelayedReveal: false,
        maxVotesPerUser: 1,
        createdById: adminUser.id
      }
    });
    
    // Create sample candidates for first election
    if (electionData.title.includes('Student Union')) {
      // Get eligible students
      const eligibleStudents = students.filter(s => 
        electionData.eligibleYears.includes(s.yearOfStudy || 0)
      ).slice(0, 3); // First 3 eligible students
      
      for (let i = 0; i < Math.min(2, eligibleStudents.length); i++) {
        const student = eligibleStudents[i];
        
        await db.candidate.create({
          data: {
            electionId: election.id,
            userId: student.id,
            manifesto: `I, ${student.firstName} ${student.lastName}, am running for Student Union Government with a vision to transform our university experience. My key priorities include improving student welfare services, enhancing academic support systems, promoting extracurricular activities, and ensuring transparent communication between students and administration. With my experience in leadership and commitment to service, I pledge to be your voice and advocate for positive change that benefits every student in our university community.`,
            isApproved: true, // Pre-approved for demo
            voteCount: 0
          }
        });
        
        logger.info(`Created candidate: ${student.firstName} ${student.lastName} for ${election.title}`);
      }
    }
    
    logger.info(`Created election: ${election.title}`);
  }
  
  logger.info('Sample election data creation completed');
}

// Run seeding
if (require.main === module) {
  seedDatabase();
}