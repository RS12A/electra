import { Router, Request, Response } from 'express';
import { DatabaseService } from '../services/DatabaseService';
import { SecurityService } from '../services/SecurityService';
import { LoggerService } from '../services/LoggerService';
import { EmailService } from '../services/EmailService';
import { 
  asyncHandler, 
  ValidationError, 
  AuthenticationError, 
  ConflictError,
  NotFoundError 
} from '../middleware/errorHandler';
import { detectSuspiciousActivity, optionalAuth } from '../middleware/auth';
import { logSpecificEvent } from '../middleware/auditLogger';
import { UserRole } from '../types/prisma';

const router = Router();
const logger = new LoggerService();

// Login endpoint
router.post('/login', detectSuspiciousActivity, asyncHandler(async (req: Request, res: Response) => {
  const { matricNumber, password, deviceId, biometricData } = req.body;

  // Validate required fields
  if (!matricNumber || !password) {
    throw new ValidationError('Matric number and password are required', {
      required: ['matricNumber', 'password'],
    });
  }

  // Get user from database
  const user = await DatabaseService.getUserByMatricNumber(matricNumber);
  
  if (!user) {
    // Log failed login attempt
    logger.logAuthenticationAttempt(matricNumber, false, req.ip, req.headers['user-agent']);
    
    await logSpecificEvent(
      req,
      'LOGIN_FAILED',
      'authentication',
      undefined,
      { reason: 'user_not_found', matricNumber }
    );

    throw new AuthenticationError('Invalid credentials', 'INVALID_CREDENTIALS');
  }

  // Check if user is active
  if (!user.isActive) {
    logger.logAuthenticationAttempt(matricNumber, false, req.ip, req.headers['user-agent']);
    
    await logSpecificEvent(
      req,
      'LOGIN_FAILED',
      'authentication',
      user.id,
      { reason: 'account_inactive', matricNumber }
    );

    throw new AuthenticationError('Account is inactive', 'ACCOUNT_INACTIVE');
  }

  // Verify password
  const isPasswordValid = await SecurityService.verifyPassword(user.passwordHash, password);
  
  if (!isPasswordValid) {
    logger.logAuthenticationAttempt(matricNumber, false, req.ip, req.headers['user-agent']);
    
    await logSpecificEvent(
      req,
      'LOGIN_FAILED',
      'authentication',
      user.id,
      { reason: 'invalid_password', matricNumber }
    );

    throw new AuthenticationError('Invalid credentials', 'INVALID_CREDENTIALS');
  }

  // Handle biometric authentication if provided
  let biometricValid = true;
  if (biometricData && user.biometricEnabled) {
    // In a real implementation, verify biometric data
    // For now, we'll assume it's valid if provided
    logger.info('Biometric authentication used', { userId: user.id });
  }

  if (!biometricValid) {
    throw new AuthenticationError('Biometric verification failed', 'BIOMETRIC_FAILED');
  }

  // Generate tokens
  const accessToken = SecurityService.generateJwtToken(user);
  const refreshToken = SecurityService.generateRefreshToken(user);

  // Store refresh token in database
  const db = DatabaseService.getClient();
  await db.refreshToken.create({
    data: {
      token: refreshToken,
      userId: user.id,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
    },
  });

  // Update user's last login and device info
  const updateData: any = {
    lastLogin: new Date(),
  };

  if (deviceId) {
    const deviceIds = user.deviceIds || [];
    if (!deviceIds.includes(deviceId)) {
      deviceIds.push(deviceId);
      updateData.deviceIds = deviceIds;
    }
  }

  await db.user.update({
    where: { id: user.id },
    data: updateData,
  });

  // Log successful login
  logger.logAuthenticationAttempt(matricNumber, true, req.ip, req.headers['user-agent']);
  
  await logSpecificEvent(
    req,
    'LOGIN_SUCCESS',
    'authentication',
    user.id,
    { 
      matricNumber, 
      role: user.role,
      biometricUsed: !!biometricData,
      deviceId: deviceId || null,
    }
  );

  // Return user data and tokens (excluding sensitive information)
  res.json({
    message: 'Login successful',
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
      biometricEnabled: user.biometricEnabled,
      isVerified: user.isVerified,
    },
    tokens: {
      accessToken,
      refreshToken,
      expiresIn: '15m',
    },
  });
}));

// Register endpoint
router.post('/register', detectSuspiciousActivity, asyncHandler(async (req: Request, res: Response) => {
  const {
    matricNumber,
    email,
    password,
    firstName,
    lastName,
    department,
    faculty,
    yearOfStudy,
  } = req.body;

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
      role: UserRole.STUDENT,
      isActive: true,
      isVerified: false,
      department: department || null,
      faculty: faculty || null,
      yearOfStudy: yearOfStudy || null,
    },
  });

  // Generate email verification token
  const verificationToken = SecurityService.generateSecureToken();
  
  await db.otpToken.create({
    data: {
      token: verificationToken,
      userId: newUser.id,
      purpose: 'EMAIL_VERIFICATION',
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
    },
  });

  // Send verification email
  try {
    await EmailService.sendVerificationEmail(email, firstName, verificationToken);
  } catch (error) {
    logger.warn('Failed to send verification email', error);
    // Don't fail registration if email fails
  }

  // Log registration
  await logSpecificEvent(
    req,
    'USER_REGISTERED',
    'user',
    newUser.id,
    { matricNumber, email, role: UserRole.STUDENT }
  );

  logger.info('User registered successfully', {
    userId: newUser.id,
    matricNumber,
    email,
  });

  res.status(201).json({
    message: 'Registration successful. Please check your email to verify your account.',
    user: {
      id: newUser.id,
      matricNumber: newUser.matricNumber,
      email: newUser.email,
      firstName: newUser.firstName,
      lastName: newUser.lastName,
      role: newUser.role,
      isVerified: newUser.isVerified,
    },
  });
}));

// Email verification endpoint
router.post('/verify-email', asyncHandler(async (req: Request, res: Response) => {
  const { token } = req.body;

  if (!token) {
    throw new ValidationError('Verification token is required');
  }

  const db = DatabaseService.getClient();

  // Find the verification token
  const otpToken = await db.otpToken.findUnique({
    where: { token },
    include: { user: true },
  });

  if (!otpToken || otpToken.purpose !== 'EMAIL_VERIFICATION') {
    throw new NotFoundError('Invalid verification token');
  }

  if (otpToken.isUsed) {
    throw new ValidationError('Verification token already used');
  }

  if (otpToken.expiresAt < new Date()) {
    throw new ValidationError('Verification token expired');
  }

  // Mark user as verified
  await db.user.update({
    where: { id: otpToken.userId },
    data: { isVerified: true },
  });

  // Mark token as used
  await db.otpToken.update({
    where: { id: otpToken.id },
    data: { 
      isUsed: true,
      usedAt: new Date(),
    },
  });

  // Log email verification
  await logSpecificEvent(
    req,
    'EMAIL_VERIFIED',
    'user',
    otpToken.userId,
    { email: otpToken.user.email }
  );

  logger.info('Email verified successfully', {
    userId: otpToken.userId,
    email: otpToken.user.email,
  });

  res.json({
    message: 'Email verified successfully',
    user: {
      id: otpToken.user.id,
      email: otpToken.user.email,
      isVerified: true,
    },
  });
}));

// Refresh token endpoint
router.post('/refresh', asyncHandler(async (req: Request, res: Response) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    throw new ValidationError('Refresh token is required');
  }

  // Verify refresh token
  const payload = await SecurityService.verifyRefreshToken(refreshToken);

  const db = DatabaseService.getClient();

  // Check if refresh token exists in database
  const tokenRecord = await db.refreshToken.findUnique({
    where: { token: refreshToken },
    include: { user: true },
  });

  if (!tokenRecord) {
    throw new AuthenticationError('Invalid refresh token', 'INVALID_REFRESH_TOKEN');
  }

  if (tokenRecord.expiresAt < new Date()) {
    // Remove expired token
    await db.refreshToken.delete({
      where: { id: tokenRecord.id },
    });
    throw new AuthenticationError('Refresh token expired', 'REFRESH_TOKEN_EXPIRED');
  }

  const user = tokenRecord.user;

  if (!user.isActive) {
    throw new AuthenticationError('User account is inactive', 'ACCOUNT_INACTIVE');
  }

  // Generate new tokens
  const newAccessToken = SecurityService.generateJwtToken(user);
  const newRefreshToken = SecurityService.generateRefreshToken(user);

  // Replace old refresh token with new one
  await db.refreshToken.update({
    where: { id: tokenRecord.id },
    data: {
      token: newRefreshToken,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
    },
  });

  logger.info('Token refreshed successfully', { userId: user.id });

  res.json({
    message: 'Token refreshed successfully',
    tokens: {
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiresIn: '15m',
    },
  });
}));

// Forgot password endpoint
router.post('/forgot-password', detectSuspiciousActivity, asyncHandler(async (req: Request, res: Response) => {
  const { email } = req.body;

  if (!email) {
    throw new ValidationError('Email is required');
  }

  const db = DatabaseService.getClient();
  const user = await db.user.findUnique({
    where: { email },
  });

  // Always return success to prevent email enumeration
  const successMessage = 'If the email address exists, you will receive password reset instructions.';

  if (!user) {
    await logSpecificEvent(
      req,
      'PASSWORD_RESET_REQUESTED',
      'authentication',
      undefined,
      { email, result: 'user_not_found' }
    );

    return res.json({ message: successMessage });
  }

  // Generate reset token
  const resetToken = SecurityService.generateSecureToken();
  
  await db.otpToken.create({
    data: {
      token: resetToken,
      userId: user.id,
      purpose: 'PASSWORD_RESET',
      expiresAt: new Date(Date.now() + 60 * 60 * 1000), // 1 hour
    },
  });

  // Send reset email
  try {
    await EmailService.sendPasswordResetEmail(email, user.firstName, resetToken);
    
    await logSpecificEvent(
      req,
      'PASSWORD_RESET_REQUESTED',
      'authentication',
      user.id,
      { email, result: 'email_sent' }
    );

    logger.info('Password reset email sent', { userId: user.id, email });
  } catch (error) {
    logger.error('Failed to send password reset email', error);
    
    await logSpecificEvent(
      req,
      'PASSWORD_RESET_REQUESTED',
      'authentication',
      user.id,
      { email, result: 'email_failed' }
    );
  }

  res.json({ message: successMessage });
}));

// Reset password endpoint
router.post('/reset-password', asyncHandler(async (req: Request, res: Response) => {
  const { token, newPassword } = req.body;

  if (!token || !newPassword) {
    throw new ValidationError('Reset token and new password are required');
  }

  if (newPassword.length < 8) {
    throw new ValidationError('Password must be at least 8 characters long');
  }

  const db = DatabaseService.getClient();

  // Find the reset token
  const otpToken = await db.otpToken.findUnique({
    where: { token },
    include: { user: true },
  });

  if (!otpToken || otpToken.purpose !== 'PASSWORD_RESET') {
    throw new NotFoundError('Invalid reset token');
  }

  if (otpToken.isUsed) {
    throw new ValidationError('Reset token already used');
  }

  if (otpToken.expiresAt < new Date()) {
    throw new ValidationError('Reset token expired');
  }

  // Hash new password
  const passwordHash = await SecurityService.hashPassword(newPassword);

  // Update user password
  await db.user.update({
    where: { id: otpToken.userId },
    data: { passwordHash },
  });

  // Mark token as used
  await db.otpToken.update({
    where: { id: otpToken.id },
    data: { 
      isUsed: true,
      usedAt: new Date(),
    },
  });

  // Invalidate all refresh tokens for this user
  await db.refreshToken.deleteMany({
    where: { userId: otpToken.userId },
  });

  // Log password reset
  await logSpecificEvent(
    req,
    'PASSWORD_RESET_COMPLETED',
    'authentication',
    otpToken.userId,
    { email: otpToken.user.email }
  );

  logger.info('Password reset successfully', {
    userId: otpToken.userId,
    email: otpToken.user.email,
  });

  res.json({
    message: 'Password reset successfully. Please log in with your new password.',
  });
}));

// Logout endpoint
router.post('/logout', optionalAuth, asyncHandler(async (req: Request, res: Response) => {
  const { refreshToken } = req.body;

  if (refreshToken) {
    const db = DatabaseService.getClient();
    
    // Remove refresh token from database
    await db.refreshToken.deleteMany({
      where: { token: refreshToken },
    });
  }

  // Log logout
  if (req.user) {
    await logSpecificEvent(
      req,
      'LOGOUT',
      'authentication',
      req.user.id,
      { matricNumber: req.user.matricNumber }
    );

    logger.info('User logged out', { userId: req.user.id });
  }

  res.json({
    message: 'Logged out successfully',
  });
}));

// Logout from all devices
router.post('/logout-all', optionalAuth, asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) {
    throw new AuthenticationError('Authentication required');
  }

  const db = DatabaseService.getClient();
  
  // Remove all refresh tokens for this user
  await db.refreshToken.deleteMany({
    where: { userId: req.user.id },
  });

  // Log logout from all devices
  await logSpecificEvent(
    req,
    'LOGOUT_ALL_DEVICES',
    'authentication',
    req.user.id,
    { matricNumber: req.user.matricNumber }
  );

  logger.info('User logged out from all devices', { userId: req.user.id });

  res.json({
    message: 'Logged out from all devices successfully',
  });
}));

export default router;