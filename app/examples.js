const RendererClient = require('./client');

// Example 1: Render simple HTML
async function example1_renderHTML() {
  console.log('\n📝 Example 1: Render simple HTML\n');

  const client = new RendererClient('http://localhost:3000');

  const html = `
    <!DOCTYPE html>
    <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; padding: 20px; }
          h1 { color: #333; }
          .badge { background: #007bff; color: white; padding: 5px 10px; border-radius: 3px; }
        </style>
      </head>
      <body>
        <h1>Hello, Playwright! 🎉</h1>
        <p>This is a rendered HTML to image conversion.</p>
        <span class="badge">Rendered at ${new Date().toISOString()}</span>
      </body>
    </html>
  `;

  try {
    const result = await client.renderHTML(html, {
      width: 800,
      height: 600,
      format: 'png',
      waitFor: 500,
    });

    console.log(`✅ Rendered successfully!`);
    console.log(`   Format: ${result.data.format}`);
    console.log(`   Size: ${result.data.size} bytes`);
    console.log(`   Dimensions: ${result.data.width}x${result.data.height}`);
    console.log(`   Image (first 50 chars): ${result.data.imageBase64.substring(0, 50)}...`);
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

// Example 2: Render URL
async function example2_renderURL() {
  console.log('\n🌐 Example 2: Render URL\n');

  const client = new RendererClient('http://localhost:3000');

  try {
    const result = await client.renderURL('https://example.com', {
      width: 1280,
      height: 720,
      format: 'png',
      waitFor: 2000,
    });

    console.log(`✅ URL rendered successfully!`);
    console.log(`   URL: ${result.data.url}`);
    console.log(`   Size: ${result.data.size} bytes`);
    console.log(`   Dimensions: ${result.data.width}x${result.data.height}`);
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

// Example 3: Async render with job tracking
async function example3_asyncRender() {
  console.log('\n⏱️  Example 3: Async render with job tracking\n');

  const client = new RendererClient('http://localhost:3000');

  const html = `
    <!DOCTYPE html>
    <html>
      <head>
        <style>
          body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px; font-family: Arial; }
          .container { max-width: 600px; margin: 50px auto; text-align: center; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>Async Rendering Demo</h1>
          <p>This image was rendered asynchronously!</p>
        </div>
      </body>
    </html>
  `;

  try {
    // Queue job
    console.log('📤 Queuing render job...');
    const queueResult = await client.renderAsync(html);
    const jobId = queueResult.jobId;

    console.log(`   Job ID: ${jobId}`);
    console.log(`   Status URL: ${queueResult.statusUrl}`);

    // Poll for completion
    let isComplete = false;
    let attempts = 0;
    const maxAttempts = 30; // 30 seconds max wait

    while (!isComplete && attempts < maxAttempts) {
      await new Promise((resolve) => setTimeout(resolve, 1000)); // Wait 1 second
      attempts++;

      const status = await client.getJobStatus(jobId);
      console.log(`   Status (${attempts}s): ${status.status}`);

      if (status.status === 'completed') {
        isComplete = true;
        console.log(`✅ Job completed!`);
        console.log(`   Size: ${status.size} bytes`);
        console.log(`   Format: ${status.format}`);
      } else if (status.status === 'failed') {
        console.error(`❌ Job failed: ${status.error}`);
        return;
      }
    }

    if (!isComplete) {
      console.warn('⏳ Job still processing (timeout)');
    }
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

// Example 4: Service health check
async function example4_healthCheck() {
  console.log('\n❤️  Example 4: Health check\n');

  const client = new RendererClient('http://localhost:3000');

  try {
    const health = await client.health();
    console.log(`✅ Service is healthy!`);
    console.log(`   Status: ${health.status}`);
    console.log(`   Timestamp: ${health.timestamp}`);

    const status = await client.status();
    console.log(`   Service: ${status.service}`);
  } catch (error) {
    console.error('❌ Service is unavailable:', error.message);
  }
}

// Run all examples
async function runAllExamples() {
  console.log('='.repeat(50));
  console.log('🎨 Playwright Renderer - Examples');
  console.log('='.repeat(50));

  await example4_healthCheck();
  await example1_renderHTML();
  await example2_renderURL();
  await example3_asyncRender();

  console.log('\n' + '='.repeat(50));
  console.log('✨ Examples completed!');
  console.log('='.repeat(50));
}

// Run the specified example or all
const exampleNum = process.argv[2];

if (exampleNum === '1') {
  example1_renderHTML().catch(console.error);
} else if (exampleNum === '2') {
  example2_renderURL().catch(console.error);
} else if (exampleNum === '3') {
  example3_asyncRender().catch(console.error);
} else if (exampleNum === '4') {
  example4_healthCheck().catch(console.error);
} else {
  runAllExamples().catch(console.error);
}
