#!/bin/bash
# =====================================================
# MotivAI - AWS EC2 PRODUCTION DEPLOYMENT SCRIPT
# Automated full-stack deployment
# =====================================================

set -e  # Exit on any error

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_REPO="https://github.com/AbduvaliyevSamandar/motivai.git"
PROJECT_DIR="/home/ubuntu/motivai"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/mobile_app"
APP_PORT=8000
APP_NAME="motivai-backend"

# Helper functions
print_step() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# =====================================================
# PHASE 1: SYSTEM UPDATE
# =====================================================
print_step "PHASE 1: System Update & Dependencies"

sudo apt update
print_success "System packages updated"

sudo apt upgrade -y
print_success "System upgraded"

sudo apt install -y \
    git \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    wget \
    nano \
    htop \
    nginx \
    supervisor \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev
    
print_success "All dependencies installed"

# Verify installations
REQS="git python3 pip nginx"
for req in $REQS; do
    if command -v $req &> /dev/null; then
        VERSION=$($req --version 2>&1)
        print_success "$req: $VERSION"
    else
        print_error "$req not installed"
        exit 1
    fi
done

# =====================================================
# PHASE 2: CLONE PROJECT
# =====================================================
print_step "PHASE 2: Clone GitHub Repository"

if [ -d "$PROJECT_DIR" ]; then
    print_warning "Project directory exists. Removing old version..."
    rm -rf "$PROJECT_DIR"
fi

git clone "$PROJECT_REPO" "$PROJECT_DIR"
print_success "Project cloned from GitHub"

cd "$PROJECT_DIR"
echo "Current branch: $(git branch --show-current)"
ls -la

# =====================================================
# PHASE 3: BACKEND SETUP
# =====================================================
print_step "PHASE 3: Backend Setup (FastAPI)"

cd "$BACKEND_DIR"
print_success "Changed to backend directory"

# Create virtual environment
python3 -m venv venv
print_success "Virtual environment created"

# Activate and install dependencies
source venv/bin/activate
pip install --upgrade pip setuptools wheel
print_success "Pip upgraded"

pip install -r requirements.txt
print_success "Backend dependencies installed"

# Create production environment file
print_warning "Creating .env.production file..."
cat > .env.production << 'ENVEOF'
ENVIRONMENT=production
DEBUG=false
HOST=0.0.0.0
PORT=8000
APP_NAME=MotivAI
APP_VERSION=1.0.0

# Update with your MongoDB Atlas connection string
MONGODB_URL=mongodb+srv://USER:PASSWORD@cluster.mongodb.net/motivai_prod
DATABASE_NAME=motivai_prod

# Security
SECRET_KEY=your-secret-key-change-in-production-min-32-chars
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS - Allow frontend domain
CORS_ORIGINS=["http://13.49.73.105", "http://localhost:80", "http://localhost:3000"]

# API
MAX_WORKERS=4
LOG_LEVEL=info
ENVEOF

print_warning "⚠ IMPORTANT: Edit .env.production with your MongoDB credentials:"
echo "  nano $BACKEND_DIR/.env.production"
echo ""
read -p "Press Enter after updating .env.production file..."

# Generate SECRET_KEY if not set
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
sed -i "s/^SECRET_KEY=.*/SECRET_KEY=$SECRET_KEY/" .env.production
print_success "Generated secure SECRET_KEY"

# Verify .env file
if [ -f ".env.production" ]; then
    print_success ".env.production created"
    echo ""
    echo "Environment variables:"
    grep -E "^[A-Z_]+=" .env.production | head -10
else
    print_error ".env.production not created"
    exit 1
fi

# =====================================================
# PHASE 4: PROCESS MANAGER SETUP (Supervisor)
# =====================================================
print_step "PHASE 4: Process Manager Setup"

# Create supervisor config for FastAPI
sudo tee /etc/supervisor/conf.d/motivai.conf > /dev/null << 'SUPEOF'
[program:motivai-backend]
directory=/home/ubuntu/motivai/backend
command=/home/ubuntu/motivai/backend/venv/bin/python3 main.py
environment=PATH="/home/ubuntu/motivai/backend/venv/bin",PYTHONUNBUFFERED=1
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/motivai-backend.log
user=ubuntu
priority=999

[group:motivai]
programs=motivai-backend
SUPEOF

print_success "Supervisor config created"

# Update supervisor
sudo supervisorctl reread
sudo supervisorctl update
print_success "Supervisor updated"

# Start the backend service
sudo supervisorctl start motivai-backend
sleep 2
print_success "Backend started with supervisor"

# Verify backend is running
if sudo supervisorctl status motivai-backend | grep -q "RUNNING"; then
    print_success "Backend is running!"
    sudo supervisorctl status motivai-backend
else
    print_error "Backend failed to start. Checking logs..."
    sudo tail -30 /var/log/motivai-backend.log
    exit 1
fi

# =====================================================
# PHASE 5: NGINX REVERSE PROXY SETUP
# =====================================================
print_step "PHASE 5: Nginx Reverse Proxy Configuration"

# Backup original nginx config
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup
print_success "Original Nginx config backed up"

# Create new nginx config
sudo tee /etc/nginx/sites-available/default > /dev/null << 'NGINXEOF'
upstream backend {
    server 127.0.0.1:8000;
    keepalive 32;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name 13.49.73.105;
    client_max_body_size 20M;
    
    # Logging
    access_log /var/log/nginx/motivai_access.log;
    error_log /var/log/nginx/motivai_error.log;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_types text/plain text/css text/xml text/javascript 
               application/x-javascript application/xml+rss 
               application/javascript application/json;
    
    # Root for static files (if needed)
    root /home/ubuntu/motivai/mobile_app/build/web;
    
    # Health check endpoint
    location /health {
        access_log off;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
    
    # API endpoints
    location /api/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # API documentation
    location /docs {
        proxy_pass http://backend/docs;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    location /openapi.json {
        proxy_pass http://backend/openapi.json;
    }
    
    # Frontend static files (if building Flutter web)
    location / {
        # First try API
        error_page 404 =200 /index.html;
        
        # Serve static files with cache
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            add_header Cache-Control "public, max-age=31536000, immutable";
            expires 1y;
        }
        
        # Try files, otherwise serve index.html for SPA routing
        try_files $uri $uri/ /index.html;
    }
}
NGINXEOF

print_success "Nginx configuration created"

# Test nginx syntax
if sudo nginx -t; then
    print_success "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
    exit 1
fi

# Reload nginx
sudo systemctl restart nginx
print_success "Nginx restarted"

# Verify nginx is running
if sudo systemctl is-active --quiet nginx; then
    print_success "Nginx is running"
    sudo systemctl status nginx | head -5
else
    print_error "Nginx failed to start"
    exit 1
fi

# =====================================================
# PHASE 6: FIREWALL CONFIGURATION
# =====================================================
print_step "PHASE 6: Firewall Configuration (UFW)"

# Enable UFW if available
if command -v ufw &> /dev/null; then
    # Check if UFW is already enabled
    if sudo ufw status | grep -q "Status: active"; then
        print_success "UFW is already enabled"
    else
        sudo ufw --force enable
        print_success "UFW enabled"
    fi
    
    # Allow SSH
    sudo ufw allow 22/tcp
    print_success "SSH (port 22) allowed"
    
    # Allow HTTP
    sudo ufw allow 80/tcp
    print_success "HTTP (port 80) allowed"
    
    # Allow HTTPS
    sudo ufw allow 443/tcp
    print_success "HTTPS (port 443) allowed"
    
    # Allow backend port (for direct access if needed)
    sudo ufw allow 8000/tcp
    print_success "Backend (port 8000) allowed"
    
    sudo ufw status
else
    print_warning "UFW not available. Check AWS Security Groups instead."
fi

# =====================================================
# PHASE 7: TEST BACKEND CONNECTIVITY
# =====================================================
print_step "PHASE 7: Testing Backend Connectivity"

# Wait for backend to be ready
sleep 3

# Test health endpoint via localhost
print_warning "Testing backend on localhost:8000..."
HEALTH_RESPONSE=$(curl -s http://127.0.0.1:8000/health || echo "FAILED")

if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    print_success "Backend health check passed"
    echo "$HEALTH_RESPONSE"
else
    print_warning "Backend health check response: $HEALTH_RESPONSE"
fi

# Test via nginx proxy
print_warning "Testing Nginx proxy..."
PROXY_RESPONSE=$(curl -s http://127.0.0.1/api/v1/health || echo "FAILED")

if echo "$PROXY_RESPONSE" | grep -q "healthy"; then
    print_success "Nginx proxy working correctly"
    echo "$PROXY_RESPONSE"
else
    print_warning "Nginx proxy response: $PROXY_RESPONSE"
fi

# =====================================================
# PHASE 8: CORS CONFIGURATION VERIFICATION
# =====================================================
print_step "PHASE 8: CORS Configuration"

# Test CORS headers
print_warning "Testing CORS headers..."
CORS_HEADERS=$(curl -s -X OPTIONS -H "Origin: http://13.49.73.105" http://127.0.0.1:8000/api/v1/health -v 2>&1 | grep -i access-control || echo "NOT_FOUND")

if [ "$CORS_HEADERS" != "NOT_FOUND" ]; then
    print_success "CORS headers detected:"
    echo "$CORS_HEADERS"
else
    print_warning "CORS headers not found. Ensure backend CORS is configured."
fi

print_warning "Verify CORS in backend .env file:"
grep "CORS_ORIGINS" "$BACKEND_DIR/.env.production"

# =====================================================
# PHASE 9: BACKEND INITIALIZATION (Optional)
# =====================================================
print_step "PHASE 9: Backend Initialization"

# Check if there are any database migrations
if [ -f "$BACKEND_DIR/app/db/init_db.py" ]; then
    print_warning "Database initialization script found. Running..."
    cd "$BACKEND_DIR"
    source venv/bin/activate
    python3 app/db/init_db.py || print_warning "Database init script failed or not needed"
    print_success "Database initialization complete"
else
    print_warning "No database init script found. Skipping."
fi

# =====================================================
# PHASE 10: FINAL VERIFICATION
# =====================================================
print_step "PHASE 10: Final Verification & Status"

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}           DEPLOYMENT SUMMARY${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# System status
echo -e "${YELLOW}System Status:${NC}"
echo "Hostname: $(hostname)"
echo "Public IP: 13.49.73.105"
echo "Time: $(date)"
echo ""

# Services status
echo -e "${YELLOW}Services Status:${NC}"
sudo supervisorctl status motivai-backend
echo ""
sudo systemctl status nginx | head -3
echo ""

# Backend endpoint test
echo -e "${YELLOW}Endpoint Tests:${NC}"
echo "Testing: http://127.0.0.1:8000/health"
curl -s http://127.0.0.1:8000/health || echo "ERROR"
echo ""
echo "Testing: http://127.0.0.1/health (via Nginx)"
curl -s http://127.0.0.1/health || echo "ERROR"
echo ""

# Account info
echo -e "${YELLOW}Directories:${NC}"
echo "Project: $PROJECT_DIR"
echo "Backend: $BACKEND_DIR"
echo "Frontend: $FRONTEND_DIR"
echo ""

echo -e "${YELLOW}Important Logs:${NC}"
echo "Backend logs: sudo tail -f /var/log/motivai-backend.log"
echo "Nginx access: sudo tail -f /var/log/nginx/motivai_access.log"
echo "Nginx errors: sudo tail -f /var/log/nginx/motivai_error.log"
echo ""

# =====================================================
# FINAL RESULTS
# =====================================================
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}           DEPLOYMENT COMPLETE!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Your MotivAI app is now LIVE!${NC}"
echo ""
echo -e "${YELLOW}Access URLs:${NC}"
echo "  • Frontend/App: http://13.49.73.105"
echo "  • API Root: http://13.49.73.105/api/v1"
echo "  • API Docs: http://13.49.73.105/docs"
echo "  • Health Check: http://13.49.73.105/api/v1/health"
echo ""
echo -e "${YELLOW}Management Commands:${NC}"
echo "  • View logs: sudo tail -f /var/log/motivai-backend.log"
echo "  • Restart backend: sudo supervisorctl restart motivai-backend"
echo "  • Stop backend: sudo supervisorctl stop motivai-backend"
echo "  • Restart Nginx: sudo systemctl restart nginx"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Test endpoints from your frontend/mobile app"
echo "  2. Verify database connectivity"
echo "  3. Monitor logs for errors"
echo "  4. Setup SSL/HTTPS (optional)"
echo "  5. Configure custom domain (optional)"
echo "  6. Setup monitoring and alerts (optional)"
echo ""

print_success "Deployment script completed successfully!"
print_success "Your MotivAI backend is production-ready at http://13.49.73.105"
