import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/errorHandler';
import { requireAdmin, requireStudent } from '../middleware/auth';
import { DatabaseService } from '../services/DatabaseService';
import { LoggerService } from '../services/LoggerService';

const router = Router();
const logger = new LoggerService();

// Get current user profile
router.get('/profile', asyncHandler(async (req: Request, res: Response) => {
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
    },
  });

  res.json({
    message: 'Profile retrieved successfully',
    user: userProfile,
  });
}));

// Update user profile
router.put('/profile', asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { firstName, lastName, department, faculty, yearOfStudy } = req.body;

  const db = DatabaseService.getClient();
  const updatedUser = await db.user.update({
    where: { id: userId },
    data: {
      firstName: firstName || undefined,
      lastName: lastName || undefined,
      department: department || undefined,
      faculty: faculty || undefined,
      yearOfStudy: yearOfStudy || undefined,
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
      biometricEnabled: true,
    },
  });

  logger.info('User profile updated', { userId });

  res.json({
    message: 'Profile updated successfully',
    user: updatedUser,
  });
}));

// Enable/disable biometric authentication
router.post('/biometric', asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { enabled } = req.body;

  const db = DatabaseService.getClient();
  await db.user.update({
    where: { id: userId },
    data: { biometricEnabled: enabled === true },
  });

  logger.info('Biometric setting updated', { userId, enabled });

  res.json({
    message: `Biometric authentication ${enabled ? 'enabled' : 'disabled'} successfully`,
    biometricEnabled: enabled === true,
  });
}));

// Get all users (admin only)
router.get('/', requireAdmin, asyncHandler(async (req: Request, res: Response) => {
  const { page = 1, limit = 20, role, faculty, search } = req.query;
  
  const skip = (Number(page) - 1) * Number(limit);
  const take = Number(limit);

  const where: any = {};
  
  if (role) where.role = role;
  if (faculty) where.faculty = faculty;
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
        lastLogin: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    }),
    db.user.count({ where }),
  ]);

  res.json({
    message: 'Users retrieved successfully',
    users,
    pagination: {
      page: Number(page),
      limit: Number(limit),
      total,
      pages: Math.ceil(total / Number(limit)),
    },
  });
}));

// Get user by ID (admin only)
router.get('/:userId', requireAdmin, asyncHandler(async (req: Request, res: Response) => {
  const { userId } = req.params;

  const db = DatabaseService.getClient();
  const user = await db.user.findUnique({
    where: { id: userId },
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
      deviceIds: true,
      lastLogin: true,
      createdAt: true,
      updatedAt: true,
    },
  });

  if (!user) {
    return res.status(404).json({
      error: 'User not found',
      message: 'The requested user does not exist',
    });
  }

  res.json({
    message: 'User retrieved successfully',
    user,
  });
}));

export default router;