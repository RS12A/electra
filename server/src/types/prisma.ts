// Mock Prisma types until we can run prisma generate
export interface User {
  id: string;
  matricNumber: string;
  email: string;
  passwordHash: string;
  firstName: string;
  lastName: string;
  role: UserRole;
  isActive: boolean;
  isVerified: boolean;
  department?: string | null;
  faculty?: string | null;
  yearOfStudy?: number | null;
  lastLogin?: Date | null;
  biometricEnabled: boolean;
  deviceIds: string[];
  createdAt: Date;
  updatedAt: Date;
}

export enum UserRole {
  STUDENT = 'STUDENT',
  CANDIDATE = 'CANDIDATE',
  ADMIN = 'ADMIN',
  ELECTORAL_COMMITTEE = 'ELECTORAL_COMMITTEE',
}

export interface PrismaClient {
  user: any;
  election: any;
  candidate: any;
  vote: any;
  ballotToken: any;
  refreshToken: any;
  otpToken: any;
  auditLog: any;
  systemConfig: any;
  $connect: () => Promise<void>;
  $disconnect: () => Promise<void>;
  $queryRaw: (query: any) => Promise<any>;
  $on: (event: string, callback: (e: any) => void) => void;
}

// Mock Prisma namespace
export namespace Prisma {
  export class PrismaClientKnownRequestError extends Error {
    code: string;
    meta?: any;
    constructor(message: string, { code, meta }: { code: string; meta?: any }) {
      super(message);
      this.code = code;
      this.meta = meta;
    }
  }
  
  export class PrismaClientUnknownRequestError extends Error {}
  export class PrismaClientRustPanicError extends Error {}
  export class PrismaClientInitializationError extends Error {}
  export class PrismaClientValidationError extends Error {}
}