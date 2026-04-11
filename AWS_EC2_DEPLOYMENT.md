# 🚀 AWS EC2 Deployment Guide - MotivAI
## Complete Step-by-Step Tutorial for Ubuntu Server

**Project Details:**
- GitHub Repo: https://github.com/AbduvaliyevSamandar/motivai
- EC2 IP: 13.49.73.105
- Key File: C:\Users\Samandar\Desktop\Samandar.ppk
- MongoDB: MongoDB Atlas (Cloud)
- Frontend: Flutter Web
- Backend: FastAPI (Python)
- Process Manager: PM2
- Web Server: Nginx

---

## ⚠️ IMPORTANT: Convert PPK to PEM First

Your key file is in **PuTTY format (.ppk)**. You need to convert it to **PEM format (.pem)** for SSH.

### Conversion Step:

**Option A: Using PuTTYgen (Easy)**
1. Open PuTTYgen
2. Menu: File → Load Private Key
3. Select your `Samandar.ppk` file
4. Menu: Conversions → Export OpenSSH Key
5. Save as `Samandar.pem`
6. Done! Now use the .pem file with SSH

**Option B: Using WSL/Git Bash**
```bash
puttygen C:\Users\Samandar\Desktop\Samandar.ppk -O private-openssh -o C:\Users\Samandar\Desktop\Samandar.pem
```

**For this guide, assume you have `Samandar.pem` saved.**

---

# PHASE 1: AWS SECURITY GROUP SETUP

## Step 1: Open Required Ports in AWS Security Group

**Why?** Your EC2 instance won't accept connections without opening ports.

### In AWS Console:
1. Go to EC2 Dashboard
2. Click "Security Groups"
3. Find your EC2's security group (usually "default" or "launch-wizard-X")
4. Click on it
5. Tab: "Inbound Rules" → "Edit Inbound Rules"
6. Add these rules:

| Type | Protocol | Port Range | Source | Purpose |
|------|----------|-----------|--------|---------|
| SSH | TCP | 22 | 0.0.0.0/0 | SSH access |
| HTTP | TCP | 80 | 0.0.0.0/0 | Nginx web |
| HTTPS | TCP | 443 | 0.0.0.0/0 | SSL (future) |
| Custom TCP | TCP | 8000 | 0.0.0.0/0 | FastAPI backend |

7. Click "Save rules"

**Verify:** You should see 4 inbound rules now.

---

# PHASE 2: CONNECT TO EC2 INSTANCE

## Step 1: SSH Connection from Windows PowerShell

Open **Windows PowerShell** and run:

```powershell
# Set key file permissions (required first time)
icacls "C:\Users\Samandar\Desktop\Samandar.pem" /inheritance:r /grant:r "$env:USERNAME`:F"

# Connect to EC2
ssh -i "C:\Users\Samandar\Desktop\Samandar.pem" ubuntu@13.49.73.105
```

**Expected Output:**
```
The authenticity of host '13.49.73.105' can't be established.
ECDSA key fingerprint is SHA256:xxxxx...
Are you sure you want to continue connecting (yes/no)? yes
ubuntu@ip-172-31-xx-xx:~$
```

**Type `yes` and press Enter**

✅ **You're now connected to the EC2 instance!**

---

# PHASE 3: SERVER SETUP

## Step 1: Update System Packages

Run these commands on the **EC2 terminal** (not PowerShell):

```bash
sudo apt update
sudo apt upgrade -y
```

**What?** Updates all system packages to latest versions.
**Warning message?** Normal - just wait for completion.

---

## Step 2: Install Required Dependencies

```bash
# Install Node.js and npm (for Flutter web build tools)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Python 3 and pip (for FastAPI backend)
sudo apt install -y python3 python3-pip python3-venv

# Install Git (to clone repository)
sudo apt install -y git

# Install Nginx (for reverse proxy and frontend hosting)
sudo apt install -y nginx

# Install PM2 (process manager for backend)
sudo npm install -g pm2

# Install other utilities
sudo apt install -y curl wget build-essential
```

**Verify each installation:**
```bash
node --version        # Should show v20.x.x
npm --version         # Should show 10.x.x
python3 --version     # Should show 3.10 or higher
git --version         # Should show 2.x.x
nginx -v              # Should show nginx version
pm2 --version         # Should show 5.x.x

# Expected output:
# v20.11.0 (or similar)
# 10.5.0
# Python 3.10.x
# git version 2.x.x
# nginx/1.x.x
# 5.x.x
```

✅ **All dependencies installed!**

---

# PHASE 4: CLONE AND SETUP PROJECT

## Step 1: Clone GitHub Repository

```bash
# Create projects directory
mkdir -p ~/projects
cd ~/projects

# Clone your repo
git clone https://github.com/AbduvaliyevSamandar/motivai.git
cd motivai

# List to verify
ls -la
```

**Expected output:**
```
backend/
mobile_app/
docs/
README.md
docker-compose.yml
... (other files)
```

✅ **Project cloned!**

---

## Step 2: Create MongoDB Atlas Connection String

**Why?** Your PythonFastAPI backend needs to connect to MongoDB.

### On Your Local Machine (NOT EC2):
1. Go to https://www.mongodb.com/cloud/atlas
2. Sign in to your MongoDB Atlas account
3. Create a cluster if you don't have one (free M0 tier)
4. Click "Database" → "Clusters"
5. Click "Connect" button
6. Choose "Drivers"
7. Copy the connection string (looks like):
   ```
   mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/motivai
   ```

### Note down this string - you'll need it next!

---

## Step 3: Create Environment File for Backend

Run this on your **EC2 terminal**:

```bash
# Navigate to backend
cd ~/projects/motivai/backend

# Create production .env file
cat > .env.production << 'EOF'
ENVIRONMENT=production
DEBUG=false
HOST=0.0.0.0
PORT=8000
APP_NAME=MotivAI
APP_VERSION=1.0.0

# MongoDB Atlas Connection (PASTE YOUR CONNECTION STRING)
MONGODB_URL=mongodb+srv://YOUR_USERNAME:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/motivai
DATABASE_NAME=motivai_prod

# Security (generate random string)
SECRET_KEY=your-super-secret-key-min-32-chars-CHANGE-THIS
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# CORS (allow your EC2 IP)
CORS_ORIGINS=["http://13.49.73.105", "http://localhost"]

# API
MAX_WORKERS=4
LOG_LEVEL=info
EOF
```

**IMPORTANT: Replace these values:**
- `YOUR_USERNAME`: Your MongoDB Atlas username
- `YOUR_PASSWORD`: Your MongoDB Atlas password
- `cluster0.xxxxx.mongodb.net`: Your actual MongoDB atlas URL
- Generate a random SECRET_KEY (at least 32 characters)

**To generate SECRET_KEY:**
```bash
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

Verify the file:
```bash
cat .env.production
```

✅ **Environment file created!**

---

# PHASE 5: SETUP BACKEND (FastAPI)

## Step 1: Install Python Dependencies

```bash
# Still in ~/projects/motivai/backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install requirements
pip install -r requirements.txt
```

**This takes 1-2 minutes. Wait for completion.**

**After completion, you should see:**
```
Successfully installed fastapi uvicorn motor pydantic python-jose bcrypt...
```

**Verify:**
```bash
pip list | grep -E "fastapi|uvicorn|motor|pydantic"
```

✅ **Backend dependencies installed!**

---

## Step 2: Test Backend Locally

```bash
# Load environment
export $(cat .env.production | xargs)

# Test FastAPI start
python3 main.py &
sleep 3

# Test health endpoint (in another terminal or new SSH session)
curl http://localhost:8000/health
```

**Expected response:**
```json
{"status":"healthy","version":"1.0.0"}
```

If you see this, the backend works! Kill it:
```bash
pkill -f "python3 main.py"
```

✅ **Backend tested!**

---

## Step 3: Start Backend with PM2

```bash
# Deactivate virtual environment first
deactivate

# Create PM2 startup script
cd ~/projects/motivai/backend

cat > start_backend.sh << 'EOF'
#!/bin/bash
source venv/bin/activate
export $(cat .env.production | xargs)
python3 main.py
EOF

# Make it executable
chmod +x start_backend.sh

# Start with PM2
pm2 start start_backend.sh --name "motivai-backend"

# Verify it's running
pm2 ps

# View logs
pm2 logs motivai-backend
```

**Expected output from `pm2 ps`:**
```
┌─────┬──────────────────┬──────┬───────┐
│ id  │ name             │ mode │ status│
├─────┼──────────────────┼──────┼───────┤
│ 0   │ motivai-backend  │ fork │ online│
└─────┴──────────────────┴──────┴───────┘
```

**Test backend is running:**
```bash
curl http://localhost:8000/health
```

✅ **Backend running with PM2!**

---

# PHASE 6: SETUP FRONTEND (Flutter Web)

## Step 1: Build Flutter Web for Production

```bash
# Navigate to frontend
cd ~/projects/motivai/mobile_app

# Get dependencies
flutter pub get

# Build web release
flutter build web --release
```

**This takes 2-5 minutes. Watch for messages like:**
```
Building with sound null safety
...
Build complete!
...
Built web release bundle.
```

**If you get error "Flutter not found":**
```bash
# Install Flutter on EC2
cd ~
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$HOME/flutter/bin"

# Test
flutter --version
```

Then retry the build.

**Verify build output:**
```bash
ls -la build/web/
```

Should show: `index.html`, `assets/`, `main.dart.js`, etc.

✅ **Frontend built!**

---

## Step 2: Copy Frontend to Nginx Directory

```bash
# Create nginx directory for our app
sudo mkdir -p /var/www/motivai

# Copy built files to nginx
sudo cp -r build/web/* /var/www/motivai/

# Fix permissions
sudo chown -R www-data:www-data /var/www/motivai
sudo chmod -R 755 /var/www/motivai

# Verify
ls -la /var/www/motivai/
```

You should see your Flutter web files here.

✅ **Frontend files copied to Nginx!**

---

# PHASE 7: CONFIGURE NGINX

## Step 1: Backup Original Nginx Config

```bash
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup
```

---

## Step 2: Create Nginx Configuration

```bash
# Edit nginx config
sudo nano /etc/nginx/sites-available/default
```

**Clear everything and paste this:**

```nginx
# Nginx configuration for MotivAI

# Upstream backend server
upstream backend {
    server localhost:8000;
}

# Server block
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name 13.49.73.105;  # Your EC2 IP
    
    # Root directory for static frontend files
    root /var/www/motivai;
    
    # Logging
    access_log /var/log/nginx/motivai_access.log;
    error_log /var/log/nginx/motivai_error.log;
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # Client max upload size
    client_max_body_size 20M;
    
    # API proxy to FastAPI backend
    location /api/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        
        # Headers
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
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
    
    # Serve Flutter web app (SPA)
    location / {
        try_files $uri $uri/ /index.html;
        
        # Cache index.html for short time
        location = /index.html {
            add_header Cache-Control "public, max-age=300";
        }
        
        # Cache other static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            add_header Cache-Control "public, max-age=31536000, immutable";
            expires 1y;
        }
    }
}
```

**To save in nano:**
- Press `Ctrl + X`
- Press `Y`
- Press `Enter`

✅ **Nginx config created!**

---

## Step 3: Test Nginx Configuration

```bash
# Test syntax
sudo nginx -t
```

**Expected output:**
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

If you get errors, check:
1. Spelling of file paths
2. Semicolons at end of lines
3. Matching curly braces `{}`

---

## Step 4: Start/Restart Nginx

```bash
# Start or restart nginx
sudo systemctl restart nginx

# Verify it's running
sudo systemctl status nginx

# Should show: active (running)
```

✅ **Nginx running!**

---

# PHASE 8: VERIFY CORS CONFIGURATION

## Step 1: Check Backend CORS Settings

```bash
# View backend .env
cat ~/projects/motivai/backend/.env.production | grep CORS
```

**Should show:**
```
CORS_ORIGINS=["http://13.49.73.105", "http://localhost"]
```

If not, edit it:
```bash
nano ~/projects/motivai/backend/.env.production
# Update CORS_ORIGINS line
# Save with Ctrl+X, Y, Enter

# Restart PM2
pm2 restart motivai-backend
pm2 logs motivai-backend
```

---

## Step 2: Test CORS Headers

```bash
# Check if backend responds with CORS headers
curl -H "Origin: http://13.49.73.105" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS http://localhost:8000/api/v1/health -v
```

**Look for response headers:**
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH
```

If missing, backend CORS is not configured. Restart it:
```bash
pm2 restart motivai-backend
```

✅ **CORS verified!**

---

# PHASE 9: FINAL TESTING

## Step 1: Test Frontend (Nginx)

Open browser and go to:
```
http://13.49.73.105
```

**You should see:** Your MotivAI Flutter web app loading!

⚠️ **If you see Nginx welcome page:**
```bash
# Check if frontend files exist
ls -la /var/www/motivai/
```

If files are missing:
```bash
# Rebuild and recopy
cd ~/projects/motivai/mobile_app
flutter build web --release
sudo cp -r build/web/* /var/www/motivai/
sudo systemctl restart nginx
```

---

## Step 2: Test Backend API

```bash
# From EC2 or local machine
curl http://13.49.73.105/api/v1/health
```

**Expected response:**
```json
{"status":"healthy","version":"1.0.0"}
```

---

## Step 3: Test API Documentation

```
http://13.49.73.105/docs
```

**You should see:** Swagger UI with all API endpoints!

---

## Step 4: Test Complete Flow

1. **Frontend Load**: http://13.49.73.105
2. **API Docs**: http://13.49.73.105/docs
3. **API Health**: http://13.49.73.105/api/v1/health
4. **Backend Direct**: http://13.49.73.105:8000/health

All should work!

---

# PHASE 10: SETUP AUTOSTART (Optional but Recommended)

## Ensure PM2 and Nginx start on server reboot:

```bash
# Make PM2 start on boot
pm2 startup
# Copy and run the command it shows

# Save PM2 process
pm2 save

# Verify
pm2 status
```

---

# TROUBLESHOOTING GUIDE

## Problem: "Connection refused" when accessing frontend

**Solution:**
```bash
# Check if Nginx is running
sudo systemctl status nginx

# If not running
sudo systemctl start nginx

# Check logs
sudo tail -f /var/log/nginx/error.log
```

---

## Problem: Frontend loads but API calls fail (CORS error in browser console)

**Solution:**
```bash
# Check backend is running
pm2 status

# If not online
pm2 start start_backend.sh --name "motivai-backend"

# Check CORS in .env
cat ~/projects/motivai/backend/.env.production | grep CORS

# Restart PM2
pm2 restart motivai-backend
pm2 logs motivai-backend # Watch for errors
```

---

## Problem: "502 Bad Gateway" error

**Solution:**
```bash
# Backend crashed
pm2 status  # Should show "online"

# Check logs
pm2 logs motivai-backend | tail -50

# Restart
pm2 restart motivai-backend

# Test directly
curl http://localhost:8000/health
```

---

## Problem: Nginx shows "Permission denied"

**Solution:**
```bash
# Fix permissions
sudo chown -R www-data:www-data /var/www/motivai
sudo chmod -R 755 /var/www/motivai

# Restart Nginx
sudo systemctl restart nginx
```

---

## Problem: Database connection error

**Solution:**
```bash
# Check MongoDB connection string
cat ~/projects/motivai/backend/.env.production | grep MONGODB_URL

# Verify it's correct format:
# mongodb+srv://USERNAME:PASSWORD@cluster0.xxxxx.mongodb.net/database

# Test connection
python3 -c "from pymongo import MongoClient; print(MongoClient('YOUR_CONNECTION_STRING')).server_info()"

# If fails, check MongoDB Atlas whitelist has your IP
```

---

# FINAL VERIFICATION CHECKLIST

Run this script on EC2 to verify everything:

```bash
#!/bin/bash

echo "=== MotivAI Deployment Verification ==="
echo ""

echo "1. System Dependencies..."
node --version && echo "✅ Node.js OK" || echo "❌ Node.js Missing"
python3 --version && echo "✅ Python3 OK" || echo "❌ Python3 Missing"
git --version && echo "✅ Git OK" || echo "❌ Git Missing"

echo ""
echo "2. Process Managers..."
systemctl is-active --quiet nginx && echo "✅ Nginx running" || echo "❌ Nginx stopped"
pm2 status | grep "online" >/dev/null && echo "✅ PM2 backend running" || echo "❌ PM2 backend stopped"

echo ""
echo "3. API Endpoints..."
curl -s -o /dev/null -w "Frontend: HTTP %{http_code}\n" http://localhost/
curl -s -o /dev/null -w "Backend: HTTP %{http_code}\n" http://localhost:8000/health
curl -s -o /dev/null -w "API: HTTP %{http_code}\n" http://localhost/api/v1/health

echo ""
echo "4. Frontend Files..."
[ -f /var/www/motivai/index.html ] && echo "✅ Frontend files exist" || echo "❌ Frontend files missing"

echo ""
echo "=== All checks complete ==="
```

---

# 🎉 YOU'RE DONE!

## Your MotivAI app is now live at:

### Frontend (Flutter Web):
```
http://13.49.73.105
```

### Backend API:
```
http://13.49.73.105/api/v1
```

### API Documentation:
```
http://13.49.73.105/docs
```

### Backend Health Check:
```
http://13.49.73.105/api/v1/health
```

---

## Next Steps (Optional):

1. **Setup SSL/HTTPS**: Use Let's Encrypt with Certbot
2. **Enable CloudFront**: CDN for faster content delivery
3. **Setup CloudWatch**: Monitor EC2 performance
4. **Domain**: Add custom domain from Route53
5. **Auto Scaling**: Setup load balancer for multiple instances
6. **Database Backups**: Enable automated backups in MongoDB Atlas

---

**Deployment Completed:** ___________
**EC2 IP**: 13.49.73.105
**Status**: ✅ LIVE
