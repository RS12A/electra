import { Router, Request, Response } from 'express';
import { asyncHandler, ValidationError, NotFoundError } from '../middleware/errorHandler';
import { requireStudent, requireDeviceAttestation } from '../middleware/auth';
import { DatabaseService } from '../services/DatabaseService';
import { SecurityService } from '../services/SecurityService';
import { LoggerService } from '../services/LoggerService';
import { logSpecificEvent } from '../middleware/auditLogger';

const router = Router();
const logger = new LoggerService();

// Cast a vote
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.post('/', requireStudent, requireDeviceAttestation, asyncHandler(async (req: Request, res: Response) => {
  const { electionId, candidateId, ballotToken } = req.body;
  const user = req.user!;

  // Validate required fields
  if (!electionId || !candidateId || !ballotToken) {
    throw new ValidationError('Election ID, candidate ID, and ballot token are required');
  }

  const db = DatabaseService.getClient();

  // Verify ballot token
  const ballotTokenRecord = await db.ballotToken.findUnique({
    where: { token: ballotToken },
    include: { election: true },
  });

  if (!ballotTokenRecord) {
    await logSpecificEvent(
      req,
      'VOTE_ATTEMPT_INVALID_TOKEN',
      'voting',
      user.id,
      { electionId, candidateId, ballotToken: ballotToken.substring(0, 8) + '***' }
    );
    throw new ValidationError('Invalid ballot token');
  }

  if (ballotTokenRecord.isUsed) {
    await logSpecificEvent(
      req,
      'VOTE_ATTEMPT_TOKEN_REUSE',
      'voting',
      user.id,
      { electionId, candidateId, tokenId: ballotTokenRecord.id }
    );
    throw new ValidationError('Ballot token has already been used');
  }

  if (ballotTokenRecord.userId !== user.id) {
    await logSpecificEvent(
      req,
      'VOTE_ATTEMPT_TOKEN_MISMATCH',
      'voting',
      user.id,
      { electionId, candidateId, tokenUserId: ballotTokenRecord.userId }
    );
    throw new ValidationError('Ballot token does not belong to this user');
  }

  if (new Date() > ballotTokenRecord.expiresAt) {
    await logSpecificEvent(
      req,
      'VOTE_ATTEMPT_TOKEN_EXPIRED',
      'voting',
      user.id,
      { electionId, candidateId, tokenId: ballotTokenRecord.id }
    );
    throw new ValidationError('Ballot token has expired');
  }

  if (ballotTokenRecord.electionId !== electionId) {
    await logSpecificEvent(
      req,
      'VOTE_ATTEMPT_WRONG_ELECTION',
      'voting',
      user.id,
      { electionId, candidateId, tokenElectionId: ballotTokenRecord.electionId }
    );
    throw new ValidationError('Ballot token is not for this election');
  }

  // Get election details
  const election = await db.election.findUnique({
    where: { id: electionId },
    include: {
      candidates: {
        where: { isApproved: true },
        select: { id: true },
      },
    },
  });

  if (!election) {
    throw new NotFoundError('Election not found');
  }

  // Check if election is active and ongoing
  const now = new Date();
  if (!election.isActive) {
    await logSpecificEvent(
      req,
      'VOTE_ATTEMPT_ELECTION_INACTIVE',
      'voting',
      user.id,
      { electionId, candidateId }
    );
    throw new ValidationError('Election is not active');
  }

  if (now < election.startDate) {
    await logSpecificEvent(
      req,
      'VOTE_ATTEMPT_ELECTION_NOT_STARTED',
      'voting',
      user.id,
      { electionId, candidateId, startDate: election.startDate }
    );
    throw new ValidationError('Election has not started yet');
  }

  if (now > election.endDate) {
    await logSpecificEvent(
      req,
      'VOTE_ATTEMPT_ELECTION_ENDED',
      'voting',
      user.id,
      { electionId, candidateId, endDate: election.endDate }
    );
    throw new ValidationError('Election has ended');
  }

  // Verify candidate exists and is approved
  const candidate = await db.candidate.findUnique({
    where: { id: candidateId },
  });

  if (!candidate) {
    throw new NotFoundError('Candidate not found');
  }

  if (candidate.electionId !== electionId) {
    await logSpecificEvent(
      req,
      'VOTE_ATTEMPT_CANDIDATE_WRONG_ELECTION',
      'voting',
      user.id,
      { electionId, candidateId, candidateElectionId: candidate.electionId }
    );
    throw new ValidationError('Candidate is not part of this election');
  }

  if (!candidate.isApproved) {
    await logSpecificEvent(
      req,
      'VOTE_ATTEMPT_CANDIDATE_NOT_APPROVED',
      'voting',
      user.id,
      { electionId, candidateId }
    );
    throw new ValidationError('Candidate is not approved to receive votes');
  }

  // Check if user is eligible for this election
  const isEligible = (!election.eligibleFaculties.length || election.eligibleFaculties.includes(user.faculty!)) &&
                     (!election.eligibleYears.length || election.eligibleYears.includes(user.yearOfStudy!));

  if (!isEligible) {
    await logSpecificEvent(
      req,
      'VOTE_ATTEMPT_USER_INELIGIBLE',
      'voting',
      user.id,
      { 
        electionId, 
        candidateId,
        userFaculty: user.faculty,
        userYear: user.yearOfStudy,
        requiredFaculties: election.eligibleFaculties,
        requiredYears: election.eligibleYears,
      }
    );
    throw new ValidationError('You are not eligible to vote in this election');
  }

  // Check for double voting
  const existingVote = await db.vote.findFirst({
    where: {
      electionId: electionId,
      voterId: user.id,
    },
  });

  if (existingVote) {
    await logSpecificEvent(
      req,
      'VOTE_ATTEMPT_DOUBLE_VOTING',
      'voting',
      user.id,
      { electionId, candidateId, existingVoteId: existingVote.id }
    );
    throw new ValidationError('You have already voted in this election');
  }

  // Prepare vote data for encryption
  const voteData = {
    electionId,
    candidateId,
    voterId: user.id,
    timestamp: now.toISOString(),
    userAgent: req.headers['user-agent'],
    ipAddress: req.ip,
  };

  // Encrypt and sign the vote
  const encryptionEnabled = await DatabaseService.getSystemConfig('VOTE_ENCRYPTION_ENABLED') === 'true';
  let encryptedVote: string;
  let voteSignature: string;

  if (encryptionEnabled) {
    try {
      const encrypted = SecurityService.encryptVote(voteData);
      encryptedVote = encrypted.encryptedData;
      voteSignature = encrypted.signature;
    } catch (error) {
      logger.error('Vote encryption failed', error);
      throw new Error('Failed to encrypt vote. Please try again.');
    }
  } else {
    // For development/testing, store vote data as JSON
    encryptedVote = JSON.stringify(voteData);
    voteSignature = SecurityService.hashData(encryptedVote);
  }

  // Begin database transaction
  try {
    // Create the vote record
    const vote = await db.vote.create({
      data: {
        electionId,
        candidateId,
        voterId: user.id,
        encryptedVote,
        voteSignature,
        ballotTokenId: ballotTokenRecord.id,
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'],
      },
    });

    // Mark ballot token as used
    await db.ballotToken.update({
      where: { id: ballotTokenRecord.id },
      data: {
        isUsed: true,
        usedAt: now,
      },
    });

    // Update candidate vote count
    await db.candidate.update({
      where: { id: candidateId },
      data: {
        voteCount: { increment: 1 },
      },
    });

    // Log successful vote
    logger.logVoteCast(electionId, user.id, candidateId, req.ip);
    
    await logSpecificEvent(
      req,
      'VOTE_CAST_SUCCESS',
      'voting',
      user.id,
      { 
        electionId, 
        candidateId,
        voteId: vote.id,
        ballotTokenId: ballotTokenRecord.id,
      }
    );

    res.status(201).json({
      message: 'Vote cast successfully',
      vote: {
        id: vote.id,
        electionId: vote.electionId,
        timestamp: vote.createdAt,
        encrypted: encryptionEnabled,
      },
    });

  } catch (error) {
    logger.error('Vote casting failed', error);
    
    await logSpecificEvent(
      req,
      'VOTE_CAST_FAILED',
      'voting',
      user.id,
      { electionId, candidateId, error: error instanceof Error ? error.message : 'Unknown error' }
    );
    
    throw new Error('Failed to cast vote. Please try again.');
  }
}));

// Get voting status for user
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.get('/status', requireStudent, asyncHandler(async (req: Request, res: Response) => {
  const { electionId } = req.query;
  const user = req.user!;

  if (!electionId) {
    throw new ValidationError('Election ID is required');
  }

  const db = DatabaseService.getClient();

  // Get election details
  const election = await db.election.findUnique({
    where: { id: electionId as string },
  });

  if (!election) {
    throw new NotFoundError('Election not found');
  }

  // Check if user has voted
  const existingVote = await db.vote.findFirst({
    where: {
      electionId: electionId as string,
      voterId: user.id,
    },
    select: {
      id: true,
      createdAt: true,
    },
  });

  // Check if user has a valid ballot token
  const ballotToken = await db.ballotToken.findFirst({
    where: {
      electionId: electionId as string,
      userId: user.id,
      isUsed: false,
      expiresAt: { gte: new Date() },
    },
  });

  // Check eligibility
  const isEligible = (!election.eligibleFaculties.length || election.eligibleFaculties.includes(user.faculty!)) &&
                     (!election.eligibleYears.length || election.eligibleYears.includes(user.yearOfStudy!));

  const now = new Date();
  const electionStatus = election.isActive 
    ? (now < election.startDate ? 'upcoming' : now > election.endDate ? 'completed' : 'ongoing')
    : 'inactive';

  res.json({
    message: 'Voting status retrieved successfully',
    status: {
      hasVoted: !!existingVote,
      voteTimestamp: existingVote?.createdAt,
      isEligible,
      canVote: isEligible && !existingVote && electionStatus === 'ongoing' && !!ballotToken,
      electionStatus,
      hasBallotToken: !!ballotToken,
      ballotTokenExpiry: ballotToken?.expiresAt,
    },
  });
}));

// Generate ballot token for eligible user (called when user accesses voting page)
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.post('/ballot-token', requireStudent, asyncHandler(async (req: Request, res: Response) => {
  const { electionId } = req.body;
  const user = req.user!;

  if (!electionId) {
    throw new ValidationError('Election ID is required');
  }

  const db = DatabaseService.getClient();

  // Get election details
  const election = await db.election.findUnique({
    where: { id: electionId },
  });

  if (!election) {
    throw new NotFoundError('Election not found');
  }

  // Check if election is ongoing
  const now = new Date();
  if (!election.isActive || now < election.startDate || now > election.endDate) {
    throw new ValidationError('Election is not currently accepting votes');
  }

  // Check eligibility
  const isEligible = (!election.eligibleFaculties.length || election.eligibleFaculties.includes(user.faculty!)) &&
                     (!election.eligibleYears.length || election.eligibleYears.includes(user.yearOfStudy!));

  if (!isEligible) {
    throw new ValidationError('You are not eligible to vote in this election');
  }

  // Check if user has already voted
  const existingVote = await db.vote.findFirst({
    where: {
      electionId,
      voterId: user.id,
    },
  });

  if (existingVote) {
    throw new ValidationError('You have already voted in this election');
  }

  // Check if user already has a valid ballot token
  const existingToken = await db.ballotToken.findFirst({
    where: {
      electionId,
      userId: user.id,
      isUsed: false,
      expiresAt: { gte: now },
    },
  });

  if (existingToken) {
    return res.json({
      message: 'Ballot token already exists',
      ballotToken: {
        token: existingToken.token,
        expiresAt: existingToken.expiresAt,
        timeRemaining: Math.max(0, existingToken.expiresAt.getTime() - now.getTime()),
      },
    });
  }

  // Generate new ballot token (expires in 30 minutes)
  const token = SecurityService.generateSecureToken(64);
  const expiresAt = new Date(now.getTime() + 30 * 60 * 1000); // 30 minutes

  const ballotToken = await db.ballotToken.create({
    data: {
      token,
      electionId,
      userId: user.id,
      expiresAt,
    },
  });

  logger.info('Ballot token generated', {
    tokenId: ballotToken.id,
    userId: user.id,
    electionId,
    expiresAt,
  });

  res.json({
    message: 'Ballot token generated successfully',
    ballotToken: {
      token: ballotToken.token,
      expiresAt: ballotToken.expiresAt,
      timeRemaining: expiresAt.getTime() - now.getTime(),
    },
  });
}));

export default router;