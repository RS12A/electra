import { DatabaseService } from '../services/DatabaseService';
import { LoggerService } from '../services/LoggerService';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const logger = new LoggerService();

async function runMigrations() {
  try {
    logger.info('Starting database migrations...');
    
    await DatabaseService.initialize();
    await DatabaseService.runMigrations();
    
    logger.info('Database migrations completed successfully!');
    
  } catch (error) {
    logger.error('Database migration failed:', error);
    process.exit(1);
  } finally {
    await DatabaseService.disconnect();
  }
}

// Run migrations
if (require.main === module) {
  runMigrations();
}