const express = require('express');
const playwright = require('playwright');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const redis = require('redis');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb' }));

// File uploads directory
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const upload = multer({ dest: uploadsDir });

// Redis client
let redisClient;
(async () => {
  redisClient = redis.createClient({
    host: process.env.REDIS_HOST || 'redis',
    port: process.env.REDIS_PORT || 6379,
  });

  redisClient.on('error', (err) => console.log('Redis Client Error', err));
  await redisClient.connect();
  console.log('✓ Connected to Redis');
})();

// Browser instance management
let browser;

async function getBrowser() {
  if (!browser) {
    browser = await playwright.chromium.launch({
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });
    console.log('✓ Browser launched');
  }
  return browser;
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Status endpoint
app.get('/status', (req, res) => {
  res.json({
    status: 'running',
    service: 'Playwright HTML Renderer',
    timestamp: new Date().toISOString(),
  });
});

/**
 * Render HTML to Image
 * POST /render
 * Body: { html: string, options?: { width, height, format } }
 * Returns: { imageBase64: string, contentType: string, size: number }
 */
app.post('/render', async (req, res) => {
  try {
    const { html, options = {} } = req.body;

    if (!html) {
      return res.status(400).json({ error: 'HTML content is required' });
    }

    const {
      width = 1280,
      height = 720,
      format = 'png',
      waitFor = 1000,
    } = options;

    const requestId = uuidv4();
    console.log(`[${requestId}] Rendering HTML to ${format}...`);

    const browserInstance = await getBrowser();
    const context = await browserInstance.newContext({
      viewport: { width: parseInt(width), height: parseInt(height) },
    });

    const page = await context.newPage();

    // Set HTML content
    await page.setContent(html, { waitUntil: 'networkidle' });

    // Wait for any dynamic content
    if (waitFor > 0) {
      await page.waitForTimeout(parseInt(waitFor));
    }

    // Take screenshot
    const screenshot = await page.screenshot({
      fullPage: false,
      type: format,
    });

    // Convert to Base64
    const imageBase64 = screenshot.toString('base64');

    // Clean up
    await page.close();
    await context.close();

    console.log(`[${requestId}] Rendered successfully - Size: ${screenshot.length} bytes`);

    res.json({
      success: true,
      data: {
        imageBase64,
        contentType: `image/${format}`,
        size: screenshot.length,
        format,
        width,
        height,
        requestId,
      },
    });
  } catch (error) {
    console.error('Render Error:', error.message);
    res.status(500).json({
      error: 'Failed to render HTML',
      message: error.message,
    });
  }
});

/**
 * Render URL to Image
 * POST /render-url
 * Body: { url: string, options?: { width, height, format } }
 * Returns: { imageBase64: string, contentType: string, size: number }
 */
app.post('/render-url', async (req, res) => {
  try {
    const { url, options = {} } = req.body;

    if (!url) {
      return res.status(400).json({ error: 'URL is required' });
    }

    const {
      width = 1280,
      height = 720,
      format = 'png',
      waitFor = 2000,
    } = options;

    const requestId = uuidv4();
    console.log(`[${requestId}] Rendering URL: ${url}`);

    const browserInstance = await getBrowser();
    const context = await browserInstance.newContext({
      viewport: { width: parseInt(width), height: parseInt(height) },
    });

    const page = await context.newPage();

    // Navigate to URL
    await page.goto(url, { waitUntil: 'networkidle' });

    // Wait for any dynamic content
    if (waitFor > 0) {
      await page.waitForTimeout(parseInt(waitFor));
    }

    // Take screenshot
    const screenshot = await page.screenshot({
      fullPage: false,
      type: format,
    });

    // Convert to Base64
    const imageBase64 = screenshot.toString('base64');

    // Clean up
    await page.close();
    await context.close();

    console.log(`[${requestId}] Rendered successfully - Size: ${screenshot.length} bytes`);

    res.json({
      success: true,
      data: {
        imageBase64,
        contentType: `image/${format}`,
        size: screenshot.length,
        format,
        width,
        height,
        url,
        requestId,
      },
    });
  } catch (error) {
    console.error('Render URL Error:', error.message);
    res.status(500).json({
      error: 'Failed to render URL',
      message: error.message,
    });
  }
});

/**
 * Async Render with Redis caching
 * POST /render-async
 * Body: { html: string, options?: { ... } }
 * Returns: { jobId: string }
 */
app.post('/render-async', async (req, res) => {
  try {
    const { html, options = {} } = req.body;

    if (!html) {
      return res.status(400).json({ error: 'HTML content is required' });
    }

    const jobId = uuidv4();

    // Store job in Redis
    await redisClient.setEx(
      `job:${jobId}`,
      3600, // 1 hour TTL
      JSON.stringify({ status: 'pending', createdAt: new Date().toISOString() })
    );

    // Process asynchronously
    processRenderJob(jobId, html, options);

    res.json({
      success: true,
      jobId,
      statusUrl: `/render-async/${jobId}`,
    });
  } catch (error) {
    console.error('Async Render Error:', error.message);
    res.status(500).json({ error: 'Failed to queue render job' });
  }
});

/**
 * Get async render result
 * GET /render-async/:jobId
 */
app.get('/render-async/:jobId', async (req, res) => {
  try {
    const { jobId } = req.params;
    const jobData = await redisClient.get(`job:${jobId}`);

    if (!jobData) {
      return res.status(404).json({ error: 'Job not found or expired' });
    }

    const job = JSON.parse(jobData);
    res.json(job);
  } catch (error) {
    res.status(500).json({ error: 'Failed to get job status' });
  }
});

/**
 * Download rendered image
 * GET /download/:jobId
 */
app.get('/download/:jobId', async (req, res) => {
  try {
    const { jobId } = req.params;
    const imagePath = path.join(uploadsDir, `${jobId}.png`);

    if (!fs.existsSync(imagePath)) {
      return res.status(404).json({ error: 'Image not found' });
    }

    res.download(imagePath, `rendered-${jobId}.png`);
  } catch (error) {
    res.status(500).json({ error: 'Failed to download image' });
  }
});

// Process render job asynchronously
async function processRenderJob(jobId, html, options) {
  try {
    const {
      width = 1280,
      height = 720,
      format = 'png',
      waitFor = 1000,
    } = options;

    // Update status
    await redisClient.setEx(
      `job:${jobId}`,
      3600,
      JSON.stringify({ status: 'processing', createdAt: new Date().toISOString() })
    );

    const browserInstance = await getBrowser();
    const context = await browserInstance.newContext({
      viewport: { width: parseInt(width), height: parseInt(height) },
    });

    const page = await context.newPage();
    await page.setContent(html, { waitUntil: 'networkidle' });

    if (waitFor > 0) {
      await page.waitForTimeout(parseInt(waitFor));
    }

    const screenshot = await page.screenshot({ fullPage: false, type: format });

    // Save image
    const imagePath = path.join(uploadsDir, `${jobId}.${format}`);
    fs.writeFileSync(imagePath, screenshot);

    // Update job status
    await redisClient.setEx(
      `job:${jobId}`,
      3600,
      JSON.stringify({
        status: 'completed',
        createdAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
        size: screenshot.length,
        format,
        width,
        height,
        downloadUrl: `/download/${jobId}`,
        imageBase64: screenshot.toString('base64'),
      })
    );

    await page.close();
    await context.close();

    console.log(`[${jobId}] Job completed successfully`);
  } catch (error) {
    console.error(`[${jobId}] Job failed:`, error.message);
    await redisClient.setEx(
      `job:${jobId}`,
      3600,
      JSON.stringify({
        status: 'failed',
        error: error.message,
        createdAt: new Date().toISOString(),
        failedAt: new Date().toISOString(),
      })
    );
  }
}

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM signal received: closing HTTP server');
  if (browser) {
    await browser.close();
  }
  if (redisClient) {
    await redisClient.quit();
  }
  process.exit(0);
});

// Start server
app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════╗
║   Playwright Renderer Service         ║
║   🚀 Running on http://localhost:${PORT}    ║
╚═══════════════════════════════════════╝

Available Endpoints:
  POST /render              - Convert HTML to Image
  POST /render-url          - Render URL to Image
  POST /render-async        - Queue HTML for async rendering
  GET  /render-async/:jobId - Get async job status
  GET  /download/:jobId     - Download rendered image
  GET  /health              - Health check
  GET  /status              - Service status
  `);
});
