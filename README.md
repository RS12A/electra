# 🗳️ Electra - University Voting System

Next-generation secure and scalable university voting system built with Flutter & Dart, designed for transparency and fairness.

## 🌟 Features

### 🔐 Security & Privacy
- **End-to-end encryption** with AES-256-GCM for votes
- **RSA-4096 digital signatures** for vote integrity
- **Tamper-proof audit trail** with blockchain-style hash chaining
- **Device attestation** (SafetyNet/DeviceCheck) for trusted devices
- **Biometric authentication** with secure fallback
- **Anonymous voting** with voter identity separation

### 🗳️ Voting Experience
- **Intuitive interface** with neomorphic design
- **Multi-platform support** (Android, iOS, Web)
- **Offline-first architecture** with secure sync
- **Real-time results** with delayed reveal options
- **Candidate profiles** with photos, manifestos, and videos
- **Push notifications** for election alerts

### 👥 User Management
- **Role-based access control** (Student, Candidate, Admin, Electoral Committee)
- **University-specific theming** with KWASU default
- **Email verification** and account recovery
- **Comprehensive audit logging**
- **Device management** and security monitoring

### 📊 Administration
- **Election lifecycle management** with scheduling
- **Live dashboards** with participation analytics
- **Results export** (CSV, XLSX, PDF) with verification
- **Turnout tracking** and engagement metrics
- **Security monitoring** and alert systems

## 🏗️ Architecture

### Backend
- **Node.js + TypeScript** for robust type safety
- **Express.js** with comprehensive middleware
- **PostgreSQL** with Prisma ORM
- **JWT authentication** with refresh tokens
- **WebSocket** for real-time updates
- **Email service** with beautiful templates

### Frontend
- **Flutter** for cross-platform consistency
- **Clean Architecture** with dependency injection
- **Offline-first** with Hive/Isar storage
- **State management** with Bloc/Cubit
- **Theme system** with university branding

### Security
- **Argon2** password hashing
- **RSA-4096** digital signatures
- **AES-256-GCM** vote encryption
- **TLS 1.3** enforced connections
- **Rate limiting** and anomaly detection

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ and npm 9+
- Flutter 3.16+
- PostgreSQL 12+
- Docker (optional)

### Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/RS12A/electra.git
   cd electra
   ```

2. **Start database services**
   ```bash
   docker-compose -f docker-compose.dev.yml up -d
   ```

3. **Setup backend**
   ```bash
   cd server
   npm install
   cp .env.example .env
   # Edit .env with your configuration
   npm run keys:generate  # Generate RSA keys
   npm run dev           # Start development server
   ```

4. **Setup frontend**
   ```bash
   cd ../client
   flutter pub get
   flutter run -d web    # Run on web
   ```

### Production Deployment

1. **Configure environment**
   ```bash
   cp .env.example .env
   # Set production values in .env
   ```

2. **Deploy with Docker**
   ```bash
   docker-compose up -d
   ```

3. **Initialize database**
   ```bash
   docker-compose exec electra-api npm run db:migrate
   docker-compose exec electra-api npm run db:seed
   ```

## 📊 API Documentation

### Authentication Endpoints
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/register` - User registration  
- `POST /api/v1/auth/verify-email` - Email verification
- `POST /api/v1/auth/forgot-password` - Password reset request
- `POST /api/v1/auth/reset-password` - Password reset
- `POST /api/v1/auth/refresh` - Token refresh
- `POST /api/v1/auth/logout` - User logout

### User Management
- `GET /api/v1/users/profile` - Get user profile
- `PUT /api/v1/users/profile` - Update profile
- `POST /api/v1/users/biometric` - Biometric settings
- `GET /api/v1/users` - List users (admin)

### Elections (Coming Soon)
- `GET /api/v1/elections` - List elections
- `POST /api/v1/elections` - Create election
- `GET /api/v1/elections/:id` - Get election details
- `POST /api/v1/votes` - Cast vote
- `GET /api/v1/votes/status` - Voting status

### System
- `GET /api/v1/health` - Health check
- `GET /api/v1/docs` - API documentation

## 🔧 Configuration

### Environment Variables

#### Required Production Variables
```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/electra

# Authentication
JWT_SECRET=your-secure-jwt-secret-32-chars
JWT_REFRESH_SECRET=your-refresh-secret-32-chars
VOTE_ENCRYPTION_KEY=your-32-byte-hex-encryption-key

# Email Service
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@domain.com
SMTP_PASS=your-app-password
SMTP_FROM="Electra Voting <noreply@yourdomain.com>"

# Security
CORS_ORIGINS=https://yourdomain.com
```

#### Optional Configuration
```bash
# University Branding
UNIVERSITY_NAME="Your University Name"
UNIVERSITY_ACRONYM="YUN"
FRONTEND_URL=https://voting.yourdomain.com

# Cloud Storage (Optional)
AWS_ACCESS_KEY_ID=your-aws-key
AWS_SECRET_ACCESS_KEY=your-aws-secret
AWS_S3_BUCKET=electra-files

# Push Notifications (Optional)  
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-firebase-key
```

## 🧪 Testing

### Backend Tests
```bash
cd server
npm test              # Run all tests
npm run test:watch    # Watch mode
npm run test:coverage # Coverage report
```

### Frontend Tests
```bash
cd client
flutter test          # Unit tests
flutter test integration_test  # Integration tests
```

### End-to-End Tests
```bash
# Start services
docker-compose -f docker-compose.dev.yml up -d
cd server && npm run dev &
cd client && flutter run -d web &

# Run E2E tests
npm run test:e2e
```

## 🔒 Security Considerations

### Production Checklist
- [ ] Generate secure RSA keys with `npm run keys:generate`
- [ ] Set strong JWT secrets (minimum 32 characters)
- [ ] Configure HTTPS with valid SSL certificates
- [ ] Set up proper CORS origins
- [ ] Enable database SSL connections
- [ ] Configure proper firewall rules
- [ ] Set up monitoring and alerting
- [ ] Regular security updates
- [ ] Backup encryption keys securely

### Key Management
```bash
# Generate production keys
npm run keys:generate

# Backup keys securely
cp keys/private.pem /secure/backup/location/
cp keys/public.pem /secure/backup/location/

# Set proper permissions
chmod 600 keys/private.pem
chmod 644 keys/public.pem
```

## 📈 Monitoring & Operations

### Health Checks
- API: `GET /api/v1/health`
- Database connectivity
- Email service status
- Encryption key availability

### Logging
- Structured JSON logs
- Automatic log rotation
- Security event tracking
- Performance metrics

### Backup Strategy
1. **Database**: Automated PostgreSQL backups
2. **Keys**: Secure RSA key storage
3. **Files**: Regular upload backup
4. **Configuration**: Version-controlled configs

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

### Development Guidelines
- Follow TypeScript strict mode
- Write tests for new features
- Update documentation
- Follow security best practices
- Use conventional commits

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏛️ Universities Using Electra

- Kwara State University (KWASU) - Reference Implementation
- [Add your university here]

## 📞 Support

- **Documentation**: [Full Documentation](docs/)
- **Issues**: [GitHub Issues](https://github.com/RS12A/electra/issues)
- **Security**: Report security issues to security@electra.edu
- **Community**: [Discord Server](https://discord.gg/electra)

## 🎯 Roadmap

### Phase 1 - Foundation ✅
- [x] Backend infrastructure
- [x] Authentication system
- [x] Security framework
- [x] Email service

### Phase 2 - Core Voting (In Progress)
- [ ] Election management
- [ ] Vote casting system
- [ ] Results calculation
- [ ] Flutter client

### Phase 3 - Advanced Features
- [ ] Multi-language support
- [ ] Advanced analytics
- [ ] Mobile app distribution
- [ ] Integration APIs

### Phase 4 - Scale & Performance
- [ ] Horizontal scaling
- [ ] Performance optimization
- [ ] Advanced monitoring
- [ ] Multi-tenant support

---

**Built with ❤️ for democratic participation in educational institutions.**
