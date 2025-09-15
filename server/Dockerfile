# Electra Server Dockerfile
FROM node:18-alpine

# Install build dependencies
RUN apk add --no-cache python3 make g++ openssl

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S electra -u 1001

# Create necessary directories
RUN mkdir -p /app/logs /app/keys /app/uploads
RUN chown -R electra:nodejs /app

# Switch to non-root user
USER electra

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/api/v1/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Start the application
CMD ["npm", "start"]