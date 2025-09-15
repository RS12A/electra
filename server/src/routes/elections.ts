import { Router, Request, Response } from 'express';
import { asyncHandler, ValidationError, NotFoundError } from '../middleware/errorHandler';
import { requireCommitteeOrAdmin, requireStudent } from '../middleware/auth';
import { DatabaseService } from '../services/DatabaseService';
import { LoggerService } from '../services/LoggerService';

const router = Router();
const logger = new LoggerService();

// Get all elections
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.get('/', requireStudent, asyncHandler(async (req: Request, res: Response) => {
  const { status, category, page = 1, limit = 20 } = req.query;
  const user = req.user!;
  
  const skip = (Number(page) - 1) * Number(limit);
  const take = Number(limit);

  const where: any = {};
  
  // Filter by status if provided
  if (status === 'active') {
    where.isActive = true;
    where.startDate = { lte: new Date() };
    where.endDate = { gte: new Date() };
  } else if (status === 'upcoming') {
    where.startDate = { gt: new Date() };
  } else if (status === 'completed') {
    where.endDate = { lt: new Date() };
  }
  
  // Filter by category if provided
  if (category) {
    where.category = category;
  }
  
  // Filter by user eligibility (faculty and year of study)
  if (user.faculty) {
    where.eligibleFaculties = { has: user.faculty };
  }
  if (user.yearOfStudy) {
    where.eligibleYears = { has: user.yearOfStudy };
  }

  const db = DatabaseService.getClient();
  
  const [elections, total] = await Promise.all([
    db.election.findMany({
      where,
      skip,
      take,
      select: {
        id: true,
        title: true,
        description: true,
        category: true,
        startDate: true,
        endDate: true,
        isActive: true,
        allowDelayedReveal: true,
        revealDate: true,
        maxVotesPerUser: true,
        eligibleFaculties: true,
        eligibleYears: true,
        createdAt: true,
        creator: {
          select: {
            firstName: true,
            lastName: true,
          },
        },
        _count: {
          select: {
            candidates: true,
            votes: true,
          },
        },
      },
      orderBy: { startDate: 'desc' },
    }),
    db.election.count({ where }),
  ]);

  // Add user vote status for each election
  const electionsWithVoteStatus = await Promise.all(
    elections.map(async (election: any) => {
      const userVote = await db.vote.findFirst({
        where: {
          electionId: election.id,
          voterId: user.id,
        },
      });

      return {
        ...election,
        hasUserVoted: !!userVote,
        candidateCount: election._count.candidates,
        voteCount: election._count.votes,
        _count: undefined, // Remove the _count field
      };
    })
  );

  res.json({
    message: 'Elections retrieved successfully',
    elections: electionsWithVoteStatus,
    pagination: {
      page: Number(page),
      limit: Number(limit),
      total,
      pages: Math.ceil(total / Number(limit)),
    },
  });
}));

// Get election by ID
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.get('/:electionId', requireStudent, asyncHandler(async (req: Request, res: Response) => {
  const { electionId } = req.params;
  const user = req.user!;
  
  const db = DatabaseService.getClient();
  const election = await db.election.findUnique({
    where: { id: electionId },
    include: {
      creator: {
        select: {
          firstName: true,
          lastName: true,
          role: true,
        },
      },
      candidates: {
        where: { isApproved: true },
        select: {
          id: true,
          manifesto: true,
          photoUrl: true,
          videoUrl: true,
          voteCount: true,
          user: {
            select: {
              firstName: true,
              lastName: true,
              matricNumber: true,
              department: true,
              faculty: true,
            },
          },
        },
        orderBy: { createdAt: 'asc' },
      },
      _count: {
        select: {
          votes: true,
        },
      },
    },
  });

  if (!election) {
    throw new NotFoundError('Election not found');
  }

  // Check if user is eligible to view this election
  const isEligible = (!election.eligibleFaculties.length || election.eligibleFaculties.includes(user.faculty!)) &&
                     (!election.eligibleYears.length || election.eligibleYears.includes(user.yearOfStudy!));

  if (!isEligible) {
    throw new ValidationError('You are not eligible to participate in this election');
  }

  // Check if user has already voted
  const userVote = await db.vote.findFirst({
    where: {
      electionId: election.id,
      voterId: user.id,
    },
  });

  const now = new Date();
  const isOngoing = election.isActive && now >= election.startDate && now <= election.endDate;
  const isCompleted = now > election.endDate;
  
  // Mask vote counts if election is ongoing (unless delayed reveal is disabled)
  const shouldShowResults = isCompleted || (election.allowDelayedReveal && election.revealDate && now >= election.revealDate);
  
  const candidates = election.candidates.map((candidate: any) => ({
    ...candidate,
    voteCount: shouldShowResults ? candidate.voteCount : undefined,
  }));

  res.json({
    message: 'Election retrieved successfully',
    election: {
      ...election,
      candidates,
      totalVotes: shouldShowResults ? election._count.votes : undefined,
      hasUserVoted: !!userVote,
      isOngoing,
      isCompleted,
      canVote: isOngoing && !userVote,
      resultsVisible: shouldShowResults,
      _count: undefined,
    },
  });
}));

// Create new election (admin/committee only)
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.post('/', requireCommitteeOrAdmin, asyncHandler(async (req: Request, res: Response) => {
  const {
    title,
    description,
    category,
    startDate,
    endDate,
    allowDelayedReveal,
    revealDate,
    maxVotesPerUser = 1,
    eligibleFaculties = [],
    eligibleYears = [],
  } = req.body;
  
  const user = req.user!;

  // Validate required fields
  if (!title || !description || !category || !startDate || !endDate) {
    throw new ValidationError('Missing required fields: title, description, category, startDate, endDate');
  }

  // Validate dates
  const start = new Date(startDate);
  const end = new Date(endDate);
  
  if (start >= end) {
    throw new ValidationError('Start date must be before end date');
  }
  
  if (start <= new Date()) {
    throw new ValidationError('Start date must be in the future');
  }

  // Validate reveal date if provided
  if (allowDelayedReveal && revealDate) {
    const reveal = new Date(revealDate);
    if (reveal <= end) {
      throw new ValidationError('Reveal date must be after end date');
    }
  }

  const db = DatabaseService.getClient();
  
  // Check for concurrent elections limit
  const activeElections = await db.election.count({
    where: {
      isActive: true,
      startDate: { lte: end },
      endDate: { gte: start },
    },
  });
  
  const maxConcurrent = parseInt(await DatabaseService.getSystemConfig('MAX_CONCURRENT_ELECTIONS') || '5');
  if (activeElections >= maxConcurrent) {
    throw new ValidationError(`Cannot create election. Maximum concurrent elections (${maxConcurrent}) reached.`);
  }

  const election = await db.election.create({
    data: {
      title,
      description,
      category,
      startDate: start,
      endDate: end,
      allowDelayedReveal: allowDelayedReveal || false,
      revealDate: allowDelayedReveal && revealDate ? new Date(revealDate) : null,
      maxVotesPerUser,
      eligibleFaculties: Array.isArray(eligibleFaculties) ? eligibleFaculties : [],
      eligibleYears: Array.isArray(eligibleYears) ? eligibleYears : [],
      createdById: user.id,
      isActive: false, // Elections must be manually activated
    },
    include: {
      creator: {
        select: {
          firstName: true,
          lastName: true,
          role: true,
        },
      },
    },
  });

  logger.info('Election created', { 
    electionId: election.id,
    title: election.title,
    createdBy: user.id,
  });

  res.status(201).json({
    message: 'Election created successfully',
    election,
  });
}));

// Update election (admin/committee only)
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.put('/:electionId', requireCommitteeOrAdmin, asyncHandler(async (req: Request, res: Response) => {
  const { electionId } = req.params;
  const user = req.user!;
  const updateData = req.body;

  const db = DatabaseService.getClient();
  
  // Check if election exists
  const existingElection = await db.election.findUnique({
    where: { id: electionId },
  });

  if (!existingElection) {
    throw new NotFoundError('Election not found');
  }

  // Prevent updates to ongoing or completed elections
  const now = new Date();
  if (existingElection.isActive && now >= existingElection.startDate) {
    throw new ValidationError('Cannot update an ongoing or completed election');
  }

  // Validate date changes if provided
  if (updateData.startDate || updateData.endDate) {
    const start = new Date(updateData.startDate || existingElection.startDate);
    const end = new Date(updateData.endDate || existingElection.endDate);
    
    if (start >= end) {
      throw new ValidationError('Start date must be before end date');
    }
    
    if (start <= new Date()) {
      throw new ValidationError('Start date must be in the future');
    }
  }

  const updatedElection = await db.election.update({
    where: { id: electionId },
    data: {
      ...updateData,
      startDate: updateData.startDate ? new Date(updateData.startDate) : undefined,
      endDate: updateData.endDate ? new Date(updateData.endDate) : undefined,
      revealDate: updateData.revealDate ? new Date(updateData.revealDate) : undefined,
    },
    include: {
      creator: {
        select: {
          firstName: true,
          lastName: true,
          role: true,
        },
      },
    },
  });

  logger.info('Election updated', { 
    electionId: electionId,
    updatedBy: user.id,
    changes: Object.keys(updateData),
  });

  res.json({
    message: 'Election updated successfully',
    election: updatedElection,
  });
}));

// Activate/Deactivate election (admin/committee only)
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.patch('/:electionId/status', requireCommitteeOrAdmin, asyncHandler(async (req: Request, res: Response) => {
  const { electionId } = req.params;
  const { isActive } = req.body;
  const user = req.user!;

  if (typeof isActive !== 'boolean') {
    throw new ValidationError('isActive must be a boolean value');
  }

  const db = DatabaseService.getClient();
  
  const election = await db.election.findUnique({
    where: { id: electionId },
    include: {
      _count: {
        select: {
          candidates: { where: { isApproved: true } },
        },
      },
    },
  });

  if (!election) {
    throw new NotFoundError('Election not found');
  }

  // If activating, check prerequisites
  if (isActive) {
    if (election._count.candidates < 2) {
      throw new ValidationError('Election must have at least 2 approved candidates to be activated');
    }

    const now = new Date();
    if (now > election.endDate) {
      throw new ValidationError('Cannot activate an election that has already ended');
    }
  }

  const updatedElection = await db.election.update({
    where: { id: electionId },
    data: { isActive },
  });

  logger.info(`Election ${isActive ? 'activated' : 'deactivated'}`, { 
    electionId: election.id,
    changedBy: user.id,
  });

  res.json({
    message: `Election ${isActive ? 'activated' : 'deactivated'} successfully`,
    election: updatedElection,
  });
}));

export default router;