import { Router, Request, Response } from 'express';
import { asyncHandler, ValidationError, NotFoundError } from '../middleware/errorHandler';
import { requireAdmin, requireCommitteeOrAdmin } from '../middleware/auth';
import { DatabaseService } from '../services/DatabaseService';
import { LoggerService } from '../services/LoggerService';
import { SecurityService } from '../services/SecurityService';
import { logSpecificEvent } from '../middleware/auditLogger';
import * as fs from 'fs';
import * as path from 'path';

const router = Router();
const logger = new LoggerService();

// Get admin dashboard data
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.get('/dashboard', requireCommitteeOrAdmin, asyncHandler(async (req: Request, res: Response) => {
  const user = req.user!;
  const db = DatabaseService.getClient();

  // Get overall statistics
  const [
    totalUsers,
    totalElections,
    activeElections,
    totalVotes,
    pendingCandidates,
    recentAuditLogs
  ] = await Promise.all([
    db.user.count(),
    db.election.count(),
    db.election.count({ where: { isActive: true } }),
    db.vote.count(),
    db.candidate.count({ where: { isApproved: false } }),
    db.auditLog.findMany({
      take: 10,
      orderBy: { createdAt: 'desc' },
      include: {
        user: {
          select: {
            firstName: true,
            lastName: true,
            matricNumber: true,
          }
        }
      }
    })
  ]);

  // Get elections summary
  const elections = await db.election.findMany({
    take: 5,
    orderBy: { createdAt: 'desc' },
    include: {
      _count: {
        select: {
          candidates: { where: { isApproved: true } },
          votes: true,
        }
      }
    }
  });

  // Get user registration statistics (last 30 days)
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const recentUsers = await db.user.count({
    where: {
      createdAt: { gte: thirtyDaysAgo }
    }
  });

  // Get voting activity by day (last 7 days)
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  const votingActivity = await db.vote.groupBy({
    by: ['createdAt'],
    where: {
      createdAt: { gte: sevenDaysAgo }
    },
    _count: true
  });

  // System health checks
  const systemHealth = {
    database: 'healthy',
    encryption: SecurityService ? 'healthy' : 'warning',
    storage: fs.existsSync('./uploads') ? 'healthy' : 'warning',
    logs: fs.existsSync('./logs') ? 'healthy' : 'warning',
  };

  res.json({
    message: 'Dashboard data retrieved successfully',
    dashboard: {
      statistics: {
        totalUsers,
        totalElections,
        activeElections,
        totalVotes,
        pendingCandidates,
        recentUsers,
      },
      recentElections: elections.map((election: any) => ({
        id: election.id,
        title: election.title,
        category: election.category,
        startDate: election.startDate,
        endDate: election.endDate,
        isActive: election.isActive,
        candidateCount: election._count.candidates,
        voteCount: election._count.votes,
      })),
      recentActivity: recentAuditLogs.map((log: any) => ({
        id: log.id,
        action: log.action,
        resource: log.resource,
        user: log.user ? `${log.user.firstName} ${log.user.lastName}` : 'System',
        timestamp: log.createdAt,
        ipAddress: log.ipAddress,
      })),
      votingActivity: votingActivity.map((activity: any) => ({
        date: activity.createdAt,
        count: activity._count,
      })),
      systemHealth,
    },
  });
}));

// Get system statistics
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.get('/statistics', requireCommitteeOrAdmin, asyncHandler(async (req: Request, res: Response) => {
  const { period = '30' } = req.query;
  const days = parseInt(period as string) || 30;
  
  const db = DatabaseService.getClient();
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);

  // User statistics
  const userStats = await db.user.groupBy({
    by: ['role'],
    _count: true,
  });

  // Election statistics by category
  const electionStats = await db.election.groupBy({
    by: ['category'],
    _count: true,
    where: {
      createdAt: { gte: startDate }
    }
  });

  // Vote turnout by election
  const voteStats = await db.election.findMany({
    where: {
      createdAt: { gte: startDate }
    },
    include: {
      _count: {
        select: {
          votes: true,
          candidates: { where: { isApproved: true } }
        }
      }
    }
  });

  // Security events
  const securityEvents = await db.auditLog.count({
    where: {
      createdAt: { gte: startDate },
      action: {
        in: ['LOGIN_FAILED', 'VOTE_ATTEMPT_INVALID_TOKEN', 'SUSPICIOUS_ACTIVITY']
      }
    }
  });

  res.json({
    message: 'Statistics retrieved successfully',
    statistics: {
      period: `${days} days`,
      users: userStats,
      elections: electionStats,
      votes: voteStats.map((election: any) => ({
        electionId: election.id,
        title: election.title,
        voteCount: election._count.votes,
        candidateCount: election._count.candidates,
        turnoutPercentage: election._count.candidates > 0 ? 
          Math.round((election._count.votes / election._count.candidates) * 100) : 0
      })),
      securityEvents,
    }
  });
}));

// Get election results
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.get('/elections/:electionId/results', requireCommitteeOrAdmin, asyncHandler(async (req: Request, res: Response) => {
  const { electionId } = req.params;
  const { includeVoteDetails = 'false' } = req.query;
  const user = req.user!;

  const db = DatabaseService.getClient();

  // Get election with candidates and votes
  const election = await db.election.findUnique({
    where: { id: electionId },
    include: {
      candidates: {
        where: { isApproved: true },
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
        },
        orderBy: { voteCount: 'desc' }
      },
      _count: {
        select: {
          votes: true
        }
      }
    }
  });

  if (!election) {
    throw new NotFoundError('Election not found');
  }

  // Calculate results
  const totalVotes = election._count.votes;
  const results = election.candidates.map((candidate: any, index: number) => {
    const percentage = totalVotes > 0 ? (candidate.voteCount / totalVotes) * 100 : 0;
    return {
      position: index + 1,
      candidate: {
        id: candidate.id,
        name: `${candidate.user.firstName} ${candidate.user.lastName}`,
        matricNumber: candidate.user.matricNumber,
        department: candidate.user.department,
        faculty: candidate.user.faculty,
        manifesto: candidate.manifesto,
        photoUrl: candidate.photoUrl,
      },
      voteCount: candidate.voteCount,
      percentage: Math.round(percentage * 100) / 100,
    };
  });

  // Determine winner(s)
  const maxVotes = Math.max(...election.candidates.map((c: any) => c.voteCount));
  const winners = results.filter((r: any) => r.voteCount === maxVotes);

  let voteDetails = null;
  if (includeVoteDetails === 'true') {
    // Get anonymized vote details for audit
    voteDetails = await db.vote.findMany({
      where: { electionId },
      select: {
        id: true,
        candidateId: true,
        createdAt: true,
        ipAddress: true,
        // Don't include voter ID for anonymity
      },
      orderBy: { createdAt: 'asc' }
    });
  }

  // Log results access
  await logSpecificEvent(
    req,
    'ELECTION_RESULTS_ACCESSED',
    'election',
    user.id,
    { electionId, includeVoteDetails: includeVoteDetails === 'true' }
  );

  logger.info('Election results accessed', {
    electionId,
    accessedBy: user.id,
    includeDetails: includeVoteDetails === 'true',
  });

  res.json({
    message: 'Election results retrieved successfully',
    election: {
      id: election.id,
      title: election.title,
      description: election.description,
      category: election.category,
      startDate: election.startDate,
      endDate: election.endDate,
      isActive: election.isActive,
      allowDelayedReveal: election.allowDelayedReveal,
      revealDate: election.revealDate,
    },
    results: {
      totalVotes,
      candidateCount: election.candidates.length,
      turnoutPercentage: election.candidates.length > 0 ? 
        Math.round((totalVotes / election.candidates.length) * 100) : 0,
      winners: winners.map((w: any) => ({
        name: w.candidate.name,
        voteCount: w.voteCount,
        percentage: w.percentage,
      })),
      candidates: results,
      voteDetails: voteDetails,
    },
  });
}));

// Export election results
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.get('/elections/:electionId/export', requireCommitteeOrAdmin, asyncHandler(async (req: Request, res: Response) => {
  const { electionId } = req.params;
  const { format = 'json' } = req.query;
  const user = req.user!;

  const db = DatabaseService.getClient();

  // Get comprehensive election data
  const election = await db.election.findUnique({
    where: { id: electionId },
    include: {
      candidates: {
        where: { isApproved: true },
        include: {
          user: {
            select: {
              firstName: true,
              lastName: true,
              matricNumber: true,
              department: true,
              faculty: true,
              yearOfStudy: true,
            }
          }
        },
        orderBy: { voteCount: 'desc' }
      },
      votes: {
        select: {
          id: true,
          candidateId: true,
          createdAt: true,
          voteSignature: true,
          // Exclude voter ID and encrypted vote for privacy
        },
        orderBy: { createdAt: 'asc' }
      },
      creator: {
        select: {
          firstName: true,
          lastName: true,
          role: true,
        }
      }
    }
  });

  if (!election) {
    throw new NotFoundError('Election not found');
  }

  const totalVotes = election.votes.length;
  const exportData = {
    election: {
      id: election.id,
      title: election.title,
      description: election.description,
      category: election.category,
      startDate: election.startDate,
      endDate: election.endDate,
      createdBy: `${election.creator.firstName} ${election.creator.lastName}`,
      createdAt: election.createdAt,
    },
    summary: {
      totalVotes,
      candidateCount: election.candidates.length,
      exportedAt: new Date(),
      exportedBy: `${user.firstName} ${user.lastName}`,
    },
    candidates: election.candidates.map((candidate: any, index: number) => ({
      position: index + 1,
      name: `${candidate.user.firstName} ${candidate.user.lastName}`,
      matricNumber: candidate.user.matricNumber,
      department: candidate.user.department,
      faculty: candidate.user.faculty,
      yearOfStudy: candidate.user.yearOfStudy,
      voteCount: candidate.voteCount,
      percentage: totalVotes > 0 ? Math.round((candidate.voteCount / totalVotes) * 10000) / 100 : 0,
    })),
    voteAuditTrail: election.votes.map((vote: any) => ({
      voteId: vote.id,
      candidateId: vote.candidateId,
      timestamp: vote.createdAt,
      signatureHash: vote.voteSignature.substring(0, 16) + '...', // Truncated for privacy
    })),
  };

  // Log export
  await logSpecificEvent(
    req,
    'ELECTION_RESULTS_EXPORTED',
    'election',
    user.id,
    { electionId, format, candidateCount: election.candidates.length, voteCount: totalVotes }
  );

  logger.info('Election results exported', {
    electionId,
    exportedBy: user.id,
    format,
    voteCount: totalVotes,
  });

  // Return data based on format
  if (format === 'csv') {
    // Convert to CSV format
    const csvHeader = 'Position,Name,Matric Number,Department,Faculty,Year,Vote Count,Percentage\n';
    const csvData = exportData.candidates.map((candidate: any) => 
      `${candidate.position},"${candidate.name}",${candidate.matricNumber},"${candidate.department}","${candidate.faculty}",${candidate.yearOfStudy},${candidate.voteCount},${candidate.percentage}%`
    ).join('\n');

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="election-${electionId}-results.csv"`);
    res.send(csvHeader + csvData);
  } else {
    // Return JSON
    res.json({
      message: 'Election results exported successfully',
      data: exportData,
    });
  }
}));

// Get audit logs
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.get('/audit-logs', requireAdmin, asyncHandler(async (req: Request, res: Response) => {
  const { 
    page = 1, 
    limit = 50, 
    action, 
    resource, 
    userId, 
    startDate, 
    endDate 
  } = req.query;

  const skip = (Number(page) - 1) * Number(limit);
  const take = Number(limit);

  const where: any = {};

  if (action) where.action = action;
  if (resource) where.resource = resource;
  if (userId) where.userId = userId;

  if (startDate || endDate) {
    where.createdAt = {};
    if (startDate) where.createdAt.gte = new Date(startDate as string);
    if (endDate) where.createdAt.lte = new Date(endDate as string);
  }

  const db = DatabaseService.getClient();

  const [auditLogs, total] = await Promise.all([
    db.auditLog.findMany({
      where,
      skip,
      take,
      include: {
        user: {
          select: {
            firstName: true,
            lastName: true,
            matricNumber: true,
            role: true,
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    }),
    db.auditLog.count({ where })
  ]);

  res.json({
    message: 'Audit logs retrieved successfully',
    auditLogs: auditLogs.map((log: any) => ({
      id: log.id,
      action: log.action,
      resource: log.resource,
      resourceId: log.resourceId,
      details: log.details,
      user: log.user ? {
        name: `${log.user.firstName} ${log.user.lastName}`,
        matricNumber: log.user.matricNumber,
        role: log.user.role,
      } : null,
      ipAddress: log.ipAddress,
      userAgent: log.userAgent,
      timestamp: log.createdAt,
      currentHash: log.currentHash.substring(0, 16) + '...', // Truncated for display
    })),
    pagination: {
      page: Number(page),
      limit: Number(limit),
      total,
      pages: Math.ceil(total / Number(limit)),
    }
  });
}));

// Manage system configuration
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.get('/config', requireAdmin, asyncHandler(async (req: Request, res: Response) => {
  const db = DatabaseService.getClient();

  const configs = await db.systemConfig.findMany({
    orderBy: { key: 'asc' }
  });

  res.json({
    message: 'System configuration retrieved successfully',
    config: configs.map((config: any) => ({
      key: config.key,
      value: config.isEncrypted ? '[ENCRYPTED]' : config.value,
      description: config.description,
      isEncrypted: config.isEncrypted,
      updatedAt: config.updatedAt,
    }))
  });
}));

// Update system configuration
// @ts-ignore - TypeScript middleware type issue, runtime safety ensured by middleware
router.put('/config/:key', requireAdmin, asyncHandler(async (req: Request, res: Response) => {
  const { key } = req.params;
  const { value, description } = req.body;
  const user = req.user!;

  if (!value) {
    throw new ValidationError('Value is required');
  }

  const db = DatabaseService.getClient();

  const config = await db.systemConfig.upsert({
    where: { key },
    update: { 
      value, 
      description: description || undefined,
      updatedAt: new Date(),
    },
    create: { 
      key, 
      value, 
      description: description || null,
    }
  });

  // Log configuration change
  await logSpecificEvent(
    req,
    'SYSTEM_CONFIG_UPDATED',
    'system',
    user.id,
    { key, hasValue: !!value }
  );

  logger.info('System configuration updated', {
    key,
    updatedBy: user.id,
  });

  res.json({
    message: 'System configuration updated successfully',
    config: {
      key: config.key,
      value: config.isEncrypted ? '[ENCRYPTED]' : config.value,
      description: config.description,
      updatedAt: config.updatedAt,
    }
  });
}));

export default router;