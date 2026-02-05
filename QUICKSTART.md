# 🎨 Playwright Renderer - Complete Setup Guide

## Overview

This is a **production-ready** HTML to image rendering service using Playwright, Express.js, and Node.js. It works **without building any Docker images** - uses official Microsoft Playwright image.

## ✨ Key Features

- ✅ **No Docker Build** - Uses pre-built `mcr.microsoft.com/playwright` image
- ✅ **Stateless Design** - No volumes, all temp data in Redis
- ✅ **Three Rendering Modes**:
  - Synchronous: HTML → Image (instant)
  - URL Rendering: Website → Image (includes network load)
  - Asynchronous: Queue jobs with Redis
- ✅ **Job Caching** - Redis-backed with 1-hour TTL
- ✅ **Health Monitoring** - Built-in health checks & metrics
- ✅ **Base64 Response** - Images returned as base64 in JSON
- ✅ **File Download** - Direct file download via `/download/:jobId`
- ✅ **Error Handling** - Comprehensive error responses
- ✅ **Node.js Client** - Included `client.js` library

## 📋 Prerequisites

```bash
# Check requirements
docker --version   # Need Docker
docker-compose --version  # Need Docker Compose
curl --version  # For testing (optional)
```

No other dependencies needed - everything is containerized!

## 🚀 Getting Started (3 Steps)

### Step 1: Navigate to the service directory
```bash
cd /Users/mohanpraneeth/Desktop/Coding/docker-compose-apps/rendered/
```

### Step 2: Start the service
```bash
# Option A: Using docker-compose directly
docker-compose up -d

# Option B: Using the startup script
./start.sh
```

### Step 3: Verify it's running
```bash
curl http://localhost:3000/health
# Response: {"status":"ok","timestamp":"..."}
```

That's it! No building required. 🎉

## 📁 Directory Structure

```
rendered/
├── docker-compose.yml          # Main compose file (stateless)
├── docker-compose-prod.yml     # Production config with limits
├── .env.example                # Environment variables template
├── README.md                   # Detailed API documentation
├── QUICKSTART.md               # This file
├── start.sh                    # Quick startup script
├── test-api.sh                 # API test suite
├── app/
│   ├── package.json            # Node.js dependencies
│   ├── server.js              # Main Express server
│   ├── client.js              # Node.js client library
│   ├── examples.js            # Usage examples
│   └── uploads/               # Temp storage (auto-created)
└── README.md                   # Full API documentation
```

## 🔧 Common Commands

### Start Service
```bash
# Development (with logs)
docker-compose up

# Background (detached)
docker-compose up -d

# Production
docker-compose -f docker-compose-prod.yml up -d
```

### Stop Service
```bash
docker-compose down

# With volume cleanup
docker-compose down -v
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f playwright-renderer
docker-compose logs -f redis

# Last 100 lines
docker-compose logs --tail=100 playwright-renderer
```

### Health Check
```bash
# Quick health check
curl http://localhost:3000/health

# Full status
curl http://localhost:3000/status

# Docker health
docker-compose ps
```

## 💻 API Quick Reference

### 1. Render HTML String
```bash
curl -X POST http://localhost:3000/render \
  -H "Content-Type: application/json" \
  -d '{
    "html": "<h1>Hello World</h1>",
    "options": {
      "width": 1280,
      "height": 720,
      "format": "png"
    }
  }'
```

**Response includes:**
- `imageBase64` - Base64 encoded image
- `size` - Image file size in bytes
- `format` - Output format (png/jpeg)
- `requestId` - Unique request ID

### 2. Render Live Website
```bash
curl -X POST http://localhost:3000/render-url \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com",
    "options": {
      "format": "png",
      "waitFor": 2000
    }
  }'
```

### 3. Queue Async Job
```bash
# Queue the job
curl -X POST http://localhost:3000/render-async \
  -H "Content-Type: application/json" \
  -d '{"html": "<h1>Test</h1>"}' \
  | jq '.jobId' -r

# Get job status (returns jobId like: "550e8400-e29b-41d4...")
# Save it as: JOB_ID="550e8400-e29b-41d4..."

# Check status
curl http://localhost:3000/render-async/$JOB_ID

# Download when complete
curl -o output.png http://localhost:3000/download/$JOB_ID
```

## 🧪 Testing

### Run All Tests
```bash
cd /Users/mohanpraneeth/Desktop/Coding/docker-compose-apps/rendered/
./test-api.sh
```

This tests:
- ✅ Health check
- ✅ Status endpoint
- ✅ HTML rendering
- ✅ URL rendering
- ✅ Async rendering
- ✅ Job status checking
- ✅ Error handling

### Run Examples
```bash
cd app/
node examples.js          # Run all examples
node examples.js 1        # Example 1: Render HTML
node examples.js 2        # Example 2: Render URL
node examples.js 3        # Example 3: Async render
node examples.js 4        # Example 4: Health check
```

## 🔌 Using the Node.js Client

```javascript
const RendererClient = require('./app/client');

const client = new RendererClient('http://localhost:3000');

// Render HTML to image
const result = await client.renderHTML(
  '<h1>Hello</h1><p>This is rendered!</p>',
  { width: 800, height: 600, format: 'png' }
);

// Get Base64 image
console.log(result.data.imageBase64);

// Render a website
const urlResult = await client.renderURL('https://google.com');

// Async rendering
const jobResult = await client.renderAsync('<h1>Async</h1>');
const jobId = jobResult.jobId;

// Poll for completion
const status = await client.getJobStatus(jobId);
if (status.status === 'completed') {
  await client.downloadImage(jobId, './output.png');
}
```

## 🎨 HTML/CSS Features

Playwright supports full HTML5 and modern CSS:

```html
<!-- ✅ Supported -->
<style>
  @media print { /* Media queries work */ }
  animation: spin 1s; /* Animations render */ }
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
</style>

<!-- ✅ JavaScript runs -->
<script>
  document.body.style.color = 'red'; // DOM manipulation works
</script>
```

## ⚙️ Configuration Options

### Render Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `width` | number | 1280 | Viewport width in pixels |
| `height` | number | 720 | Viewport height in pixels |
| `format` | string | "png" | Output format: "png" or "jpeg" |
| `waitFor` | number | 1000 | Wait time (ms) before capture |

### Environment Variables

```bash
NODE_ENV=production     # Set to 'production' for production use
PORT=3000              # HTTP server port
REDIS_HOST=redis       # Redis hostname
REDIS_PORT=6379        # Redis port
JOB_TTL=3600          # Job cache TTL in seconds
```

## 📊 Performance Tips

### For Fast Responses
- Use `/render` for simple HTML (no network requests)
- Keep viewport small if possible
- Reduce `waitFor` time to 500ms
- Use JPEG format for photos (smaller files)

### For Complex Pages
- Use `/render-url` for real websites
- Increase `waitFor` to 2000-3000ms
- Use `/render-async` for batch processing
- Check Redis queue: `docker-compose exec redis redis-cli INFO stats`

### Memory Usage
- Each render uses ~100-200MB
- Set resource limits in `docker-compose-prod.yml`
- Monitor with: `docker stats`

## 🐛 Troubleshooting

### Service won't start
```bash
# Check logs
docker-compose logs playwright-renderer

# Verify port is free
lsof -i :3000

# Check Docker resources
docker system df
```

### Images are incomplete/blank
```bash
# Solution 1: Increase waitFor
curl -X POST http://localhost:3000/render \
  -d '{"html":"...", "options":{"waitFor":2000}}'

# Solution 2: Use render-url for websites with JS
curl -X POST http://localhost:3000/render-url \
  -d '{"url":"https://example.com"}'
```

### Redis errors
```bash
# Check Redis is running
docker-compose ps redis

# Verify connectivity
docker-compose exec redis redis-cli ping
# Should return: PONG
```

### Out of memory
```bash
# Check container limits
docker stats playwright-renderer

# Update docker-compose-prod.yml limits
# Then restart:
docker-compose -f docker-compose-prod.yml restart
```

## 🌍 Deployment

### Local Development
```bash
docker-compose up -d
# Runs on http://localhost:3000
```

### Production (Single Server)
```bash
docker-compose -f docker-compose-prod.yml up -d
# Includes resource limits and health checks
```

### Production (Multiple Instances)
```bash
# Scale the renderer service
docker-compose -f docker-compose-prod.yml up -d --scale playwright-renderer=3

# Use a load balancer (nginx, HAProxy) to distribute requests
```

### Cloud Deployment (AWS, GCP, Azure)
```bash
# Push to your registry
docker tag playwright-renderer:latest your-registry/renderer:latest
docker push your-registry/renderer:latest

# Update docker-compose to use your image
# Deploy using ECS, AKS, Cloud Run, etc.
```

## 📈 Monitoring

### Health Checks
```bash
# Automated health check (every 10s)
curl http://localhost:3000/health

# In production monitoring
# Add to Prometheus/DataDog/New Relic
curl http://localhost:3000/health | jq '.status'
```

### Job Monitoring
```bash
# Check Redis stats
docker-compose exec redis redis-cli INFO stats

# Monitor queue size
docker-compose exec redis redis-cli KEYS "job:*" | wc -l

# Check specific job
docker-compose exec redis redis-cli GET "job:550e8400-e29b-41d4-a716-446655440000"
```

### Resource Monitoring
```bash
# Real-time stats
docker stats playwright-renderer

# Check logs for errors
docker-compose logs --tail=50 | grep ERROR
```

## 🔒 Security

### Best Practices
1. **Limit HTML input size** - Currently 50MB, reduce in production
2. **Sanitize HTML** - Use DOMPurify or similar before sending
3. **Rate limiting** - Add nginx/HAProxy in front
4. **Authentication** - Add API key verification
5. **HTTPS** - Use TLS in production
6. **Network isolation** - Don't expose Redis to internet

### Example: Rate Limiting
```bash
# Add to docker-compose.yml nginx service
services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
```

## 📚 Additional Resources

- [Playwright Documentation](https://playwright.dev)
- [Express.js Guide](https://expressjs.com)
- [Docker Compose Reference](https://docs.docker.com/compose)
- [Redis Commands](https://redis.io/commands)

## ❓ FAQ

**Q: Do I need to build a Docker image?**
A: No! Uses the official Microsoft Playwright image.

**Q: Can I render URLs behind authentication?**
A: Yes, use cookies or Bearer tokens in the Playwright API.

**Q: What's the maximum HTML size?**
A: Currently 50MB, configured in express middleware.

**Q: How long are jobs cached?**
A: 1 hour (3600 seconds), configurable via environment.

**Q: Can I scale to multiple instances?**
A: Yes, use `docker-compose up -d --scale playwright-renderer=3`

**Q: Does it support JavaScript rendering?**
A: Yes, fully supported. Increase `waitFor` for dynamic content.

**Q: Can I get detailed error logs?**
A: Yes, check `docker-compose logs` for error details.

## 🤝 Support

If you encounter issues:
1. Check logs: `docker-compose logs -f`
2. Verify health: `curl http://localhost:3000/health`
3. Test API: `./test-api.sh`
4. Review examples: `node app/examples.js`

## 📄 License

MIT - Free to use and modify
