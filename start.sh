#!/bin/bash

# 🎨 Playwright Renderer Service - Quick Start

set -e

echo "╔════════════════════════════════════════╗"
echo "║  Playwright Renderer Service           ║"
echo "║  Starting up...                        ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
    exit 1
fi

echo -e "${YELLOW}📦 Starting services with docker-compose...${NC}"
docker-compose up -d

echo ""
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"

# Wait for service to be ready
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:3000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Service is ready!${NC}"
        break
    fi
    echo "  Attempt $((attempt + 1))/$max_attempts..."
    sleep 2
    ((attempt++))
done

if [ $attempt -eq $max_attempts ]; then
    echo -e "${RED}✗ Service failed to start${NC}"
    docker-compose logs
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════╗"
echo -e "║  ${GREEN}✓ Service is running!${NC}               ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Display endpoints
echo "📡 API Endpoints:"
echo "   POST   http://localhost:3000/render         - Render HTML to image"
echo "   POST   http://localhost:3000/render-url     - Render URL to image"
echo "   POST   http://localhost:3000/render-async   - Queue async render"
echo "   GET    http://localhost:3000/health         - Health check"
echo ""

# Test health
echo -e "${YELLOW}🏥 Testing health endpoint...${NC}"
response=$(curl -s http://localhost:3000/health)
echo -e "${GREEN}✓ Response: $response${NC}"
echo ""

echo "📚 Quick test:"
echo "   curl -X POST http://localhost:3000/render \\"
echo "     -H 'Content-Type: application/json' \\"
echo '     -d '"'"'{"html":"<h1>Test</h1>"}'"'"''
echo ""

echo "📖 For more examples, see: app/examples.js"
echo "   cd app && node examples.js"
echo ""

echo "🛑 To stop the service:"
echo "   docker-compose down"
echo ""
