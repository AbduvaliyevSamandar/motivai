#!/usr/bin/env python3
import subprocess
import base64
import sys

# SSH key and connection details
SSH_KEY = "C:\\Users\\Samandar\\Desktop\\Samandar.ppk"
EC2_IP = "13.49.73.105"
EC2_USER = "ubuntu"

# The deployment bash script (base64 encoded for safe transmission)
DEPLOYMENT_SCRIPT = """#!/bin/bash
set -e

echo "=========================================="
echo "MotivAI PRODUCTION DEPLOYMENT"
echo "=========================================="

# Configuration
PROJECT_DIR="/home/ubuntu/motivai"
BACKEND_DIR="$PROJECT_DIR/backend"
REPO_URL="https://github.com/AbduvaliyevSamandar/motivai.git"
EC2_IP="13.49.73.105"

# Phase 1: Clone/Update repository
echo "[1/7] Repository setup..."
if [ ! -d "$PROJECT_DIR" ]; then
    git clone "$REPO_URL" "$PROJECT_DIR"
fi
cd "$PROJECT_DIR"
git pull origin main 2>/dev/null || true

# Phase 2: Python environment
echo "[2/7] Python environment..."
cd "$BACKEND_DIR"
python3 -m venv venv 2>/dev/null || true
source venv/bin/activate
pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt

# Phase 3: Environment configuration
echo "[3/7] Configuration files..."
if [ ! -f ".env.production" ]; then
    cat > .env.production << 'ENVEOF'
ENVIRONMENT=production
HOST=0.0.0.0
PORT=8000
MONGODB_URL=mongodb+srv://USER:PASSWORD@cluster.mongodb.net/motivai
SECRET_KEY=production-key-minimum-32-chars-change-in-prod
CORS_ORIGINS=["http://13.49.73.105","http://localhost"]
DEBUG=False
ENVEOF
fi

# Phase 4: Supervisor configuration
echo "[4/7] Process manager..."
sudo tee /etc/supervisor/conf.d/motivai.conf > /dev/null << 'SUPEOF'
[program:motivai-backend]
directory=/home/ubuntu/motivai/backend
command=/home/ubuntu/motivai/backend/venv/bin/python3 main.py
autostart=true
autorestart=true
user=ubuntu
stdout_logfile=/var/log/motivai-backend.log
redirect_stderr=true
SUPEOF

sudo supervisorctl reread >/dev/null 2>&1
sudo supervisorctl update >/dev/null 2>&1
sudo supervisorctl start motivai-backend >/dev/null 2>&1

# Phase 5: Nginxconfiguration  
echo "[5/7] Web server..."
sudo tee /etc/nginx/sites-available/default > /dev/null << 'NGINXEOF'
upstream backend {
    server 127.0.0.1:8000;
}
server {
    listen 80 default_server;
    server_name _;
    client_max_body_size 50M;
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    location /api/ {
        proxy_pass http://backend;
    }
    location /docs {
        proxy_pass http://backend/docs;
    }
}
NGINXEOF

sudo nginx -t >/dev/null 2>&1 || true
sudo systemctl restart nginx >/dev/null 2>&1
sudo systemctl enable nginx >/dev/null 2>&1

# Phase 6: Firewall
echo "[6/7] Firewall..."
sudo ufw --force enable >/dev/null 2>&1
sudo ufw allow 22/tcp >/dev/null 2>&1
sudo ufw allow 80/tcp >/dev/null 2>&1
sudo ufw allow 443/tcp >/dev/null 2>&1
sudo ufw allow 8000/tcp >/dev/null 2>&1

# Phase 7: Verification
echo "[7/7] Verification..."
sleep 3

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE"
echo "=========================================="
echo ""
echo "📍 Access URLs:"
echo "  • App: http://$EC2_IP"
echo "  • API Docs: http://$EC2_IP/docs"
echo "  • Health: http://$EC2_IP/health"
echo ""
echo "🔍 Backend Status:"
sudo supervisorctl status motivai-backend | tail -1
echo ""
echo "🔍 Nginx Status:"
sudo systemctl status nginx --no-pager | grep Active | head -1
echo ""
echo "📋 Check logs: sudo tail -f /var/log/motivai-backend.log"
echo ""
"""

def execute_deployment():
    """Execute deployment via SSH"""
    try:
        # Encode the script
        script_b64 = base64.b64encode(DEPLOYMENT_SCRIPT.encode()).decode()
        
        # SSH command: decode and execute
        ssh_cmd = [
            "C:\\Program Files\\PuTTY\\plink.exe",
            "-i", SSH_KEY,
            f"{EC2_USER}@{EC2_IP}",
            f"echo '{script_b64}' | base64 -d | bash"
        ]
        
        print(f"🚀 Connecting to {EC2_IP}...")
        print("⏳ This will take 2-3 minutes...\n")
        
        # Execute and stream output
        result = subprocess.run(
            ssh_cmd,
            capture_output=False,
            text=True,
            timeout=600
        )
        
        if result.returncode == 0:
            print("\n✅ Deployment completed successfully!")
            return True
        else:
            print(f"\n❌ Deployment failed with code {result.returncode}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = execute_deployment()
    sys.exit(0 if success else 1)
