#!/bin/bash

# 🎨 Playwright Renderer - API Test Suite

BASE_URL="http://localhost:3000"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Playwright Renderer API Test Suite    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Test 1: Health Check
echo -e "${YELLOW}[TEST 1] Health Check${NC}"
response=$(curl -s -w "\n%{http_code}" "$BASE_URL/health")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Status: $http_code"
    echo -e "  Response: $body"
else
    echo -e "${RED}✗ FAIL${NC} - Status: $http_code"
fi
echo ""

# Test 2: Service Status
echo -e "${YELLOW}[TEST 2] Service Status${NC}"
response=$(curl -s -w "\n%{http_code}" "$BASE_URL/status")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Status: $http_code"
    echo -e "  Response: $body"
else
    echo -e "${RED}✗ FAIL${NC} - Status: $http_code"
fi
echo ""

# Test 3: Render Simple HTML
echo -e "${YELLOW}[TEST 3] Render Simple HTML${NC}"
html_payload='{
  "html": "<html><body style=\"background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px; text-align: center;\"><h1>Test Render</h1><p>HTML to Image Conversion Works!</p></body></html>",
  "options": {
    "width": 800,
    "height": 600,
    "format": "png",
    "waitFor": 500
  }
}'

response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/render" \
  -H "Content-Type: application/json" \
  -d "$html_payload")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ]; then
    size=$(echo "$body" | grep -o '"size":[0-9]*' | cut -d: -f2)
    echo -e "${GREEN}✓ PASS${NC} - Status: $http_code"
    echo -e "  Image size: $size bytes"
    echo -e "  Image (first 100 chars): $(echo "$body" | grep -o '"imageBase64":"[^"]*' | cut -c1-150)..."
else
    echo -e "${RED}✗ FAIL${NC} - Status: $http_code"
    echo -e "  Response: $body"
fi
echo ""

# Test 4: Render URL
echo -e "${YELLOW}[TEST 4] Render URL${NC}"
url_payload='{
  "url": "https://example.com",
  "options": {
    "width": 1024,
    "height": 768,
    "format": "png",
    "waitFor": 2000
  }
}'

response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/render-url" \
  -H "Content-Type: application/json" \
  -d "$url_payload")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ]; then
    size=$(echo "$body" | grep -o '"size":[0-9]*' | cut -d: -f2)
    echo -e "${GREEN}✓ PASS${NC} - Status: $http_code"
    echo -e "  Image size: $size bytes"
else
    echo -e "${RED}✗ FAIL${NC} - Status: $http_code"
    echo -e "  Response: $body"
fi
echo ""

# Test 5: Async Render
echo -e "${YELLOW}[TEST 5] Async Render${NC}"
async_payload='{
  "html": "<html><body style=\"background: #2c3e50; color: #ecf0f1; padding: 40px; text-align: center;\"><h1>Async Job</h1><p>This was queued asynchronously!</p></body></html>",
  "options": {
    "width": 800,
    "height": 600,
    "format": "png"
  }
}'

response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/render-async" \
  -H "Content-Type: application/json" \
  -d "$async_payload")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ]; then
    job_id=$(echo "$body" | grep -o '"jobId":"[^"]*' | cut -d'"' -f4)
    echo -e "${GREEN}✓ PASS${NC} - Status: $http_code"
    echo -e "  Job ID: $job_id"
    echo -e "  Response: $body"
    
    # Test 6: Check Job Status
    echo ""
    echo -e "${YELLOW}[TEST 6] Check Async Job Status${NC}"
    
    for i in {1..10}; do
        sleep 1
        response=$(curl -s -w "\n%{http_code}" "$BASE_URL/render-async/$job_id")
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | head -n-1)
        
        status=$(echo "$body" | grep -o '"status":"[^"]*' | cut -d'"' -f4)
        echo -e "  Attempt $i - Status: $status"
        
        if [ "$status" = "completed" ]; then
            echo -e "${GREEN}✓ PASS${NC} - Job completed"
            size=$(echo "$body" | grep -o '"size":[0-9]*' | cut -d: -f2)
            echo -e "  Image size: $size bytes"
            break
        elif [ "$status" = "failed" ]; then
            echo -e "${RED}✗ FAIL${NC} - Job failed"
            error=$(echo "$body" | grep -o '"error":"[^"]*' | cut -d'"' -f4)
            echo -e "  Error: $error"
            break
        fi
    done
else
    echo -e "${RED}✗ FAIL${NC} - Status: $http_code"
    echo -e "  Response: $body"
fi
echo ""

# Test 7: Invalid HTML
echo -e "${YELLOW}[TEST 7] Invalid Request (Missing HTML)${NC}"
invalid_payload='{"options": {"width": 800}}'

response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/render" \
  -H "Content-Type: application/json" \
  -d "$invalid_payload")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "400" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Correctly rejected - Status: $http_code"
    echo -e "  Response: $body"
else
    echo -e "${RED}✗ FAIL${NC} - Should return 400, got $http_code"
fi
echo ""

# Summary
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Test Suite Completed                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo "📊 All endpoints tested!"
echo ""
