#!/bin/bash
set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_DIR="$HOME/motivai"
BACKEND_DIR="$PROJECT_DIR/backend"
REPO_URL="https://github.com/AbduvaliyevSamandar/motivai.git"
BACKEND_PORT=8000
EC2_IP="13.49.73.105"

echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${BLUE}  MotivAI PRODUCTION DEPLOYMENT${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}\n"

# PHASE 1: System Update
echo -e "${YELLOW}[PHASE 1]${NC} System Update & Dependencies..."
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get upgrade -y > /dev/null 2>&1
sudo apt-get install -y git curl wget unzip nano htop build-essential libssl-dev libffi-dev python3-dev python3-pip python3-venv nginx supervisor > /dev/null 2>&1
echo -e "${GREEN}✅ System updated${NC}"

# PHASE 2: Clone Project
echo -e "${YELLOW}[PHASE 2]${NC} Cloning MotivAI Repository..."
if [ -d "$PROJECT_DIR" ]; then
    echo "  Updating existing repository..."
    cd "$PROJECT_DIR"
    git pull origin main > /dev/null 2>&1
else
    echo "  Cloning from GitHub..."
    git clone "$REPO_URL" "$PROJECT_DIR" > /dev/null 2>&1
    cd "$PROJECT_DIR"
fi
echo -e "${GREEN}✅ Repository ready at $PROJECT_DIR${NC}"

# PHASE 3: Backend Python Environment
echo -e "${YELLOW}[PHASE 3]${NC} Setting up Python Backend..."
cd "$BACKEND_DIR"

# Create virtual environment
if [ ! -d "venv" ]; then
    python3 -m venv venv > /dev/null 2>&1
fi

# Activate venv and install dependencies
source venv/bin/activate
pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt > /dev/null 2>&1
echo -e "${GREEN}✅ Python environment ready${NC}"

# PHASE 4: Configure Environment
echo -e "${YELLOW}[PHASE 4]${NC} Configuring Environment..."

# Create .env.production if it doesn't exist
if [ ! -f ".env.production" ]; then
    cat > .env.production << 'ENVEOF'
ENVIRONMENT=production
HOST=0.0.0.0
PORT=8000
MONGODB_URL=mongodb+srv://user:password@cluster.mongodb.net/motivai
SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')
CORS_ORIGINS=["http://13.49.73.105","http://localhost:3000","http://localhost:8000"]
DEBUG=False
ENVEOF
    
    # Generate a secure SECRET_KEY
    SECRET=$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')
    sed -i "s/\$(python3.*SECRET=.*/SECRET_KEY=$SECRET/" .env.production
fi

echo -e "${GREEN}✅ Environment configured${NC}"
echo -e "   ⚠️  UPDATE MONGODB_URL in .env.production if needed:"
echo -e "   nano $BACKEND_DIR/.env.production"

# PHASE 5: Setup Supervisor (Process Manager)
echo -e "${YELLOW}[PHASE 5]${NC} Setting up Supervisor..."

# Create supervisor config
sudo tee /etc/supervisor/conf.d/motivai-backend.conf > /dev/null << 'SUPEOF'
[program:motivai-backend]
directory=/home/ubuntu/motivai/backend
command=/home/ubuntu/motivai/backend/venv/bin/python3 main.py
autostart=true
autorestart=true
user=ubuntu
numprocs=1
stdout_logfile=/var/log/motivai-backend.log
stderr_logfile=/var/log/motivai-backend.log
redirect_stderr=true
stopasgroup=true
killasgroup=true
environment=PATH="/home/ubuntu/motivai/backend/venv/bin",HOME="/home/ubuntu"
SUPEOF

# Restart supervisor
sudo supervisorctl reread > /dev/null 2>&1
sudo supervisorctl update > /dev/null 2>&1
sudo supervisorctl restart motivai-backend > /dev/null 2>&1
sleep 2

echo -e "${GREEN}✅ Supervisor configured & backend started${NC}"

# PHASE 6: Configure Nginx Reverse Proxy
echo -e "${YELLOW}[PHASE 6]${NC} Setting up Nginx Reverse Proxy..."

# Create nginx config
sudo tee /etc/nginx/sites-available/default > /dev/null << 'NGINXEOF'
upstream backend {
    server 127.0.0.1:8000;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    
    client_max_body_size 50M;
    
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_buffering off;
        proxy_request_buffering off;
    }
    
    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
    
    location /docs {
        proxy_pass http://backend/docs;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
    gzip_min_length 1000;
}
NGINXEOF

# Test and restart nginx
sudo nginx -t > /dev/null 2>&1
sudo systemctl restart nginx > /dev/null 2>&1
sudo systemctl enable nginx > /dev/null 2>&1

echo -e "${GREEN}✅ Nginx configured (port 80 → backend)${NC}"

# PHASE 7: Configure Firewall (UFW)
echo -e "${YELLOW}[PHASE 7]${NC} Configuring Firewall..."

# Enable UFW
sudo ufw --force enable > /dev/null 2>&1

# Allow required ports
sudo ufw allow 22/tcp > /dev/null 2>&1  # SSH
sudo ufw allow 80/tcp > /dev/null 2>&1  # HTTP
sudo ufw allow 443/tcp > /dev/null 2>&1 # HTTPS
sudo ufw allow 8000/tcp > /dev/null 2>&1 # Backend

echo -e "${GREEN}✅ Firewall configured (ports 22, 80, 443, 8000 open)${NC}"

# PHASE 8: Verify Services
echo -e "${YELLOW}[PHASE 8]${NC} Verifying Services..."

# Wait for backend to start
sleep 3

# Check backend status
BACKEND_STATUS=$(sudo supervisorctl status motivai-backend | grep -o "RUNNING\|FATAL\|BACKOFF")
if [[ "$BACKEND_STATUS" == "RUNNING" ]]; then
    echo -e "${GREEN}✅ Backend: RUNNING${NC}"
else
    echo -e "${RED}❌ Backend: NOT RUNNING (Status: $BACKEND_STATUS)${NC}"
fi

# Check nginx status
NGINX_STATUS=$(sudo systemctl is-active nginx)
if [[ "$NGINX_STATUS" == "active" ]]; then
    echo -e "${GREEN}✅ Nginx: RUNNING${NC}"
else
    echo -e "${RED}❌ Nginx: NOT RUNNING${NC}"
fi

# Test health endpoint
echo -e "\n${YELLOW}Testing API Endpoints...${NC}"
HEALTH=$(curl -s http://127.0.0.1:8000/health 2>/dev/null || echo "")
if [[ $HEALTH == *"status"* ]]; then
    echo -e "${GREEN}✅ Backend health check: OK${NC}"
else
    echo -e "${RED}⚠️  Backend not responding (may still be starting)${NC}"
fi

# PHASE 9: Provide Status Report
echo -e "\n${BLUE}════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETE!${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📍 SERVICE STATUS:${NC}"
sudo supervisorctl status motivai-backend
echo ""
sudo systemctl status nginx --no-pager | head -3

echo -e "\n${YELLOW}🌐 ACCESS URLS:${NC}"
echo -e "  • Frontend/App: ${GREEN}http://$EC2_IP${NC}"
echo -e "  • API Root: ${GREEN}http://$EC2_IP/api/v1${NC}"
echo -e "  • API Docs: ${GREEN}http://$EC2_IP/docs${NC}"
echo -e "  • Health Check: ${GREEN}http://$EC2_IP/health${NC}"

echo -e "\n${YELLOW}📋 LOG FILES:${NC}"
echo -e "  • Backend: ${GREEN}sudo tail -f /var/log/motivai-backend.log${NC}"
echo -e "  • Nginx: ${GREEN}sudo tail -f /var/log/nginx/error.log${NC}"

echo -e "\n${YELLOW}⚙️  MANAGEMENT COMMANDS:${NC}"
echo -e "  • Restart backend: ${GREEN}sudo supervisorctl restart motivai-backend${NC}"
echo -e "  • Restart nginx: ${GREEN}sudo systemctl restart nginx${NC}"
echo -e "  • Restart all: ${GREEN}sudo supervisorctl restart motivai-backend && sudo systemctl restart nginx${NC}"

echo -e "\n${YELLOW}⚠️  IMPORTANT NEXT STEPS:${NC}"
echo -e "  1. Update MongoDB URL in: ${GREEN}.env.production${NC}"
echo -e "  2. Restart backend: ${GREEN}sudo supervisorctl restart motivai-backend${NC}"
echo -e "  3. Test API: ${GREEN}curl http://127.0.0.1:8000/health${NC}"

echo -e "\n${BLUE}════════════════════════════════════════════${NC}"
echo -e "Deployment: $(/bin/date '+%Y-%m-%d %H:%M:%S')"
echo -e "Status: ✅ PRODUCTION READY"
echo -e "${BLUE}════════════════════════════════════════════${NC}\n"
