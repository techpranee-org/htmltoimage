#!/bin/bash

# 📡 Playwright Renderer - cURL Examples
# Copy-paste ready examples for testing the API

echo "🎨 Playwright Renderer - cURL Examples"
echo ""
echo "Service must be running on http://localhost:3000"
echo ""

# Color codes
GREEN='\033[0;32m'
NC='\033[0m'

# ============================================
# EXAMPLE 1: Simple HTML Render
# ============================================
echo -e "${GREEN}[EXAMPLE 1] Render Simple HTML${NC}"
echo ""
echo "curl -X POST http://localhost:3000/render \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{"
echo "    \"html\": \"<h1>Hello World</h1><p>This is rendered!</p>\","
echo "    \"options\": {"
echo "      \"width\": 1280,"
echo "      \"height\": 720,"
echo "      \"format\": \"png\","
echo "      \"waitFor\": 1000"
echo "    }"
echo "  }' | jq '.'"
echo ""

# ============================================
# EXAMPLE 2: Styled HTML Render
# ============================================
echo -e "${GREEN}[EXAMPLE 2] Render Styled HTML${NC}"
echo ""
echo "curl -X POST http://localhost:3000/render \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{
cat << 'EOF'
    "html": "<html><head><style>body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px; text-align: center; font-family: Arial, sans-serif; } h1 { font-size: 48px; margin-bottom: 20px; } p { font-size: 24px; }</style></head><body><h1>🎨 Styled Render</h1><p>HTML with CSS styling</p></body></html>",
    "options": { "width": 1024, "height": 768, "format": "png" }
  }' | jq '.'
EOF
echo ""

# ============================================
# EXAMPLE 3: Render a Real URL
# ============================================
echo -e "${GREEN}[EXAMPLE 3] Render a Real URL${NC}"
echo ""
echo "curl -X POST http://localhost:3000/render-url \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{
echo '    "url": "https://example.com",'
echo '    "options": {'
echo '      "width": 1920,'
echo '      "height": 1080,'
echo '      "format": "png",'
echo '      "waitFor": 2000'
echo '    }'
echo '  }' | jq '.'
echo ""

# ============================================
# EXAMPLE 4: Render GitHub Profile
# ============================================
echo -e "${GREEN}[EXAMPLE 4] Render GitHub Profile${NC}"
echo ""
echo "curl -X POST http://localhost:3000/render-url \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"url\": \"https://github.com\", \"options\": {\"width\": 1280, \"height\": 720}}' \\"
echo "  | jq '.data.size'"
echo ""

# ============================================
# EXAMPLE 5: Async Render
# ============================================
echo -e "${GREEN}[EXAMPLE 5] Async Render (Queue Job)${NC}"
echo ""
echo "# Step 1: Queue the render job"
echo "JOB_ID=\$(curl -s -X POST http://localhost:3000/render-async \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"html\": \"<h1>Async Job</h1>\"}' | jq '.jobId' -r)"
echo ""
echo "echo \"Job ID: \$JOB_ID\""
echo ""
echo "# Step 2: Check status (repeat until 'completed')"
echo "curl http://localhost:3000/render-async/\$JOB_ID | jq '.status'"
echo ""
echo "# Step 3: Download the image"
echo "curl -o output.png http://localhost:3000/download/\$JOB_ID"
echo ""

# ============================================
# EXAMPLE 6: Save Image to File
# ============================================
echo -e "${GREEN}[EXAMPLE 6] Save Image to File${NC}"
echo ""
echo "# Method 1: Using base64 from response"
echo "curl -s -X POST http://localhost:3000/render \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"html\": \"<h1>Test</h1>\"}' \\"
echo "  | jq '.data.imageBase64' -r | base64 -d > output.png"
echo ""
echo "# Method 2: Using async job download"
echo "JOB_ID=\$(curl -s -X POST http://localhost:3000/render-async \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"html\": \"<h1>Test</h1>\"}' | jq '.jobId' -r)"
echo "sleep 2  # Wait for processing"
echo "curl -o output.png http://localhost:3000/download/\$JOB_ID"
echo ""

# ============================================
# EXAMPLE 7: Custom Viewport Sizes
# ============================================
echo -e "${GREEN}[EXAMPLE 7] Different Viewport Sizes${NC}"
echo ""
echo "# Mobile view (iPhone)"
echo "curl -X POST http://localhost:3000/render \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"html\": \"<h1>Mobile</h1>\", \"options\": {\"width\": 390, \"height\": 844}}' | jq '.data.size'"
echo ""
echo "# Tablet view (iPad)"
echo "curl -X POST http://localhost:3000/render \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"html\": \"<h1>Tablet</h1>\", \"options\": {\"width\": 1024, \"height\": 1366}}' | jq '.data.size'"
echo ""
echo "# Desktop view (4K)"
echo "curl -X POST http://localhost:3000/render \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"html\": \"<h1>4K</h1>\", \"options\": {\"width\": 3840, \"height\": 2160}}' | jq '.data.size'"
echo ""

# ============================================
# EXAMPLE 8: Format Options
# ============================================
echo -e "${GREEN}[EXAMPLE 8] Different Output Formats${NC}"
echo ""
echo "# PNG format (lossless, larger)"
echo "curl -X POST http://localhost:3000/render \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"html\": \"<h1>PNG</h1>\", \"options\": {\"format\": \"png\"}}' | jq '.data | {format, size}'"
echo ""
echo "# JPEG format (lossy, smaller)"
echo "curl -X POST http://localhost:3000/render \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"html\": \"<h1>JPEG</h1>\", \"options\": {\"format\": \"jpeg\"}}' | jq '.data | {format, size}'"
echo ""

# ============================================
# EXAMPLE 9: Health & Status Checks
# ============================================
echo -e "${GREEN}[EXAMPLE 9] Health & Status Checks${NC}"
echo ""
echo "# Quick health check"
echo "curl http://localhost:3000/health | jq '.'"
echo ""
echo "# Full service status"
echo "curl http://localhost:3000/status | jq '.'"
echo ""

# ============================================
# EXAMPLE 10: Error Handling
# ============================================
echo -e "${GREEN}[EXAMPLE 10] Error Handling${NC}"
echo ""
echo "# Missing HTML (400 error)"
echo "curl -X POST http://localhost:3000/render \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{}' | jq '.'"
echo ""
echo "# Invalid URL (error in response)"
echo "curl -X POST http://localhost:3000/render-url \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"url\": \"https://invalid-domain-12345.com\"}' | jq '.'"
echo ""

# ============================================
# EXAMPLE 11: Batch Processing
# ============================================
echo -e "${GREEN}[EXAMPLE 11] Batch Processing${NC}"
echo ""
echo "# Queue multiple renders"
echo "for i in {1..5}; do"
echo "  JOB_ID=\$(curl -s -X POST http://localhost:3000/render-async \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d \"{\\\"html\\\": \\\"<h1>Job \$i</h1>\\\"}\" \\"
echo "    | jq '.jobId' -r)"
echo "  echo \"Queued job \$i: \$JOB_ID\""
echo "done"
echo ""

# ============================================
# EXAMPLE 12: Complex HTML with JavaScript
# ============================================
echo -e "${GREEN}[EXAMPLE 12] Complex HTML with JavaScript${NC}"
echo ""
cat << 'EOF'
HTML='<html>
<head>
<style>
body { background: #2c3e50; color: #ecf0f1; padding: 40px; text-align: center; font-family: Arial; }
#counter { font-size: 48px; color: #3498db; }
.box { background: #34495e; padding: 20px; border-radius: 10px; margin: 20px 0; }
</style>
</head>
<body>
<h1>Dynamic Counter</h1>
<div class="box">
<p id="counter">0</p>
</div>
<script>
let count = 0;
for(let i = 0; i < 50; i++) { count++; }
document.getElementById("counter").textContent = count;
</script>
</body>
</html>'

curl -X POST http://localhost:3000/render \
  -H 'Content-Type: application/json' \
  -d "{\"html\": $(echo $HTML | jq -R .)}" | jq '.data | {format, size}'
EOF
echo ""

# ============================================
# QUICK TEST SCRIPT
# ============================================
echo -e "${GREEN}[QUICK TEST]${NC}"
echo ""
echo "Run all 12 examples with:"
echo "source curl-examples.sh | bash"
echo ""
