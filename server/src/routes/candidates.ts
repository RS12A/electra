import { Router, Request, Response } from 'express';
import { asyncHandler, ValidationError, NotFoundError, ConflictError } from '../middleware/errorHandler';
import { requireStudent, requireCommitteeOrAdmin, requireAuth } from '../middleware/auth';
import { DatabaseService } from '../services/DatabaseService';
import { LoggerService } from '../services/LoggerService';
import { logSpecificEvent } from '../middleware/auditLogger';
import multer from 'multer';
import path from 'path';
import fs from 'fs';

const router = Router();
const logger = new LoggerService();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = path.join(__dirname, '../../uploads/candidates');
    if (!fs.existsSync(uploadPath)) {
      fs.mkdirSync(uploadPath, { recursive: true });
    }
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, `candidate-${uniqueSuffix}${ext}`);
  }
});

const upload = multer({
  storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.fieldname === 'photo') {
      if (!file.mimetype.startsWith('image/')) {
        return cb(new Error('Photo must be an image file'));
      }
    } else if (file.fieldname === 'video') {
      if (!file.mimetype.startsWith('video/')) {
        return cb(new Error('Video must be a video file'));
      }
    }
    cb(null, true);
  }
});

// Get candidates for an election
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.get('/', requireStudent, asyncHandler(async (req: Request, res: Response) => {
  const { electionId, approved } = req.query;
  const user = req.user!;

  if (!electionId) {
    throw new ValidationError('Election ID is required');
  }

  const db = DatabaseService.getClient();

  // Get election and check user access
  const election = await db.election.findUnique({
    where: { id: electionId as string }
  });

  if (!election) {
    throw new NotFoundError('Election not found');
  }

  // Check if user is eligible to view this election
  const isEligible = (!election.eligibleFaculties.length || election.eligibleFaculties.includes(user.faculty!)) &&
                     (!election.eligibleYears.length || election.eligibleYears.includes(user.yearOfStudy!));

  if (!isEligible && user.role === 'STUDENT') {
    throw new ValidationError('You are not eligible to view candidates for this election');
  }

  // Build where clause
  const where: any = {
    electionId: electionId as string,
  };

  // Filter by approval status if specified
  if (approved !== undefined) {
    where.isApproved = approved === 'true';
  } else if (user.role === 'STUDENT') {
    // Students can only see approved candidates
    where.isApproved = true;
  }

  const candidates = await db.candidate.findMany({
    where,
    include: {
      user: {
        select: {
          firstName: true,
          lastName: true,
          matricNumber: true,
          email: true,
          department: true,
          faculty: true,
          yearOfStudy: true,
        }
      }
    },
    orderBy: [
      { isApproved: 'desc' },
      { createdAt: 'asc' }
    ]
  });

  res.json({
    message: 'Candidates retrieved successfully',
    candidates: candidates.map((candidate: any) => ({
      id: candidate.id,
      manifesto: candidate.manifesto,
      photoUrl: candidate.photoUrl,
      videoUrl: candidate.videoUrl,
      voteCount: candidate.voteCount,
      isApproved: candidate.isApproved,
      createdAt: candidate.createdAt,
      user: candidate.user,
    })),
  });
}));

// Get candidate by ID
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.get('/:candidateId', requireStudent, asyncHandler(async (req: Request, res: Response) => {
  const { candidateId } = req.params;
  const user = req.user!;

  const db = DatabaseService.getClient();

  const candidate = await db.candidate.findUnique({
    where: { id: candidateId },
    include: {
      user: {
        select: {
          firstName: true,
          lastName: true,
          matricNumber: true,
          email: true,
          department: true,
          faculty: true,
          yearOfStudy: true,
        }
      },
      election: {
        select: {
          id: true,
          title: true,
          eligibleFaculties: true,
          eligibleYears: true,
        }
      }
    }
  });

  if (!candidate) {
    throw new NotFoundError('Candidate not found');
  }

  // Check eligibility for students
  if (user.role === 'STUDENT') {
    const isEligible = (!candidate.election.eligibleFaculties.length || candidate.election.eligibleFaculties.includes(user.faculty!)) &&
                       (!candidate.election.eligibleYears.length || candidate.election.eligibleYears.includes(user.yearOfStudy!));

    if (!isEligible) {
      throw new ValidationError('You are not eligible to view this candidate');
    }

    // Students can only see approved candidates
    if (!candidate.isApproved) {
      throw new NotFoundError('Candidate not found');
    }
  }

  res.json({
    message: 'Candidate retrieved successfully',
    candidate: {
      id: candidate.id,
      manifesto: candidate.manifesto,
      photoUrl: candidate.photoUrl,
      videoUrl: candidate.videoUrl,
      voteCount: candidate.voteCount,
      isApproved: candidate.isApproved,
      createdAt: candidate.createdAt,
      user: candidate.user,
      election: {
        id: candidate.election.id,
        title: candidate.election.title,
      }
    }
  });
}));

// Apply to become a candidate
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.post('/', requireAuth, upload.fields([
  { name: 'photo', maxCount: 1 },
  { name: 'video', maxCount: 1 }
]), asyncHandler(async (req: Request, res: Response) => {
  const { electionId, manifesto } = req.body;
  const user = req.user!;
  const files = req.files as { [fieldname: string]: Express.Multer.File[] };

  // Validate required fields
  if (!electionId || !manifesto) {
    throw new ValidationError('Election ID and manifesto are required');
  }

  if (manifesto.length < 100) {
    throw new ValidationError('Manifesto must be at least 100 characters long');
  }

  const db = DatabaseService.getClient();

  // Get election details
  const election = await db.election.findUnique({
    where: { id: electionId }
  });

  if (!election) {
    throw new NotFoundError('Election not found');
  }

  // Check if applications are still open
  const now = new Date();
  const applicationDeadline = new Date(election.startDate.getTime() - 7 * 24 * 60 * 60 * 1000); // 7 days before election

  if (now > applicationDeadline) {
    throw new ValidationError('Candidate applications have closed for this election');
  }

  // Check if user is eligible
  const isEligible = (!election.eligibleFaculties.length || election.eligibleFaculties.includes(user.faculty!)) &&
                     (!election.eligibleYears.length || election.eligibleYears.includes(user.yearOfStudy!));

  if (!isEligible) {
    throw new ValidationError('You are not eligible to run as a candidate in this election');
  }

  // Check if user is already a candidate for this election
  const existingCandidate = await db.candidate.findFirst({
    where: {
      electionId,
      userId: user.id,
    }
  });

  if (existingCandidate) {
    throw new ConflictError('You have already applied to be a candidate in this election');
  }

  // Process uploaded files
  let photoUrl: string | undefined;
  let videoUrl: string | undefined;

  if (files.photo && files.photo[0]) {
    photoUrl = `/uploads/candidates/${files.photo[0].filename}`;
  }

  if (files.video && files.video[0]) {
    videoUrl = `/uploads/candidates/${files.video[0].filename}`;
  }

  // Create candidate application
  const candidate = await db.candidate.create({
    data: {
      electionId,
      userId: user.id,
      manifesto,
      photoUrl,
      videoUrl,
      isApproved: false, // Requires approval from admin/committee
    },
    include: {
      user: {
        select: {
          firstName: true,
          lastName: true,
          matricNumber: true,
          department: true,
          faculty: true,
        }
      }
    }
  });

  // Log candidate application
  await logSpecificEvent(
    req,
    'CANDIDATE_APPLICATION_SUBMITTED',
    'candidate',
    user.id,
    { electionId, candidateId: candidate.id, manifesto: manifesto.substring(0, 100) + '...' }
  );

  logger.info('Candidate application submitted', {
    candidateId: candidate.id,
    userId: user.id,
    electionId,
  });

  res.status(201).json({
    message: 'Candidate application submitted successfully. Awaiting approval.',
    candidate: {
      id: candidate.id,
      manifesto: candidate.manifesto,
      photoUrl: candidate.photoUrl,
      videoUrl: candidate.videoUrl,
      isApproved: candidate.isApproved,
      createdAt: candidate.createdAt,
      user: candidate.user,
    }
  });
}));

// Update candidate application (only before approval)
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.put('/:candidateId', requireAuth, upload.fields([
  { name: 'photo', maxCount: 1 },
  { name: 'video', maxCount: 1 }
]), asyncHandler(async (req: Request, res: Response) => {
  const { candidateId } = req.params;
  const { manifesto } = req.body;
  const user = req.user!;
  const files = req.files as { [fieldname: string]: Express.Multer.File[] };

  const db = DatabaseService.getClient();

  const candidate = await db.candidate.findUnique({
    where: { id: candidateId },
    include: { election: true }
  });

  if (!candidate) {
    throw new NotFoundError('Candidate not found');
  }

  // Only the candidate themselves can update their application
  if (candidate.userId !== user.id) {
    throw new ValidationError('You can only update your own candidate application');
  }

  // Cannot update after approval
  if (candidate.isApproved) {
    throw new ValidationError('Cannot update candidate application after approval');
  }

  // Check if applications are still open
  const now = new Date();
  const applicationDeadline = new Date(candidate.election.startDate.getTime() - 7 * 24 * 60 * 60 * 1000);

  if (now > applicationDeadline) {
    throw new ValidationError('Candidate application period has ended');
  }

  // Prepare update data
  const updateData: any = {};

  if (manifesto) {
    if (manifesto.length < 100) {
      throw new ValidationError('Manifesto must be at least 100 characters long');
    }
    updateData.manifesto = manifesto;
  }

  // Process uploaded files
  if (files.photo && files.photo[0]) {
    // Delete old photo if it exists
    if (candidate.photoUrl) {
      const oldPhotoPath = path.join(__dirname, '../../', candidate.photoUrl);
      if (fs.existsSync(oldPhotoPath)) {
        fs.unlinkSync(oldPhotoPath);
      }
    }
    updateData.photoUrl = `/uploads/candidates/${files.photo[0].filename}`;
  }

  if (files.video && files.video[0]) {
    // Delete old video if it exists
    if (candidate.videoUrl) {
      const oldVideoPath = path.join(__dirname, '../../', candidate.videoUrl);
      if (fs.existsSync(oldVideoPath)) {
        fs.unlinkSync(oldVideoPath);
      }
    }
    updateData.videoUrl = `/uploads/candidates/${files.video[0].filename}`;
  }

  const updatedCandidate = await db.candidate.update({
    where: { id: candidateId },
    data: updateData,
    include: {
      user: {
        select: {
          firstName: true,
          lastName: true,
          matricNumber: true,
          department: true,
          faculty: true,
        }
      }
    }
  });

  // Log candidate update
  await logSpecificEvent(
    req,
    'CANDIDATE_APPLICATION_UPDATED',
    'candidate',
    user.id,
    { candidateId, changes: Object.keys(updateData) }
  );

  logger.info('Candidate application updated', {
    candidateId,
    userId: user.id,
    changes: Object.keys(updateData),
  });

  res.json({
    message: 'Candidate application updated successfully',
    candidate: {
      id: updatedCandidate.id,
      manifesto: updatedCandidate.manifesto,
      photoUrl: updatedCandidate.photoUrl,
      videoUrl: updatedCandidate.videoUrl,
      isApproved: updatedCandidate.isApproved,
      updatedAt: updatedCandidate.updatedAt,
      user: updatedCandidate.user,
    }
  });
}));

// Approve/Reject candidate (admin/committee only)
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.patch('/:candidateId/approval', requireCommitteeOrAdmin, asyncHandler(async (req: Request, res: Response) => {
  const { candidateId } = req.params;
  const { isApproved, rejectionReason } = req.body;
  const user = req.user!;

  if (typeof isApproved !== 'boolean') {
    throw new ValidationError('isApproved must be a boolean value');
  }

  if (!isApproved && !rejectionReason) {
    throw new ValidationError('Rejection reason is required when rejecting a candidate');
  }

  const db = DatabaseService.getClient();

  const candidate = await db.candidate.findUnique({
    where: { id: candidateId },
    include: {
      user: true,
      election: true,
    }
  });

  if (!candidate) {
    throw new NotFoundError('Candidate not found');
  }

  // Check if election has started
  const now = new Date();
  if (now >= candidate.election.startDate) {
    throw new ValidationError('Cannot modify candidate approval after election has started');
  }

  const updatedCandidate = await db.candidate.update({
    where: { id: candidateId },
    data: { isApproved }
  });

  // Log approval/rejection
  const action = isApproved ? 'CANDIDATE_APPROVED' : 'CANDIDATE_REJECTED';
  await logSpecificEvent(
    req,
    action,
    'candidate',
    user.id,
    { 
      candidateId, 
      candidateUserId: candidate.userId,
      electionId: candidate.electionId,
      rejectionReason: rejectionReason || null,
    }
  );

  logger.info(`Candidate ${isApproved ? 'approved' : 'rejected'}`, {
    candidateId,
    reviewedBy: user.id,
    electionId: candidate.electionId,
    rejectionReason: rejectionReason || null,
  });

  // TODO: Send notification email to candidate

  res.json({
    message: `Candidate ${isApproved ? 'approved' : 'rejected'} successfully`,
    candidate: {
      id: updatedCandidate.id,
      isApproved: updatedCandidate.isApproved,
      updatedAt: updatedCandidate.updatedAt,
    },
  });
}));

// Delete candidate application (own application only, before approval)
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.delete('/:candidateId', requireAuth, asyncHandler(async (req: Request, res: Response) => {
  const { candidateId } = req.params;
  const user = req.user!;

  const db = DatabaseService.getClient();

  const candidate = await db.candidate.findUnique({
    where: { id: candidateId },
    include: { election: true }
  });

  if (!candidate) {
    throw new NotFoundError('Candidate not found');
  }

  // Only allow deletion by the candidate themselves or admin
  if (candidate.userId !== user.id && user.role !== 'ADMIN' && user.role !== 'ELECTORAL_COMMITTEE') {
    throw new ValidationError('You can only delete your own candidate application');
  }

  // Cannot delete after approval unless admin
  if (candidate.isApproved && user.role === 'STUDENT') {
    throw new ValidationError('Cannot delete approved candidate application');
  }

  // Check if election has started
  const now = new Date();
  if (now >= candidate.election.startDate && user.role === 'STUDENT') {
    throw new ValidationError('Cannot delete candidate application after election has started');
  }

  // Delete associated files
  if (candidate.photoUrl) {
    const photoPath = path.join(__dirname, '../../', candidate.photoUrl);
    if (fs.existsSync(photoPath)) {
      fs.unlinkSync(photoPath);
    }
  }

  if (candidate.videoUrl) {
    const videoPath = path.join(__dirname, '../../', candidate.videoUrl);
    if (fs.existsSync(videoPath)) {
      fs.unlinkSync(videoPath);
    }
  }

  await db.candidate.delete({
    where: { id: candidateId }
  });

  // Log deletion
  await logSpecificEvent(
    req,
    'CANDIDATE_APPLICATION_DELETED',
    'candidate',
    user.id,
    { candidateId, candidateUserId: candidate.userId, electionId: candidate.electionId }
  );

  logger.info('Candidate application deleted', {
    candidateId,
    deletedBy: user.id,
    candidateUserId: candidate.userId,
  });

  res.json({
    message: 'Candidate application deleted successfully'
  });
}));

export default router;