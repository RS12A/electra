import nodemailer from 'nodemailer';
import { LoggerService } from './LoggerService';

interface EmailConfig {
  host: string;
  port: number;
  secure: boolean;
  auth: {
    user: string;
    pass: string;
  };
}

interface EmailData {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

export class EmailService {
  private static transporter: nodemailer.Transporter | null = null;
  private static logger: LoggerService = new LoggerService();
  private static isInitialized: boolean = false;

  static async initialize() {
    try {
      const provider = process.env.EMAIL_PROVIDER || 'smtp';

      if (provider === 'mock') {
        this.logger.info('Email service initialized in mock mode');
        this.isInitialized = true;
        return;
      }

      const config: EmailConfig = {
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: parseInt(process.env.SMTP_PORT || '587'),
        secure: process.env.SMTP_SECURE === 'true',
        auth: {
          user: process.env.SMTP_USER || '',
          pass: process.env.SMTP_PASS || '',
        },
      };

      // Validate configuration
      if (!config.auth.user || !config.auth.pass) {
        throw new Error('SMTP credentials not configured');
      }

      this.transporter = nodemailer.createTransport(config);

      // Verify connection
      if (this.transporter) {
        await this.transporter.verify();
      }
      
      this.logger.info('Email service initialized successfully', {
        provider,
        host: config.host,
        port: config.port,
      });
      
      this.isInitialized = true;
    } catch (error) {
      this.logger.error('Email service initialization failed', error);
      
      // In development, fall back to mock mode
      if (process.env.NODE_ENV === 'development') {
        this.logger.warn('Falling back to mock email mode in development');
        this.isInitialized = true;
      } else {
        throw error;
      }
    }
  }

  private static async sendEmail(emailData: EmailData): Promise<boolean> {
    try {
      if (!this.isInitialized) {
        await this.initialize();
      }

      const provider = process.env.EMAIL_PROVIDER || 'smtp';
      const fromAddress = process.env.SMTP_FROM || 'Electra Voting System <noreply@electra.edu>';

      if (provider === 'mock' || !this.transporter) {
        // Mock email sending for development/testing
        this.logger.info('Mock email sent', {
          to: emailData.to,
          subject: emailData.subject,
          provider: 'mock',
        });
        
        // In development, log the email content for debugging
        if (process.env.NODE_ENV === 'development') {
          console.log('\n--- MOCK EMAIL ---');
          console.log(`To: ${emailData.to}`);
          console.log(`From: ${fromAddress}`);
          console.log(`Subject: ${emailData.subject}`);
          console.log('Content:');
          console.log(emailData.text || emailData.html);
          console.log('--- END MOCK EMAIL ---\n');
        }
        
        return true;
      }

      const mailOptions = {
        from: fromAddress,
        to: emailData.to,
        subject: emailData.subject,
        html: emailData.html,
        text: emailData.text,
      };

      await this.transporter.sendMail(mailOptions);
      
      this.logger.info('Email sent successfully', {
        to: emailData.to,
        subject: emailData.subject,
        provider: 'smtp',
      });

      return true;
    } catch (error) {
      this.logger.error('Failed to send email', error, {
        to: emailData.to,
        subject: emailData.subject,
      });
      return false;
    }
  }

  static async sendVerificationEmail(email: string, firstName: string, token: string): Promise<boolean> {
    const universityName = process.env.UNIVERSITY_NAME || 'Kwara State University';
    const baseUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
    const verificationUrl = `${baseUrl}/verify-email?token=${token}`;

    const subject = `Welcome to Electra - Verify Your Email`;
    
    const html = `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Email Verification</title>
        <style>
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
          }
          .container {
            background-color: #ffffff;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
          }
          .header {
            text-align: center;
            margin-bottom: 30px;
          }
          .logo {
            font-size: 24px;
            font-weight: bold;
            color: #1976d2;
            margin-bottom: 10px;
          }
          .university {
            color: #666;
            font-size: 14px;
          }
          .content {
            margin-bottom: 30px;
          }
          .button {
            display: inline-block;
            padding: 12px 24px;
            background-color: #1976d2;
            color: #ffffff;
            text-decoration: none;
            border-radius: 6px;
            font-weight: bold;
            text-align: center;
            margin: 20px 0;
          }
          .button:hover {
            background-color: #1565c0;
          }
          .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            font-size: 12px;
            color: #666;
            text-align: center;
          }
          .token {
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 6px;
            font-family: monospace;
            word-break: break-all;
            margin: 15px 0;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="logo">🗳️ Electra</div>
            <div class="university">${universityName}</div>
          </div>
          
          <div class="content">
            <h2>Welcome, ${firstName}!</h2>
            <p>Thank you for registering with the Electra Voting System. To complete your registration, please verify your email address.</p>
            
            <p><strong>Click the button below to verify your email:</strong></p>
            <div style="text-align: center;">
              <a href="${verificationUrl}" class="button">Verify Email Address</a>
            </div>
            
            <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
            <div class="token">${verificationUrl}</div>
            
            <p><strong>Or use this verification code directly in the app:</strong></p>
            <div class="token">${token}</div>
            
            <p><strong>Important:</strong> This verification link will expire in 24 hours. If you didn't create an account with us, please ignore this email.</p>
          </div>
          
          <div class="footer">
            <p>This email was sent from the Electra Voting System at ${universityName}.</p>
            <p>If you have any questions, please contact your electoral committee.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    const text = `
      Welcome to Electra Voting System, ${firstName}!
      
      Please verify your email address by visiting this link:
      ${verificationUrl}
      
      Or use this verification code: ${token}
      
      This link will expire in 24 hours.
      
      ${universityName} Electoral Committee
    `;

    return this.sendEmail({
      to: email,
      subject,
      html,
      text,
    });
  }

  static async sendPasswordResetEmail(email: string, firstName: string, token: string): Promise<boolean> {
    const universityName = process.env.UNIVERSITY_NAME || 'Kwara State University';
    const baseUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
    const resetUrl = `${baseUrl}/reset-password?token=${token}`;

    const subject = `Electra - Password Reset Request`;
    
    const html = `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Password Reset</title>
        <style>
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
          }
          .container {
            background-color: #ffffff;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
          }
          .header {
            text-align: center;
            margin-bottom: 30px;
          }
          .logo {
            font-size: 24px;
            font-weight: bold;
            color: #dc004e;
            margin-bottom: 10px;
          }
          .university {
            color: #666;
            font-size: 14px;
          }
          .content {
            margin-bottom: 30px;
          }
          .button {
            display: inline-block;
            padding: 12px 24px;
            background-color: #dc004e;
            color: #ffffff;
            text-decoration: none;
            border-radius: 6px;
            font-weight: bold;
            text-align: center;
            margin: 20px 0;
          }
          .button:hover {
            background-color: #b8003d;
          }
          .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            font-size: 12px;
            color: #666;
            text-align: center;
          }
          .token {
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 6px;
            font-family: monospace;
            word-break: break-all;
            margin: 15px 0;
          }
          .warning {
            background-color: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 6px;
            padding: 15px;
            margin: 15px 0;
            color: #856404;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="logo">🔐 Electra</div>
            <div class="university">${universityName}</div>
          </div>
          
          <div class="content">
            <h2>Password Reset Request</h2>
            <p>Hello ${firstName},</p>
            <p>We received a request to reset your password for your Electra account. If you made this request, click the button below to reset your password:</p>
            
            <div style="text-align: center;">
              <a href="${resetUrl}" class="button">Reset Password</a>
            </div>
            
            <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
            <div class="token">${resetUrl}</div>
            
            <p><strong>Or use this reset code directly in the app:</strong></p>
            <div class="token">${token}</div>
            
            <div class="warning">
              <strong>⚠️ Security Notice:</strong>
              <ul>
                <li>This reset link will expire in 1 hour</li>
                <li>If you didn't request this reset, please ignore this email</li>
                <li>Your password will remain unchanged unless you click the link above</li>
                <li>For security, please use a strong, unique password</li>
              </ul>
            </div>
          </div>
          
          <div class="footer">
            <p>This email was sent from the Electra Voting System at ${universityName}.</p>
            <p>If you have security concerns, please contact your electoral committee immediately.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    const text = `
      Password Reset Request - Electra Voting System
      
      Hello ${firstName},
      
      We received a request to reset your password. If you made this request, visit this link:
      ${resetUrl}
      
      Or use this reset code: ${token}
      
      This link expires in 1 hour.
      
      If you didn't request this reset, please ignore this email.
      
      ${universityName} Electoral Committee
    `;

    return this.sendEmail({
      to: email,
      subject,
      html,
      text,
    });
  }

  static async sendElectionNotification(
    email: string,
    firstName: string,
    electionTitle: string,
    startDate: Date,
    endDate: Date
  ): Promise<boolean> {
    const universityName = process.env.UNIVERSITY_NAME || 'Kwara State University';
    const baseUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
    
    const subject = `🗳️ Election Alert: ${electionTitle}`;
    
    const html = `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Election Notification</title>
        <style>
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
          }
          .container {
            background-color: #ffffff;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
          }
          .header {
            text-align: center;
            margin-bottom: 30px;
          }
          .logo {
            font-size: 24px;
            font-weight: bold;
            color: #4caf50;
            margin-bottom: 10px;
          }
          .election-info {
            background-color: #e8f5e8;
            border-left: 4px solid #4caf50;
            padding: 20px;
            margin: 20px 0;
            border-radius: 0 6px 6px 0;
          }
          .button {
            display: inline-block;
            padding: 12px 24px;
            background-color: #4caf50;
            color: #ffffff;
            text-decoration: none;
            border-radius: 6px;
            font-weight: bold;
            text-align: center;
            margin: 20px 0;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="logo">🗳️ Electra</div>
            <div class="university">${universityName}</div>
          </div>
          
          <div class="content">
            <h2>Election Notification</h2>
            <p>Dear ${firstName},</p>
            <p>An election you are eligible to participate in has been scheduled:</p>
            
            <div class="election-info">
              <h3>${electionTitle}</h3>
              <p><strong>Voting Period:</strong></p>
              <p>📅 <strong>Start:</strong> ${startDate.toLocaleString()}</p>
              <p>🏁 <strong>End:</strong> ${endDate.toLocaleString()}</p>
            </div>
            
            <div style="text-align: center;">
              <a href="${baseUrl}/elections" class="button">View Elections</a>
            </div>
            
            <p><strong>Important Reminders:</strong></p>
            <ul>
              <li>Make sure your account is verified before voting</li>
              <li>You can only vote once per election</li>
              <li>Voting is anonymous and secure</li>
              <li>Results will be available after the voting period ends</li>
            </ul>
          </div>
        </div>
      </body>
      </html>
    `;

    const text = `
      Election Notification - ${electionTitle}
      
      Dear ${firstName},
      
      An election you are eligible for has been scheduled:
      
      Election: ${electionTitle}
      Start: ${startDate.toLocaleString()}
      End: ${endDate.toLocaleString()}
      
      Visit ${baseUrl}/elections to participate.
      
      ${universityName} Electoral Committee
    `;

    return this.sendEmail({
      to: email,
      subject,
      html,
      text,
    });
  }

  static async sendVoteConfirmation(
    email: string,
    firstName: string,
    electionTitle: string,
    voteTime: Date
  ): Promise<boolean> {
    const universityName = process.env.UNIVERSITY_NAME || 'Kwara State University';
    
    const subject = `Vote Confirmation: ${electionTitle}`;
    
    const html = `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Vote Confirmation</title>
        <style>
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
          }
          .container {
            background-color: #ffffff;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
          }
          .success {
            background-color: #d4edda;
            border: 1px solid #c3e6cb;
            border-radius: 6px;
            padding: 20px;
            margin: 20px 0;
            text-align: center;
            color: #155724;
          }
          .logo {
            font-size: 24px;
            font-weight: bold;
            color: #4caf50;
            text-align: center;
            margin-bottom: 10px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="logo">✅ Electra</div>
          
          <div class="success">
            <h2>Vote Recorded Successfully!</h2>
            <p>Your vote for <strong>${electionTitle}</strong> has been securely recorded.</p>
            <p><strong>Time:</strong> ${voteTime.toLocaleString()}</p>
          </div>
          
          <p>Dear ${firstName},</p>
          <p>Thank you for participating in the democratic process. Your vote has been:</p>
          <ul>
            <li>✅ Encrypted and stored securely</li>
            <li>✅ Verified for integrity</li>
            <li>✅ Added to the audit trail</li>
            <li>✅ Kept completely anonymous</li>
          </ul>
          
          <p>You cannot vote again for this election. Results will be available after the voting period ends.</p>
          
          <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; font-size: 12px; color: #666; text-align: center;">
            <p>${universityName} Electoral Committee</p>
          </div>
        </div>
      </body>
      </html>
    `;

    const text = `
      Vote Confirmation - ${electionTitle}
      
      Dear ${firstName},
      
      Your vote has been successfully recorded for ${electionTitle} at ${voteTime.toLocaleString()}.
      
      Your vote is secure, encrypted, and anonymous.
      
      Thank you for participating!
      
      ${universityName} Electoral Committee
    `;

    return this.sendEmail({
      to: email,
      subject,
      html,
      text,
    });
  }

  static async testEmailConfiguration(): Promise<boolean> {
    try {
      const testEmail = process.env.SMTP_USER || 'test@example.com';
      
      return await this.sendEmail({
        to: testEmail,
        subject: 'Electra Email Service Test',
        html: '<h1>Email Service Test</h1><p>If you receive this email, the service is working correctly.</p>',
        text: 'Email Service Test\n\nIf you receive this email, the service is working correctly.',
      });
    } catch (error) {
      this.logger.error('Email configuration test failed', error);
      return false;
    }
  }
}