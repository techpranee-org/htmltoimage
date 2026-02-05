# 🎨 Playwright Renderer Service

A production-ready HTML to image rendering service built with Playwright, Express, and Node.js. No Docker build required - uses pre-built Playwright image from Microsoft.

## Features

✅ **No Docker Build Required** - Uses official Microsoft Playwright image  
✅ **HTML to Image Conversion** - Convert HTML strings to PNG/JPEG  
✅ **URL Rendering** - Render live websites to images  
✅ **Async Processing** - Queue render jobs with Redis  
✅ **Job Tracking** - Poll job status and download results  
✅ **Caching** - Redis-backed job storage (1-hour TTL)  
✅ **Health Checks** - Built-in monitoring endpoints  
✅ **Stateless** - Uses cloud services (no volumes)  

## Quick Start

### Prerequisites
- Docker & Docker Compose installed
- No building required!

### Start the Service

```bash
cd rendered/
docker-compose up -d
```

The service will:
1. Pull the official Playwright image
2. Install dependencies automatically
3. Start the HTTP server on port 3000
4. Start Redis cache on port 6379

```bash
# Check service is running
curl http://localhost:3000/health
```

Output:
```json
{"status":"ok","timestamp":"2024-01-15T10:30:45.123Z"}
```

### Stop the Service

```bash
docker-compose down
```

## API Endpoints

### 1. **Synchronous HTML Rendering**

**Endpoint:** `POST /render`

Convert HTML string to image instantly.

**Request:**
```bash
curl -X POST http://localhost:3000/render \
  -H "Content-Type: application/json" \
  -d '{
    "html": "<h1>Hello World</h1>",
    "options": {
      "width": 1280,
      "height": 720,
      "format": "png",
      "waitFor": 1000
    }
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "imageBase64": "iVBORw0KGgoAAAANSUhEUgAAA...",
    "contentType": "image/png",
    "size": 2048,
    "format": "png",
    "width": 1280,
    "height": 720,
    "requestId": "550e8400-e29b-41d4-a716-446655440000"
  }
}
```

**Options:**
- `width` (number): Viewport width in pixels (default: 1280)
- `height` (number): Viewport height in pixels (default: 720)
- `format` (string): Output format - "png" or "jpeg" (default: "png")
- `waitFor` (number): Wait time in ms before capturing (default: 1000)

---

### 2. **URL Rendering**

**Endpoint:** `POST /render-url`

Render a live website to image.

**Request:**
```bash
curl -X POST http://localhost:3000/render-url \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com",
    "options": {
      "width": 1920,
      "height": 1080,
      "format": "png",
      "waitFor": 2000
    }
  }'
```

**Response:** Same as `/render` + `url` field

---

### 3. **Asynchronous Rendering**

**Endpoint:** `POST /render-async`

Queue a render job for processing. Returns immediately.

**Request:**
```bash
curl -X POST http://localhost:3000/render-async \
  -H "Content-Type: application/json" \
  -d '{
    "html": "<h1>Async Render</h1>",
    "options": {
      "width": 800,
      "height": 600,
      "format": "png"
    }
  }'
```

**Response:**
```json
{
  "success": true,
  "jobId": "550e8400-e29b-41d4-a716-446655440000",
  "statusUrl": "/render-async/550e8400-e29b-41d4-a716-446655440000"
}
```

---

### 4. **Get Async Job Status**

**Endpoint:** `GET /render-async/:jobId`

Check the status of a queued render job.

**Request:**
```bash
curl http://localhost:3000/render-async/550e8400-e29b-41d4-a716-446655440000
```

**Response (Processing):**
```json
{
  "status": "processing",
  "createdAt": "2024-01-15T10:30:45.123Z"
}
```

**Response (Completed):**
```json
{
  "status": "completed",
  "createdAt": "2024-01-15T10:30:45.123Z",
  "completedAt": "2024-01-15T10:30:48.456Z",
  "size": 2048,
  "format": "png",
  "width": 800,
  "height": 600,
  "downloadUrl": "/download/550e8400-e29b-41d4-a716-446655440000",
  "imageBase64": "iVBORw0KGgoAAAANSUhEUgAAA..."
}
```

**Response (Failed):**
```json
{
  "status": "failed",
  "error": "Error message",
  "createdAt": "2024-01-15T10:30:45.123Z",
  "failedAt": "2024-01-15T10:30:50.789Z"
}
```

---

### 5. **Download Rendered Image**

**Endpoint:** `GET /download/:jobId`

Download the rendered image file directly.

**Request:**
```bash
curl -o rendered-image.png \
  http://localhost:3000/download/550e8400-e29b-41d4-a716-446655440000
```

---

### 6. **Health Check**

**Endpoint:** `GET /health`

```bash
curl http://localhost:3000/health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:45.123Z"
}
```

---

### 7. **Service Status**

**Endpoint:** `GET /status`

```bash
curl http://localhost:3000/status
```

**Response:**
```json
{
  "status": "running",
  "service": "Playwright HTML Renderer",
  "timestamp": "2024-01-15T10:30:45.123Z"
}
```

---

## Node.js Client Library

Use the included `client.js` for easy integration in Node.js applications.

### Installation

```bash
npm install uuid  # Only dependency
```

### Usage

```javascript
const RendererClient = require('./client');

const client = new RendererClient('http://localhost:3000');

// Render HTML
const result = await client.renderHTML('<h1>Hello</h1>', {
  width: 1280,
  height: 720,
  format: 'png'
});

console.log(result.data.imageBase64);

// Render URL
const urlResult = await client.renderURL('https://example.com');

// Async render
const jobResult = await client.renderAsync('<h1>Async</h1>');
const jobId = jobResult.jobId;

// Check status
const status = await client.getJobStatus(jobId);

// Download image
await client.downloadImage(jobId, './output.png');
```

## Running Examples

Run all examples:
```bash
cd rendered/app
node examples.js
```

Run specific example:
```bash
node examples.js 1  # Render HTML
node examples.js 2  # Render URL
node examples.js 3  # Async render
node examples.js 4  # Health check
```

## Docker Compose Configuration

The service uses:
- **Image**: `mcr.microsoft.com/playwright:v1.40.0-focal` (official Microsoft image)
- **Port**: 3000 (HTTP server)
- **Redis**: 6379 (job caching)
- **No volumes**: Stateless design

```yaml
services:
  playwright-renderer:
    image: mcr.microsoft.com/playwright:v1.40.0-focal
    ports:
      - "3000:3000"
    command: sh -c "npm install && node server.js"
    # No volumes needed!
```

## Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌──────────────────────────┐
│  Express Server (3000)   │
│  - /render               │
│  - /render-url           │
│  - /render-async         │
│  - /download/:jobId      │
└──────┬───────────────────┘
       │
       ├──────────────┐
       │              │
       ▼              ▼
   ┌────────────┐  ┌──────────┐
   │ Playwright │  │  Redis   │
   │  Browser   │  │  Cache   │
   └────────────┘  └──────────┘
```

## Performance Tips

1. **Use async rendering** for bulk jobs
2. **Set appropriate `waitFor`** to ensure JavaScript execution
3. **Optimize viewport size** based on content needs
4. **Cache rendered images** in your application
5. **Use JPEG** for photography, PNG for graphics
6. **Monitor Redis** for job queue backlog

## Troubleshooting

### Service won't start
```bash
# Check logs
docker-compose logs -f playwright-renderer

# Check if port 3000 is available
lsof -i :3000
```

### Images look incomplete
- Increase `waitFor` time to let JavaScript render
- Use `/render-url` if page needs network requests
- Check browser console errors in logs

### Redis connection errors
```bash
# Verify Redis is running
docker-compose logs -f redis

# Check Redis connectivity
redis-cli -h localhost ping
```

### Out of memory
- Limit concurrent render jobs
- Close browser contexts properly (automatic)
- Monitor with: `docker stats`

## Production Deployment

### Using Docker
```bash
# With environment variables
docker-compose up -d

# Scale with multiple instances
docker-compose up -d --scale playwright-renderer=3
```

### Health monitoring
```bash
# Add to your monitoring
curl -f http://localhost:3000/health || exit 1
```

### Environment variables
```env
NODE_ENV=production
PORT=3000
REDIS_HOST=redis
REDIS_PORT=6379
```

## Limits & Best Practices

- **Max HTML size**: 50MB
- **Job TTL**: 1 hour (configurable in Redis)
- **Screenshot timeout**: 30 seconds (Playwright default)
- **Concurrent renders**: Limited by available memory

## File Structure

```
rendered/
├── docker-compose.yml      # Service configuration
├── README.md              # This file
└── app/
    ├── package.json       # Dependencies
    ├── server.js         # Main application
    ├── client.js         # Node.js client library
    ├── examples.js       # Usage examples
    └── uploads/          # Rendered images (created at runtime)
```

## License

MIT

## Support

For issues or questions:
1. Check the logs: `docker-compose logs`
2. Verify service health: `curl http://localhost:3000/health`
3. Test with examples: `node examples.js`
4. Check Redis: `docker-compose exec redis redis-cli ping`
