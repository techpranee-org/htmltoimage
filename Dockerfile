FROM mcr.microsoft.com/playwright:v1.40.0-focal

WORKDIR /app

# Copy package files
COPY app/package.json app/package-lock.json* ./

# Install dependencies
RUN npm install --prefer-offline --no-audit

# Copy application files
COPY app/ ./

# Set environment
ENV NODE_ENV=production
ENV PORT=3000

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
  CMD curl -f http://localhost:3000/health || exit 1

# Start the app
CMD ["node", "server.js"]
