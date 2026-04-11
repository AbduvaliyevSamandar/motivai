# ✅ AWS EC2 DEPLOYMENT CHECKLIST
## MotivAI - Complete Step-by-Step Progress Tracker

**Project:** MotivAI  
**Target IP:** 13.49.73.105  
**Date Started:** ___________  
**Date Completed:** ___________  

---

## PHASE 1: PRE-DEPLOYMENT SETUP

### AWS Account & EC2 Setup
- [ ] AWS account created
- [ ] EC2 instance launched (Ubuntu 22.04)
- [ ] Security group configured with ports 22, 80, 443, 8000
- [ ] Key pair (.pem file) downloaded
- [ ] 💡 Key file location: `C:\Users\Samandar\Desktop\Samandar.pem`
- [ ] 💡 EC2 Public IP: `13.49.73.105`

### GitHub & MongoDB Setup
- [ ] GitHub repository created/updated
- [ ] Code pushed to GitHub: `https://github.com/AbduvaliyevSamandar/motivai`
- [ ] MongoDB Atlas account created
- [ ] MongoDB cluster created (M0 free tier)
- [ ] Database user created
- [ ] EC2 security IP whitelisted in MongoDB Atlas
- [ ] MongoDB connection string copied
  - Connection string: `mongodb+srv://USERNAME:PASSWORD@cluster.xxxxx.mongodb.net/motivai`

---

## PHASE 2: CONNECT TO EC2

### SSH Connection
- [ ] **Step 1:** Open Windows PowerShell
- [ ] **Step 2:** Run: `icacls "C:\Users\Samandar\Desktop\Samandar.pem" /inheritance:r /grant:r "$env:USERNAME`:F`
- [ ] **Step 3:** Run: `ssh -i "C:\Users\Samandar\Desktop\Samandar.pem" ubuntu@13.49.73.105`
- [ ] **Step 4:** Type `yes` when prompted
- [ ] ✅ **RESULT:** You see the Ubuntu terminal prompt `ubuntu@ip-xxx:~$`

---

## PHASE 3: AWS SECURITY GROUP

### Open Required Ports
- [ ] Go to AWS Console → EC2 → Security Groups
- [ ] Find your security group
- [ ] Click "Inbound Rules" → "Edit Inbound Rules"
- [ ] Add SSH (port 22)
  - [ ] Type: SSH
  - [ ] Port: 22
  - [ ] Source: 0.0.0.0/0
- [ ] Add HTTP (port 80)
  - [ ] Type: HTTP
  - [ ] Port: 80
  - [ ] Source: 0.0.0.0/0
- [ ] Add HTTPS (port 443)
  - [ ] Type: HTTPS
  - [ ] Port: 443
  - [ ] Source: 0.0.0.0/0
- [ ] Add Custom TCP (port 8000)
  - [ ] Type: Custom TCP
  - [ ] Port: 8000
  - [ ] Source: 0.0.0.0/0
- [ ] ✅ **RESULT:** All 4 rules saved

---

## PHASE 4: SERVER SETUP

### Update System
- [ ] Run: `sudo apt update`
- [ ] Run: `sudo apt upgrade -y`
- [ ] ✅ **RESULT:** "Processing triggers..." and prompt returns

### Install Node.js
- [ ] Run: `curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -`
- [ ] Run: `sudo apt install -y nodejs`
- [ ] Verify: `node --version` → Should show v20.x.x
- [ ] Verify: `npm --version` → Should show 10.x.x
- [ ] ✅ **RESULT:** Node.js v20+ installed

### Install Python
- [ ] Run: `sudo apt install -y python3 python3-pip python3-venv`
- [ ] Verify: `python3 --version` → Should show 3.10 or higher
- [ ] ✅ **RESULT:** Python3 10+ installed

### Install Git
- [ ] Run: `sudo apt install -y git`
- [ ] Verify: `git --version` → Should show 2.x.x
- [ ] ✅ **RESULT:** Git installed

### Install Nginx
- [ ] Run: `sudo apt install -y nginx`
- [ ] Verify: `nginx -v` → Should show nginx/1.x.x
- [ ] ✅ **RESULT:** Nginx installed

### Install PM2
- [ ] Run: `sudo npm install -g pm2`
- [ ] Verify: `pm2 --version` → Should show 5.x.x
- [ ] ✅ **RESULT:** PM2 installed globally

### Install Build Tools
- [ ] Run: `sudo apt install -y curl wget build-essential`
- [ ] ✅ **RESULT:** All utilities installed

---

## PHASE 5: PROJECT SETUP

### Clone Repository
- [ ] Run: `mkdir -p ~/projects`
- [ ] Run: `cd ~/projects`
- [ ] Run: `git clone https://github.com/AbduvaliyevSamandar/motivai.git`
- [ ] Run: `cd motivai`
- [ ] Verify: `ls -la` → Should show backend/, mobile_app/, docs/, etc.
- [ ] ✅ **RESULT:** Project cloned successfully

### Create Backend Environment File
- [ ] Run: `cd ~/projects/motivai/backend`
- [ ] Create .env.production file with:
  - [ ] ENVIRONMENT=production
  - [ ] MONGODB_URL=mongodb+srv://USERNAME:PASSWORD@cluster.xxxxx.mongodb.net/motivai
  - [ ] SECRET_KEY=<Generated 32-char key>
  - [ ] CORS_ORIGINS=["http://13.49.73.105", "http://localhost"]
  - All other required fields from template
- [ ] Verify: `cat .env.production` → Should show all variables
- [ ] ✅ **RESULT:** .env.production created with correct values

### Generate SECRET_KEY
- [ ] Run: `python3 -c "import secrets; print(secrets.token_urlsafe(32))"`
- [ ] Copy the output
- [ ] Add to .env.production
- [ ] ✅ **RESULT:** SECRET_KEY added to .env

---

## PHASE 6: BACKEND SETUP (FastAPI)

### Install Python Dependencies
- [ ] Run: `cd ~/projects/motivai/backend`
- [ ] Run: `python3 -m venv venv`
- [ ] Run: `source venv/bin/activate`
- [ ] Run: `pip install --upgrade pip`
- [ ] Run: `pip install -r requirements.txt`
- [ ] Wait for "Successfully installed..." message
- [ ] ✅ **RESULT:** All Python packages installed (2-3 minutes)

### Test Backend Locally
- [ ] Run: `export $(cat .env.production | xargs)`
- [ ] Run: `python3 main.py`
- [ ] Look for messages like:
  - [ ] "Starting server process..."
  - [ ] "MongoDB connected successfully"
  - [ ] "Application startup complete"
- [ ] Open new SSH terminal and test: `curl http://localhost:8000/health`
- [ ] Should see JSON response: `{"status":"healthy","version":"1.0.0"}`
- [ ] Go back to first terminal, press Ctrl+C to stop
- [ ] Run: `deactivate` to exit virtual environment
- [ ] ✅ **RESULT:** Backend runs and health check works

### Create PM2 Startup Script
- [ ] Run: `cd ~/projects/motivai/backend`
- [ ] Create start_backend.sh file with:
  ```bash
  #!/bin/bash
  source venv/bin/activate
  export $(cat .env.production | xargs)
  python3 main.py
  ```
- [ ] Run: `chmod +x start_backend.sh`
- [ ] ✅ **RESULT:** Startup script created and executable

### Start Backend with PM2
- [ ] Run: `pm2 start start_backend.sh --name "motivai-backend"`
- [ ] Run: `pm2 status`
- [ ] Look for motivai-backend with status "online"
- [ ] Run: `pm2 logs motivai-backend`
- [ ] Look for:
  - [ ] "Started server process"
  - [ ] "MongoDB connected"
  - [ ] No ERROR messages
- [ ] Test: `curl http://localhost:8000/health` → See JSON response
- [ ] ✅ **RESULT:** Backend running with PM2

---

## PHASE 7: FRONTEND SETUP (Flutter Web)

### Build Flutter Web
- [ ] Run: `cd ~/projects/motivai/mobile_app`
- [ ] Run: `flutter pub get`
- [ ] Run: `flutter build web --release`
- [ ] Wait for "Build complete!" message (2-5 minutes)
- [ ] ✅ **RESULT:** Web build created in build/web/

### Copy Frontend to Nginx
- [ ] Run: `sudo mkdir -p /var/www/motivai`
- [ ] Run: `sudo cp -r build/web/* /var/www/motivai/`
- [ ] Run: `sudo chown -R www-data:www-data /var/www/motivai`
- [ ] Run: `sudo chmod -R 755 /var/www/motivai`
- [ ] Verify: `ls -la /var/www/motivai/`
- [ ] Should see: index.html, assets/, main.dart.js, etc.
- [ ] ✅ **RESULT:** Frontend files in Nginx directory

---

## PHASE 8: NGINX CONFIGURATION

### Create Nginx Config
- [ ] Run: `sudo nano /etc/nginx/sites-available/default`
- [ ] Clear existing content (Ctrl+A, Delete)
- [ ] Paste complete Nginx configuration from AWS_EC2_DEPLOYMENT.md
- [ ] Save with Ctrl+X, Y, Enter
- [ ] Verify: `cat /etc/nginx/sites-available/default` → Should show your config
- [ ] ✅ **RESULT:** Nginx configuration file updated

### Check Nginx Config Syntax
- [ ] Run: `sudo nginx -t`
- [ ] Should see: "syntax is ok" and "test is successful"
- [ ] If error, common issues:
  - [ ] Missing semicolons (;)
  - [ ] Certificate paths don't exist (skip SSL for now)
  - [ ] Server block not closed (check {} brackets)
- [ ] ✅ **RESULT:** Nginx syntax valid

### Restart Nginx
- [ ] Run: `sudo systemctl restart nginx`
- [ ] Verify: `sudo systemctl status nginx`
- [ ] Should show: "active (running)" in green
- [ ] ✅ **RESULT:** Nginx running

---

## PHASE 9: CORS VERIFICATION

### Check Backend CORS
- [ ] Run: `cat ~/projects/motivai/backend/.env.production | grep CORS`
- [ ] Should show: `CORS_ORIGINS=["http://13.49.73.105", "http://localhost"]`
- [ ] If not correct, edit file: `nano ~/projects/motivai/backend/.env.production`
- [ ] ✅ **RESULT:** CORS configured

### Restart Backend for Changes
- [ ] Run: `pm2 restart motivai-backend`
- [ ] Run: `pm2 logs motivai-backend` → Should show "Starting server process..."
- [ ] ✅ **RESULT:** Backend restarted with new CORS

### Test CORS Headers
- [ ] Run:
  ```bash
  curl -H "Origin: http://13.49.73.105" \
       -H "Access-Control-Request-Method: POST" \
       -X OPTIONS http://localhost:8000/api/v1/health -v
  ```
- [ ] Look for response headers:
  - [ ] `Access-Control-Allow-Origin: *` or your domain
  - [ ] `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH`
- [ ] ✅ **RESULT:** CORS headers present

---

## PHASE 10: COMPREHENSIVE TESTING

### Test Frontend (Nginx)
- [ ] Open browser
- [ ] Go to: `http://13.49.73.105`
- [ ] Should see: MotivAI Flutter app loading
- [ ] If you see Nginx welcome page, frontend files missing:
  - [ ] Run: `ls -la /var/www/motivai/`
  - [ ] If empty, copy files again: `sudo cp -r build/web/* /var/www/motivai/`
- [ ] ✅ **RESULT:** Frontend loads at http://13.49.73.105

### Test Backend Health (Direct)
- [ ] Run: `curl http://13.49.73.105:8000/health`
- [ ] Should see: `{"status":"healthy"}`
- [ ] ✅ **RESULT:** Backend responds on port 8000

### Test API via Nginx Proxy
- [ ] Run: `curl http://13.49.73.105/api/v1/health`
- [ ] Should see: `{"status":"healthy"}`
- [ ] ✅ **RESULT:** Nginx proxy to backend works

### Test API Documentation
- [ ] Open browser
- [ ] Go to: `http://13.49.73.105/docs`
- [ ] Should see: Swagger UI with API endpoints
- [ ] ✅ **RESULT:** API docs accessible

### Run Verification Script
- [ ] Copy tools/verify_ec2_deployment.sh to EC2:
  ```bash
  # On Windows, use SCP or manually create the file
  ```
- [ ] On EC2, run: `bash ~/verify_ec2_deployment.sh`
- [ ] Should see mostly green ✅ checkmarks
- [ ] Note any ❌ failures
- [ ] ✅ **RESULT:** Verification script runs

---

## PHASE 11: TROUBLESHOOTING (If Issues)

### Problem: Frontend shows Nginx Welcome Page
- [ ] Check: `ls -la /var/www/motivai/`
- [ ] If empty:
  - [ ] Run: `cd ~/projects/motivai/mobile_app`
  - [ ] Run: `flutter build web --release`
  - [ ] Run: `sudo cp -r build/web/* /var/www/motivai/`

### Problem: Backend not responding (502 error)
- [ ] Check: `pm2 status` → Should show "online"
- [ ] If not: `pm2 start start_backend.sh --name "motivai-backend"`
- [ ] Check logs: `pm2 logs motivai-backend`
- [ ] Look for ERROR messages
- [ ] Common: Database connection → Check MONGODB_URL in .env.production

### Problem: CORS error in browser console
- [ ] Check: `cat ~/projects/motivai/backend/.env.production | grep CORS`
- [ ] Add your frontend domain if missing
- [ ] Restart: `pm2 restart motivai-backend`
- [ ] Check: `curl -X OPTIONS ... http://localhost:8000/api/v1/health -v`
- [ ] Verify CORS headers present

### Problem: "Connection refused"
- [ ] Check ports open: `sudo ss -tulpn | grep -E ":80|:8000"`
- [ ] Check security group in AWS Console
- [ ] Verify ports 80 and 8000 are open to 0.0.0.0/0

---

## PHASE 12: FINAL VERIFICATION

### Pre-Launch Checklist
- [ ] Frontend loads at http://13.49.73.105 ✅
- [ ] API responds at http://13.49.73.105/api/v1/health ✅
- [ ] Documentation available at http://13.49.73.105/docs ✅
- [ ] Backend process running: `pm2 status` shows "online" ✅
- [ ] Nginx running: `sudo systemctl status nginx` shows "active" ✅
- [ ] Database connection working (check PM2 logs) ✅
- [ ] CORS headers present (test with OPTIONS request) ✅
- [ ] Security group has required ports open ✅

### Success Indicators
- [ ] ✅ All tests passed in verification script
- [ ] ✅ No ERROR messages in PM2 logs
- [ ] ✅ No red errors in browser console
- [ ] ✅ API endpoints respond correctly
- [ ] ✅ Frontend and backend working together

---

## OPTIONAL: SETUP AUTOSTART

### Make Services Start on Reboot
- [ ] Run: `pm2 startup`
- [ ] Copy and run the command shown
- [ ] Run: `pm2 save`
- [ ] Verify: `pm2 status` after reboot

---

## DEPLOYMENT COMPLETE! 🎉

### Your MotivAI App is Live at:

| Service | URL |
|---------|-----|
| **Frontend** | http://13.49.73.105 |
| **API Health** | http://13.49.73.105/api/v1/health |
| **API Docs** | http://13.49.73.105/docs |
| **Backend Direct** | http://13.49.73.105:8000/health |

---

## NOTES & TROUBLESHOOTING

**Date Started:** ___________

**Issues Encountered:**
```
1. _________________________________
   Solution: _____________________

2. _________________________________
   Solution: _____________________

3. _________________________________
   Solution: _____________________
```

**Total Time to Deploy:** ___________

**Performance Notes:**
- Frontend load time: ___________
- API response time: ___________
- Database query time: ___________

**Next Steps:**
- [ ] Setup SSL/HTTPS certificate (Let's Encrypt)
- [ ] Configure custom domain
- [ ] Setup CloudFront CDN
- [ ] Enable CloudWatch monitoring
- [ ] Setup error logging (Sentry)
- [ ] Schedule database backups
- [ ] Document deployment procedures

---

**Deployment Completed By:** ___________________________  
**Date:** ___________________________  
**Status:** ✅ SUCCESSFULLY DEPLOYED
