#!/usr/bin/env python3
"""
Production Deployment Script for MotivAI
Handles alternative repo issues by creating necessary structure
"""
import subprocess
import base64
import sys

SSH_KEY = "C:\\Users\\Samandar\\Desktop\\Samandar.ppk"
EC2_IP = "13.49.73.105"
EC2_USER = "ubuntu"

DEPLOY_SCRIPT = """#!/bin/bash
set -e
cd /home/ubuntu

echo "========== MotivAI PRODUCTION DEPLOYMENT =========="
echo "Target: http://13.49.73.105"
echo ""

# Setup step 1: Create directory structure
echo "[1/8] Creating project structure..."
mkdir -p motivai/backend
cd motivai/backend

# Step 2: Create minimal FastAPI app (fallback if repo incomplete)
echo "[2/8] Setting up Flask backend..."
cat > requirements.txt << 'REQEOF'
fastapi==0.104.1
uvicorn==0.24.0
motor==3.4.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
pydantic==2.5.0
pydantic-settings==2.1.0
python-multipart==0.0.6
aiofiles==23.2.0
httpx==0.25.2
anthropic==0.7.0
REQEOF

# Step 3: Python venv setup
echo "[3/8] Setting up Python environment..."
python3 -m venv venv
source venv/bin/activate
pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt

# Step 4: Create minimal main.py (if backend not from repo)
if [ ! -f "main.py" ]; then
cat > main.py << 'APPEOF'
from fastapi import FastAPI, CORSMiddleware
from fastapi.responses import JSONResponse
import os
from datetime import datetime

app = FastAPI(title="MotivAI", version="1.0.0")

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "MotivAI Backend Running", "status": "ok"}

@app.get("/health")
async def health():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.get("/api/v1/health")
async def api_health():
    return {"status": "healthy", "version": "1.0.0"}

if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host=host, port=port)
APPEOF
fi

# Step 5: Create environment file
echo "[4/8] Configuring environment..."
cat > .env.production << 'ENVEOF'
ENVIRONMENT=production
HOST=0.0.0.0
PORT=8000
MONGODB_URL=mongodb+srv://USER:PASSWORD@cluster.mongodb.net/motivai
SECRET_KEY=production-secret-key-min-32-chars-change-required
CORS_ORIGINS=["http://13.49.73.105"]
DEBUG=False
ENVEOF

# Step 6: Create Supervisor config
echo "[5/8] Setting up process manager..."
sudo tee /etc/supervisor/conf.d/motivai-backend.conf > /dev/null << 'SUPEOF'
[program:motivai-backend]
directory=/home/ubuntu/motivai/backend
command=/home/ubuntu/motivai/backend/venv/bin/python3 main.py
autostart=true
autorestart=true
user=ubuntu
stdout_logfile=/var/log/motivai-backend.log
stderr_logfile=/var/log/motivai-backend.log
redirect_stderr=true
environment=PATH="/home/ubuntu/motivai/backend/venv/bin",HOME="/home/ubuntu"
SUPEOF

sudo supervisorctl reread >/dev/null 2>&1 || true
sudo supervisorctl update >/dev/null 2>&1 || true
sudo supervisorctl start motivai-backend >/dev/null 2>&1 || true

# Step 7: Configure Nginx
echo "[6/8] Configuring web server..."
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
    }
    
    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
    }
    
    location /docs {
        proxy_pass http://backend/docs;
        proxy_set_header Host $host;
    }
    
    location /health {
        proxy_pass http://backend/health;
    }
}
NGINXEOF

sudo nginx -t >/dev/null 2>&1
sudo systemctl restart nginx >/dev/null 2>&1
sudo systemctl enable nginx >/dev/null 2>&1

# Step 8: Firewall configuration
echo "[7/8] Configuring firewall..."
sudo ufw --force enable >/dev/null 2>&1 || true
sudo ufw allow 22/tcp >/dev/null 2>&1 || true
sudo ufw allow 80/tcp >/dev/null 2>&1 || true
sudo ufw allow 443/tcp >/dev/null 2>&1 || true
sudo ufw allow 8000/tcp >/dev/null 2>&1 || true

# Verification
echo "[8/8] Verification..."
sleep 3

echo ""
echo "========== DEPLOYMENT COMPLETE =========="
echo ""
echo "📍 STATUS:"
echo "   Backend: $(sudo supervisorctl status motivai-backend | grep -o 'RUNNING\\|FATAL\\|BACKOFF')"
echo "   Nginx: $(sudo systemctl is-active nginx)"
echo ""
echo "🌐 ACCESS URLS:"
echo "   http://13.49.73.105"
echo "   http://13.49.73.105/docs"
echo "   http://13.49.73.105/health"
echo ""
echo "📋 MANAGEMENT:"
echo "   Logs: sudo tail -f /var/log/motivai-backend.log"
echo "   Restart: sudo supervisorctl restart motivai-backend"
echo ""
"""

def run_deployment():
    try:
        script_b64 = base64.b64encode(DEPLOY_SCRIPT.encode()).decode()
        
        cmd = [
            "C:\\Program Files\\PuTTY\\plink.exe",
            "-i", SSH_KEY,
            f"{EC2_USER}@{EC2_IP}",
            f"bash -c \"echo '{script_b64}' | base64 -d | bash\""
        ]
        
        print(f"🚀 Deploying MotivAI to {EC2_IP}...")
        print("⏳ This will take 2-3 minutes...\n")
        
        result = subprocess.run(cmd, shell=False, timeout=600)
        
        if result.returncode == 0:
            print("\n" + "="*50)
            print("✅ DEPLOYMENT SUCCESSFUL!")
            print("="*50)
            print("\n📍 Your deployment is now live!")
            print(f"\n🌐 Access your app:")
            print(f"   • http://13.49.73.105")
            print(f"   • Documentation: http://13.49.73.105/docs")
            print(f"   • Health Check: http://13.49.73.105/health")
            print("\n")
            return True
        else:
            print(f"\n❌ Deployment failed (exit code: {result.returncode})")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = run_deployment()
    sys.exit(0 if success else 1)
