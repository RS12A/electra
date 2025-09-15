import { SecurityService } from '../services/SecurityService';
import { LoggerService } from '../services/LoggerService';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const logger = new LoggerService();

async function generateKeys() {
  try {
    logger.info('Generating RSA key pair...');
    
    await SecurityService.generateRSAKeys();
    
    logger.info('RSA keys generated successfully!');
    logger.info('Keys saved to:');
    logger.info(`  Private key: ${process.env.VOTE_SIGNING_PRIVATE_KEY_PATH || './keys/private.pem'}`);
    logger.info(`  Public key: ${process.env.VOTE_SIGNING_PUBLIC_KEY_PATH || './keys/public.pem'}`);
    logger.info('');
    logger.info('⚠️  IMPORTANT SECURITY NOTES:');
    logger.info('1. Keep the private key secure and never share it');
    logger.info('2. The private key is used to sign votes for integrity');
    logger.info('3. Back up these keys securely');
    logger.info('4. In production, use proper key management services');
    
  } catch (error) {
    logger.error('Failed to generate RSA keys:', error);
    process.exit(1);
  }
}

// Run the key generation
if (require.main === module) {
  generateKeys();
}