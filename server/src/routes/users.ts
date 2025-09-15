import { Router, Request, Response } from 'express';
import { asyncHandler, ValidationError, NotFoundError, ConflictError } from '../middleware/errorHandler';
import { requireAdmin, requireCommitteeOrAdmin, requireAuth } from '../middleware/auth';
import { DatabaseService } from '../services/DatabaseService';
import { SecurityService } from '../services/SecurityService';
import { EmailService } from '../services/EmailService';
import { LoggerService } from '../services/LoggerService';
import { logSpecificEvent } from '../middleware/auditLogger';
import { UserRole } from '../types/prisma';

const router = Router();
const logger = new LoggerService();

// Get current user profile
router.get('/profile', requireAuth, asyncHandler(async (req: Request, res: Response) => {
  const user = req.user!;
  
  const db = DatabaseService.getClient();
  const userProfile = await db.user.findUnique({
    where: { id: user.id },
    select: {
      id: true,
      matricNumber: true,
      email: true,
      firstName: true,
      lastName: true,
      role: true,
      department: true,
      faculty: true,
      yearOfStudy: true,
      isActive: true,
      isVerified: true,
      biometricEnabled: true,
      lastLogin: true,
      createdAt: true,
      deviceIds: true,
    },
  });

  if (!userProfile) {
    throw new NotFoundError('User profile not found');
  }

  // Get user's voting history count (without revealing details)
  const voteCount = await db.vote.count({
    where: { voterId: user.id }
  });

  // Get user's candidate applications
  const candidateApplications = await db.candidate.findMany({
    where: { userId: user.id },
    include: {
      election: {
        select: {
          id: true,
          title: true,
          category: true,
          startDate: true,
          endDate: true,
        }
      }
    }
  });

  res.json({
    message: 'Profile retrieved successfully',
    user: {
      ...userProfile,
      statistics: {
        votesCount: voteCount,
        candidateApplications: candidateApplications.length,
      },
      candidateApplications: candidateApplications.map((app: any) => ({
        id: app.id,
        election: app.election,
        isApproved: app.isApproved,
        createdAt: app.createdAt,
      })),
    },
  });
}));

// Update user profile
router.put('/profile', requireAuth, asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { firstName, lastName, department, faculty, yearOfStudy } = req.body;

  // Validate input
  if (firstName && firstName.length < 2) {
    throw new ValidationError('First name must be at least 2 characters');
  }
  if (lastName && lastName.length < 2) {
    throw new ValidationError('Last name must be at least 2 characters');
  }
  if (yearOfStudy && (yearOfStudy < 1 || yearOfStudy > 7)) {
    throw new ValidationError('Year of study must be between 1 and 7');
  }

  const updateData: any = {};
  if (firstName) updateData.firstName = firstName;
  if (lastName) updateData.lastName = lastName;
  if (department) updateData.department = department;
  if (faculty) updateData.faculty = faculty;
  if (yearOfStudy) updateData.yearOfStudy = yearOfStudy;

  const db = DatabaseService.getClient();
  const updatedUser = await db.user.update({
    where: { id: userId },
    data: updateData,
    select: {
      id: true,
      matricNumber: true,
      email: true,
      firstName: true,
      lastName: true,
      role: true,
      department: true,
      faculty: true,
      yearOfStudy: true,
      isActive: true,
      isVerified: true,
      biometricEnabled: true,
      updatedAt: true,
    },
  });

  // Log profile update
  await logSpecificEvent(
    req,
    'USER_PROFILE_UPDATED',
    'user',
    userId,
    { changes: Object.keys(updateData) }
  );

  logger.info('User profile updated', { 
    userId, 
    changes: Object.keys(updateData) 
  });

  res.json({
    message: 'Profile updated successfully',
    user: updatedUser,
  });
}));

// Change password
router.post('/change-password', requireAuth, asyncHandler(async (req: Request, res: Response) => {
  const { currentPassword, newPassword } = req.body;
  const userId = req.user!.id;

  if (!currentPassword || !newPassword) {
    throw new ValidationError('Current password and new password are required');
  }

  if (newPassword.length < 8) {
    throw new ValidationError('New password must be at least 8 characters long');
  }

  const db = DatabaseService.getClient();
  const user = await db.user.findUnique({
    where: { id: userId }
  });

  if (!user) {
    throw new NotFoundError('User not found');
  }

  // Verify current password
  const isCurrentPasswordValid = await SecurityService.verifyPassword(user.passwordHash, currentPassword);
  if (!isCurrentPasswordValid) {
    throw new ValidationError('Current password is incorrect');
  }

  // Hash new password
  const newPasswordHash = await SecurityService.hashPassword(newPassword);

  // Update password
  await db.user.update({
    where: { id: userId },
    data: { passwordHash: newPasswordHash }
  });

  // Invalidate all refresh tokens to force re-login on all devices
  await db.refreshToken.deleteMany({
    where: { userId }
  });

  // Log password change
  await logSpecificEvent(
    req,
    'USER_PASSWORD_CHANGED',
    'user',
    userId,
    {}
  );

  logger.info('User password changed', { userId });

  res.json({
    message: 'Password changed successfully. Please log in again on all devices.',
  });
}));

// Enable/disable biometric authentication
router.post('/biometric', requireAuth, asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { enabled, biometricData } = req.body;

  if (typeof enabled !== 'boolean') {
    throw new ValidationError('enabled must be a boolean value');
  }

  // If enabling biometric auth, require biometric data for verification
  if (enabled && !biometricData) {
    throw new ValidationError('Biometric data is required to enable biometric authentication');
  }

  const db = DatabaseService.getClient();
  
  const updateData: any = { biometricEnabled: enabled };
  
  // In a real implementation, you would verify and store biometric data
  // For now, we just store the enabled state
  
  await db.user.update({
    where: { id: userId },
    data: updateData,
  });

  // Log biometric setting change
  await logSpecificEvent(
    req,
    'USER_BIOMETRIC_SETTING_CHANGED',
    'user',
    userId,
    { enabled }
  );

  logger.info('Biometric setting updated', { userId, enabled });

  res.json({
    message: `Biometric authentication ${enabled ? 'enabled' : 'disabled'} successfully`,
    biometricEnabled: enabled,
  });
}));

// Get user notifications
router.get('/notifications', requireAuth, asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { page = 1, limit = 20, unreadOnly = 'false' } = req.query;

  // TODO: Implement actual notifications system
  // For now, return mock data based on user activity
  
  const db = DatabaseService.getClient();
  
  // Get recent elections user is eligible for
  const user = await db.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw new NotFoundError('User not found');
  }

  const eligibleElections = await db.election.findMany({
    where: {
      OR: [
        { eligibleFaculties: { isEmpty: true } },
        { eligibleFaculties: { has: user.faculty } },
      ],
      AND: [
        {
          OR: [
            { eligibleYears: { isEmpty: true } },
            { eligibleYears: { has: user.yearOfStudy } },
          ]
        }
      ],
      startDate: { gte: new Date() }, // Upcoming elections
    },
    take: 5,
    orderBy: { startDate: 'asc' }
  });

  // Generate notification-like data
  const notifications = eligibleElections.map((election: any) => ({
    id: `election-${election.id}`,
    type: 'election_announcement',
    title: `New Election: ${election.title}`,
    message: `You are eligible to vote in the ${election.category} election starting ${election.startDate.toLocaleDateString()}`,
    isRead: false,
    createdAt: election.createdAt,
    data: {
      electionId: election.id,
      category: election.category,
    }
  }));

  res.json({
    message: 'Notifications retrieved successfully',
    notifications,
    pagination: {
      page: Number(page),
      limit: Number(limit),
      total: notifications.length,
      pages: Math.ceil(notifications.length / Number(limit)),
    }
  });
}));

// Get all users (admin only)
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.get('/', requireCommitteeOrAdmin, asyncHandler(async (req: Request, res: Response) => {
  const { page = 1, limit = 20, role, faculty, search, isActive, isVerified } = req.query;
  
  const skip = (Number(page) - 1) * Number(limit);
  const take = Number(limit);

  const where: any = {};
  
  if (role) where.role = role;
  if (faculty) where.faculty = faculty;
  if (isActive !== undefined) where.isActive = isActive === 'true';
  if (isVerified !== undefined) where.isVerified = isVerified === 'true';
  
  if (search) {
    where.OR = [
      { firstName: { contains: search as string, mode: 'insensitive' } },
      { lastName: { contains: search as string, mode: 'insensitive' } },
      { matricNumber: { contains: search as string, mode: 'insensitive' } },
      { email: { contains: search as string, mode: 'insensitive' } },
    ];
  }

  const db = DatabaseService.getClient();
  
  const [users, total] = await Promise.all([
    db.user.findMany({
      where,
      skip,
      take,
      select: {
        id: true,
        matricNumber: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        department: true,
        faculty: true,
        yearOfStudy: true,
        isActive: true,
        isVerified: true,
        biometricEnabled: true,
        lastLogin: true,
        createdAt: true,
        _count: {
          select: {
            votes: true,
            candidacies: true,
          }
        }
      },
      orderBy: { createdAt: 'desc' },
    }),
    db.user.count({ where }),
  ]);

  res.json({
    message: 'Users retrieved successfully',
    users: users.map((user: any) => ({
      ...user,
      statistics: {
        votesCount: user._count.votes,
        candidaciesCount: user._count.candidacies,
      },
      _count: undefined,
    })),
    pagination: {
      page: Number(page),
      limit: Number(limit),
      total,
      pages: Math.ceil(total / Number(limit)),
    },
  });
}));

// Get user by ID (admin only)
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.get('/:userId', requireCommitteeOrAdmin, asyncHandler(async (req: Request, res: Response) => {
  const { userId } = req.params;

  const db = DatabaseService.getClient();
  const user = await db.user.findUnique({
    where: { id: userId },
    include: {
      candidacies: {
        include: {
          election: {
            select: {
              id: true,
              title: true,
              category: true,
              startDate: true,
              endDate: true,
            }
          }
        }
      },
      _count: {
        select: {
          votes: true,
          candidacies: true,
          auditLogs: true,
        }
      }
    }
  });

  if (!user) {
    throw new NotFoundError('User not found');
  }

  // Get recent activity
  const recentAuditLogs = await db.auditLog.findMany({
    where: { userId: user.id },
    take: 10,
    orderBy: { createdAt: 'desc' },
    select: {
      action: true,
      resource: true,
      createdAt: true,
      ipAddress: true,
    }
  });

  res.json({
    message: 'User retrieved successfully',
    user: {
      id: user.id,
      matricNumber: user.matricNumber,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      department: user.department,
      faculty: user.faculty,
      yearOfStudy: user.yearOfStudy,
      isActive: user.isActive,
      isVerified: user.isVerified,
      biometricEnabled: user.biometricEnabled,
      deviceIds: user.deviceIds,
      lastLogin: user.lastLogin,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      statistics: {
        votesCount: user._count.votes,
        candidaciesCount: user._count.candidacies,
        auditLogsCount: user._count.auditLogs,
      },
      candidacies: user.candidacies.map((candidacy: any) => ({
        id: candidacy.id,
        election: candidacy.election,
        isApproved: candidacy.isApproved,
        voteCount: candidacy.voteCount,
        createdAt: candidacy.createdAt,
      })),
      recentActivity: recentAuditLogs,
    },
  });
}));

// Update user (admin only)
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.put('/:userId', requireAdmin, asyncHandler(async (req: Request, res: Response) => {
  const { userId } = req.params;
  const { role, isActive, isVerified, department, faculty, yearOfStudy } = req.body;
  const adminUser = req.user!;

  const db = DatabaseService.getClient();

  // Check if user exists
  const existingUser = await db.user.findUnique({
    where: { id: userId }
  });

  if (!existingUser) {
    throw new NotFoundError('User not found');
  }

  // Prepare update data
  const updateData: any = {};
  if (role && Object.values(UserRole).includes(role)) {
    updateData.role = role;
  }
  if (isActive !== undefined) updateData.isActive = isActive;
  if (isVerified !== undefined) updateData.isVerified = isVerified;
  if (department) updateData.department = department;
  if (faculty) updateData.faculty = faculty;
  if (yearOfStudy) updateData.yearOfStudy = yearOfStudy;

  const updatedUser = await db.user.update({
    where: { id: userId },
    data: updateData,
    select: {
      id: true,
      matricNumber: true,
      email: true,
      firstName: true,
      lastName: true,
      role: true,
      department: true,
      faculty: true,
      yearOfStudy: true,
      isActive: true,
      isVerified: true,
      updatedAt: true,
    },
  });

  // Log user update
  await logSpecificEvent(
    req,
    'USER_UPDATED_BY_ADMIN',
    'user',
    adminUser.id,
    { 
      targetUserId: userId,
      changes: Object.keys(updateData),
      newRole: role || null,
    }
  );

  logger.info('User updated by admin', {
    targetUserId: userId,
    adminUserId: adminUser.id,
    changes: Object.keys(updateData),
  });

  res.json({
    message: 'User updated successfully',
    user: updatedUser,
  });
}));

// Create new user (admin only)
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.post('/', requireAdmin, asyncHandler(async (req: Request, res: Response) => {
  const {
    matricNumber,
    email,
    password,
    firstName,
    lastName,
    role = UserRole.STUDENT,
    department,
    faculty,
    yearOfStudy,
  } = req.body;
  const adminUser = req.user!;

  // Validate required fields
  const requiredFields = ['matricNumber', 'email', 'password', 'firstName', 'lastName'];
  const missingFields = requiredFields.filter(field => !req.body[field]);
  
  if (missingFields.length > 0) {
    throw new ValidationError('Required fields are missing', {
      missingFields,
    });
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new ValidationError('Invalid email format');
  }

  // Validate password strength
  if (password.length < 8) {
    throw new ValidationError('Password must be at least 8 characters long');
  }

  // Validate role
  if (!Object.values(UserRole).includes(role)) {
    throw new ValidationError('Invalid user role');
  }

  const db = DatabaseService.getClient();

  // Check if user already exists
  const existingUser = await db.user.findFirst({
    where: {
      OR: [
        { matricNumber },
        { email },
      ],
    },
  });

  if (existingUser) {
    if (existingUser.matricNumber === matricNumber) {
      throw new ConflictError('Matric number already registered');
    } else {
      throw new ConflictError('Email address already registered');
    }
  }

  // Hash password
  const passwordHash = await SecurityService.hashPassword(password);

  // Create user
  const newUser = await db.user.create({
    data: {
      matricNumber,
      email,
      passwordHash,
      firstName,
      lastName,
      role,
      isActive: true,
      isVerified: true, // Admin-created users are pre-verified
      department: department || null,
      faculty: faculty || null,
      yearOfStudy: yearOfStudy || null,
    },
    select: {
      id: true,
      matricNumber: true,
      email: true,
      firstName: true,
      lastName: true,
      role: true,
      department: true,
      faculty: true,
      yearOfStudy: true,
      isActive: true,
      isVerified: true,
      createdAt: true,
    },
  });

  // Log user creation
  await logSpecificEvent(
    req,
    'USER_CREATED_BY_ADMIN',
    'user',
    adminUser.id,
    { 
      newUserId: newUser.id,
      matricNumber,
      email,
      role,
    }
  );

  logger.info('User created by admin', {
    newUserId: newUser.id,
    adminUserId: adminUser.id,
    matricNumber,
    email,
    role,
  });

  // Send welcome email
  try {
    await EmailService.sendWelcomeEmail(email, firstName, password);
  } catch (error) {
    logger.warn('Failed to send welcome email', error);
    // Don't fail user creation if email fails
  }

  res.status(201).json({
    message: 'User created successfully',
    user: newUser,
  });
}));

// Delete user (admin only)
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.delete('/:userId', requireAdmin, asyncHandler(async (req: Request, res: Response) => {
  const { userId } = req.params;
  const adminUser = req.user!;

  if (userId === adminUser.id) {
    throw new ValidationError('Cannot delete your own account');
  }

  const db = DatabaseService.getClient();

  const user = await db.user.findUnique({
    where: { id: userId },
    include: {
      _count: {
        select: {
          votes: true,
          candidacies: true,
        }
      }
    }
  });

  if (!user) {
    throw new NotFoundError('User not found');
  }

  // Check if user has voted or has candidacies
  if (user._count.votes > 0 || user._count.candidacies > 0) {
    throw new ValidationError('Cannot delete user with voting history or candidacies. Consider deactivating instead.');
  }

  await db.user.delete({
    where: { id: userId }
  });

  // Log user deletion
  await logSpecificEvent(
    req,
    'USER_DELETED_BY_ADMIN',
    'user',
    adminUser.id,
    { 
      deletedUserId: userId,
      deletedUserMatric: user.matricNumber,
      deletedUserEmail: user.email,
    }
  );

  logger.info('User deleted by admin', {
    deletedUserId: userId,
    adminUserId: adminUser.id,
    matricNumber: user.matricNumber,
  });

  res.json({
    message: 'User deleted successfully',
  });
}));

export default router;