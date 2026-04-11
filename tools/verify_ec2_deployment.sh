#!/bin/bash
# MotivAI AWS EC2 Deployment Verification Script
# Run this on your EC2 instance to verify everything is working

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     MotivAI AWS EC2 Deployment Verification Script         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0

# Test function
test_command() {
    local test_name=$1
    local command=$2
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} $test_name"
        ((PASSED++))
    else
        echo -e "${RED}❌${NC} $test_name"
        ((FAILED++))
    fi
}

echo "1️⃣  SYSTEM DEPENDENCIES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━="
test_command "Node.js installed" "node --version"
test_command "npm installed" "npm --version"
test_command "Python3 installed" "python3 --version"
test_command "Git installed" "git --version"
test_command "Nginx installed" "nginx -v 2>/dev/null"
test_command "PM2 installed" "pm2 --version"

echo ""
echo "2️⃣  PROCESS MANAGERS & SERVICES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━="
test_command "Nginx running" "sudo systemctl is-active --quiet nginx"
test_command "PM2 backend running" "pm2 status | grep -q 'motivai-backend' && pm2 status | grep 'motivai-backend' | grep -q 'online'"

echo ""
echo "3️⃣  PROJECT STRUCTURE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━="
test_command "Project directory exists" "[ -d ~/projects/motivai ]"
test_command "Backend exists" "[ -d ~/projects/motivai/backend ]"
test_command "Frontend exists" "[ -d ~/projects/motivai/mobile_app ]"
test_command "Frontend build exists" "[ -d ~/projects/motivai/mobile_app/build/web ]"
test_command ".env.production exists" "[ -f ~/projects/motivai/backend/.env.production ]"

echo ""
echo "4️⃣  FRONTEND (NGINX + FLUTTER WEB)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━="
test_command "Frontend files in Nginx dir" "[ -f /var/www/motivai/index.html ]"
test_command "Nginx can access frontend" "sudo test -r /var/www/motivai/index.html"

# Test HTTP response
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅${NC} Frontend responds (HTTP $HTTP_CODE)"
    ((PASSED++))
else
    echo -e "${RED}❌${NC} Frontend not responding properly (HTTP $HTTP_CODE)"
    ((FAILED++))
fi

echo ""
echo "5️⃣  BACKEND (FASTAPI + PM2)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━="

# Check PM2 logs for errors
if pm2 logs motivai-backend 2>/dev/null | grep -q "ERROR\|error"; then
    echo -e "${YELLOW}⚠️${NC} Backend has errors in logs"
else
    echo -e "${GREEN}✅${NC} No errors in backend logs"
    ((PASSED++))
fi

# Test backend health
HEALTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null)
if [ "$HEALTH_CODE" = "200" ]; then
    echo -e "${GREEN}✅${NC} Backend health check (HTTP $HEALTH_CODE)"
    ((PASSED++))
else
    echo -e "${RED}❌${NC} Backend health check failed (HTTP $HEALTH_CODE)"
    ((FAILED++))
fi

# Test backend API
API_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/v1/health 2>/dev/null)
if [ "$API_CODE" = "200" ]; then
    echo -e "${GREEN}✅${NC} API endpoint responsive (HTTP $API_CODE)"
    ((PASSED++))
else
    echo -e "${RED}❌${NC} API endpoint not responding (HTTP $API_CODE)"
    ((FAILED++))
fi

echo ""
echo "6️⃣  NGINX REVERSE PROXY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━="

# Test frontend via Nginx
PROXY_FRONTEND=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null)
if [ "$PROXY_FRONTEND" = "200" ]; then
    echo -e "${GREEN}✅${NC} Nginx → Frontend proxy (HTTP $PROXY_FRONTEND)"
    ((PASSED++))
else
    echo -e "${RED}❌${NC} Nginx → Frontend proxy failed (HTTP $PROXY_FRONTEND)"
    ((FAILED++))
fi

# Test API via Nginx
PROXY_API=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/v1/health 2>/dev/null)
if [ "$PROXY_API" = "200" ]; then
    echo -e "${GREEN}✅${NC} Nginx → Backend API proxy (HTTP $PROXY_API)"
    ((PASSED++))
else
    echo -e "${RED}❌${NC} Nginx → Backend API proxy failed (HTTP $PROXY_API)"
    ((FAILED++))
fi

# Test docs via Nginx
PROXY_DOCS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/docs 2>/dev/null)
if [ "$PROXY_DOCS" = "200" ]; then
    echo -e "${GREEN}✅${NC} Nginx → API docs proxy (HTTP $PROXY_DOCS)"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠️${NC} Nginx → API docs proxy (HTTP $PROXY_DOCS)"
fi

echo ""
echo "7️⃣  CORS CONFIGURATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━="

CORS_HEADERS=$(curl -s -X OPTIONS -H "Origin: http://localhost" http://localhost:8000/api/v1/health 2>/dev/null | grep -i "access-control")
if [ -n "$CORS_HEADERS" ]; then
    echo -e "${GREEN}✅${NC} CORS headers present"
    echo "   $CORS_HEADERS"
    ((PASSED++))
else
    echo -e "${RED}❌${NC} CORS headers missing"
    ((FAILED++))
fi

echo ""
echo "8️⃣  MONGODB CONNECTION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━="

# Check if .env has MongoDB URL
if grep -q "MONGODB_URL" ~/projects/motivai/backend/.env.production 2>/dev/null; then
    echo -e "${GREEN}✅${NC} MongoDB URL configured in .env"
    ((PASSED++))
    
    # Extract MongoDB URL (hide password)
    MONGO_URL=$(grep "MONGODB_URL" ~/projects/motivai/backend/.env.production | cut -d'=' -f2 | sed 's/:.*@/@hidden/g')
    echo "   $MONGO_URL"
else
    echo -e "${RED}❌${NC} MongoDB URL not found in .env"
    ((FAILED++))
fi

echo ""
echo "9️⃣  PORT ACCESSIBILITY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━="
test_command "Port 80 open (Nginx)" "sudo netstat -tulpn 2>/dev/null | grep -q ':80' || sudo ss -tulpn 2>/dev/null | grep -q ':80'"
test_command "Port 8000 open (Backend)" "sudo netstat -tulpn 2>/dev/null | grep -q ':8000' || sudo ss -tulpn 2>/dev/null | grep -q ':8000'"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "                    SUMMARY REPORT"
echo "════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ PASSED: $PASSED${NC}"
echo -e "${RED}❌ FAILED: $FAILED${NC}"

TOTAL=$((PASSED + FAILED))
if [ $FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Your deployment is ready!${NC}"
    echo ""
    echo "Access your app at:"
    echo "  Frontend: http://$(hostname -I | awk '{print $1}')/"
    echo "  API Docs: http://$(hostname -I | awk '{print $1}')/docs"
    echo "  API Health: http://$(hostname -I | awk '{print $1}')/api/v1/health"
    echo ""
else
    echo ""
    echo -e "${RED}⚠️  Some tests failed. Review errors above.${NC}"
    echo ""
    echo "Commands to debug:"
    echo "  • View backend logs: pm2 logs motivai-backend"
    echo "  • Check Nginx: sudo systemctl status nginx"
    echo "  • Check processes: pm2 status"
    echo ""
fi

echo ""
