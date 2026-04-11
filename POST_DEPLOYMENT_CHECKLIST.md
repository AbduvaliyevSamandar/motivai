# ✅ POST-DEPLOYMENT CHECKLIST & MONITORING
## MotivAI Production Verification (30 Minutes)

**Purpose:** Verify everything works correctly after deploy.sh completes  
**Audience:** Deployment verification, monitoring, troubleshooting  

---

## 📋 IMMEDIATE CHECKS (Right After Deployment)

### 1. SSH Connection Verification
```bash
# Ensure you're still connected to EC2
whoami
# Expected: ubuntu

# Check hostname
hostname -I
# Expected: Shows your EC2 private IP (e.g., 172.31.x.x)
```

### 2. Backend Service Status
```bash
# Check if backend is running
sudo supervisorctl status motivai-backend

# Expected Output:
# motivai-backend                RUNNING   pid 1234, uptime 0:00:45
```

**If NOT RUNNING:**
```bash
# Start it
sudo supervisorctl start motivai-backend

# Check for errors in log
sudo tail -50 /var/log/motivai-backend.log
```

### 3. Nginx Status
```bash
# Check if Nginx is running
sudo systemctl status nginx

# Expected: active (running)
```

**If NOT RUNNING:**
```bash
# Start it
sudo systemctl restart nginx

# Check error
sudo nginx -t  # Syntax check
```

### 4. Firewall Status
```bash
# Check UFW status
sudo ufw status

# Expected:
# Status: active
# To                         Action      From
# --                         ------      ----
# 22/tcp                     ALLOW       Anywhere
# 80/tcp                     ALLOW       Anywhere
# 443/tcp                    ALLOW       Anywhere
# 8000/tcp                   ALLOW       Anywhere
```

---

## 🌐 CONNECTIVITY TESTS (From Your Local Machine)

### Test 1: Direct Backend Health (SSH Tunnel)
```bash
# SSH to EC2 and test backend directly
ssh -i "path/to/key.pem" ubuntu@13.49.73.105 \
  "curl -s http://127.0.0.1:8000/health | jq ."
```

**Expected Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

**If fails:**
```bash
# Check if backend is listening on port 8000
sudo netstat -tulpn | grep 8000
# or
sudo ss -tulpn | grep 8000
```

### Test 2: Nginx Proxy Health
```bash
# Test through Nginx reverse proxy
curl http://13.49.73.105/api/v1/health

# Expected: Same JSON response as above
```

**If times out or connection refused:**
- Check AWS Security Group allows port 80
- Check Nginx is running: `sudo systemctl status nginx`
- Check Nginx config: `sudo nginx -t`

### Test 3: Swagger UI Access
```
Open in browser: http://13.49.73.105/docs
```

**Expected:** Swagger UI loads with list of all API endpoints

**If blank or error:**
- Check backend logs: `sudo tail -100 /var/log/motivai-backend.log`
- Check browser console for errors (F12)

### Test 4: CORS Headers Check
```powershell
# From local machine PowerShell
curl -i -X OPTIONS `
  -H "Origin: http://13.49.73.105" `
  -H "Access-Control-Request-Method: GET" `
  http://13.49.73.105/api/v1/health
```

**Expected headers in response:**
```
Access-Control-Allow-Origin: http://13.49.73.105
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

**If missing CORS headers:**
```bash
# Edit backend config
sudo nano /home/ubuntu/motivai/backend/.env.production

# Verify CORS_ORIGINS includes your frontend URL
CORS_ORIGINS=["http://13.49.73.105"]

# Restart backend
sudo supervisorctl restart motivai-backend
```

---

## 📊 DATABASE CONNECTIVITY TEST

### Test 1: MongoDB Connection
```bash
# SSH to EC2
ssh -i "path/to/key.pem" ubuntu@13.49.73.105

# Test MongoDB connection
python3 << 'EOF'
from pymongo import MongoClient
import os

try:
    mongo_url = open('/home/ubuntu/motivai/backend/.env.production').read()
    mongo_url = [line.split('=')[1] for line in mongo_url.split('\n') if 'MONGODB_URL' in line][0]
    
    client = MongoClient(mongo_url)
    db = client['motivai']
    
    # Test connection
    db.command('ping')
    print("✅ MongoDB connection successful!")
    
    # List collections
    collections = db.list_collection_names()
    print(f"✅ Collections: {collections}")
    
except Exception as e:
    print(f"❌ MongoDB error: {e}")
EOF
```

**Expected Output:**
```
✅ MongoDB connection successful!
✅ Collections: ['users', 'tasks', 'sessions', ...]
```

**If connection fails:**
- Check MongoDB URL: `grep MONGODB_URL /home/ubuntu/motivai/backend/.env.production`
- Verify EC2 IP in MongoDB Atlas whitelist
- Check MongoDB Atlas cluster status (may need to wake up free tier)

### Test 2: Create Test User
```bash
# Create test user via API
curl -X POST http://13.49.73.105/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "TestPass123!",
    "full_name": "Test User"
  }'
```

**Expected Response:**
```json
{
  "id": "507f1f77bcf86cd799439011",
  "email": "testuser@example.com",
  "full_name": "Test User",
  "created_at": "2024-04-03T10:30:00+00:00"
}
```

**If error:**
- Check MongoDB connection
- Verify .env.production has correct MONGODB_URL
- Check backend logs: `sudo tail -100 /var/log/motivai-backend.log`

---

## 📁 DEPLOYMENT FILE VERIFICATION

### Verify All Files in Place
```bash
# Check backend directory
ls -la /home/ubuntu/motivai/backend/

# Expected files:
# main.py
# requirements.txt
# .env.production
# venv/
# app/
```

### Verify Virtual Environment
```bash
# Check Python version
/home/ubuntu/motivai/backend/venv/bin/python3 --version

# Expected: Python 3.8+ (check your requirements)

# Check installed packages
/home/ubuntu/motivai/backend/venv/bin/pip list | grep -E "fastapi|motor|uvicorn"

# Expected:
# fastapi      0.104.x
# motor        3.4.x
# uvicorn      0.24.x
```

### Verify Supervisor Configuration
```bash
# Check supervisor config
cat /etc/supervisor/conf.d/motivai.conf

# Expected to show:
# directory=/home/ubuntu/motivai/backend
# command=/home/ubuntu/motivai/backend/venv/bin/python3 main.py
# autostart=true
# autorestart=true
```

### Verify Nginx Configuration
```bash
# Check nginx config
cat /etc/nginx/sites-available/default | grep -A 20 "upstream backend"

# Expected to show:
# upstream backend {
#     server 127.0.0.1:8000;
# }
```

---

## 📊 PERFORMANCE & RESOURCE CHECK

### Memory Usage
```bash
# Check free memory
free -h

# Expected: At least 500MB free on t2.micro

# Check backend memory
ps aux | grep motivai
# Check RSS column (memory usage) - should be under 200MB
```

### CPU Usage
```bash
# Quick CPU check
top -bn1 | head -20

# Press 'q' to exit

# Expected: CPU usage < 50% at idle
```

### Disk Space
```bash
# Check disk usage
df -h /

# Expected: At least 5GB free

# Check if logs are growing
du -sh /var/log/motivai-backend.log
# Should be small (< 100MB for first run)
```

### Network Connections
```bash
# Check listening ports
sudo netstat -tulpn | grep LISTEN

# Expected:
# tcp 0 0 0.0.0.0:80  0.0.0.0:* LISTEN  (nginx)
# tcp 0 0 127.0.0.1:8000  0.0.0.0:* LISTEN  (backend)
# tcp 0 0 0.0.0.0:22  0.0.0.0:* LISTEN  (ssh)
```

---

## 🧪 API ENDPOINT TESTS

### Test Health Endpoint
```bash
curl -s http://13.49.73.105/api/v1/health | jq .
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-04-03T10:30:00+00:00"
}
```

### Test Authentication - Register
```bash
curl -X POST http://13.49.73.105/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@test.com",
    "password": "SecurePass123!",
    "full_name": "New User"
  }'
```

**Expected:** User created with ID

### Test Authentication - Login
```bash
curl -X POST http://13.49.73.105/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@test.com",
    "password": "SecurePass123!"
  }'
```

**Expected:** JSON with `access_token` and `refresh_token`

### Test Protected Endpoint
```bash
# First, get a token from login response above
# Replace TOKEN with the actual token

curl -X GET http://13.49.73.105/api/v1/users/me \
  -H "Authorization: Bearer TOKEN"
```

**Expected:** User details in JSON

---

## 🔍 LOG ANALYSIS

### View Backend Logs
```bash
# Last 50 lines
sudo tail -50 /var/log/motivai-backend.log

# Last 100 lines with follow (live updates)
sudo tail -f /var/log/motivai-backend.log
# Press Ctrl+C to stop

# Search for errors
sudo grep ERROR /var/log/motivai-backend.log

# Count log lines
sudo wc -l /var/log/motivai-backend.log
```

### View Nginx Logs
```bash
# Access log (requests)
sudo tail -30 /var/log/nginx/motivai_access.log

# Error log (problems)
sudo tail -30 /var/log/nginx/motivai_error.log

# View failed requests (4xx, 5xx)
sudo grep -E " (4|5)[0-9]{2} " /var/log/nginx/motivai_access.log
```

### Analyze Error Patterns
```bash
# Count 502 errors (bad gateway)
sudo grep "502" /var/log/nginx/motivai_error.log | wc -l

# Count backend errors
sudo grep "ERROR\|Exception" /var/log/motivai-backend.log | wc -l

# Find specific error
sudo grep "mongoclient" /var/log/motivai-backend.log -i
```

---

## ⚠️ COMMON ISSUES & RESOLUTION

### Issue 1: Backend Not Starting
```bash
# Check error
sudo supervisorctl status motivai-backend

# If FATAL, check logs
sudo tail -100 /var/log/motivai-backend.log

# Common fixes:
# 1. MongoDB URL issue
grep MONGODB_URL /home/ubuntu/motivai/backend/.env.production

# 2. Port already in use
sudo lsof -i :8000

# 3. Dependencies missing
/home/ubuntu/motivai/backend/venv/bin/pip list
```

### Issue 2: Nginx Returns 502 Bad Gateway
```bash
# 1. Check if backend is running
sudo supervisorctl status motivai-backend

# 2. Check if backend is listening
sudo netstat -tulpn | grep 8000

# 3. Test backend directly
curl http://127.0.0.1:8000/health

# 4. Check Nginx error log
sudo tail -50 /var/log/nginx/motivai_error.log

# Fix:
sudo systemctl restart nginx
sudo supervisorctl restart motivai-backend
```

### Issue 3: Database Connection Error
```bash
# 1. Check connection string
cat /home/ubuntu/motivai/backend/.env.production | grep MONGODB_URL

# 2. Test connection manually
python3 -c "from pymongo import MongoClient; \
    MongoClient('YOUR_URL_HERE').admin.command('ping'); \
    print('Connected!')"

# 3. Check MongoDB Atlas whitelist
# Go to https://cloud.mongodb.com/v2 → Network Access
# Add 13.49.73.105 to IP list

# 4. Restart backend after whitelisting
sudo supervisorctl restart motivai-backend
```

### Issue 4: CORS Errors from Frontend
```bash
# 1. Check CORS configuration
grep CORS_ORIGINS /home/ubuntu/motivai/backend/.env.production

# 2. Add your frontend URL
sudo nano /home/ubuntu/motivai/backend/.env.production

# Update (example):
# CORS_ORIGINS=["http://13.49.73.105", "http://localhost:3000"]

# 3. Restart backend
sudo supervisorctl restart motivai-backend

# 4. Test CORS headers
curl -i -X OPTIONS -H "Origin: http://13.49.73.105" \
  http://13.49.73.105/api/v1/health
```

### Issue 5: High Memory Usage
```bash
# 1. Check current memory
ps aux | grep motivai | grep -v grep

# 2. If over 500MB, restart backend
sudo supervisorctl restart motivai-backend

# 3. Check for memory leaks (should stabilize)
free -h
watch -n 1 'free -h'  # Updates every 1 second

# 4. Check MongoDB connection pooling
# Consider adjusting in code if queries are slow
```

---

## 📈 ONGOING MONITORING

### Daily Check (5 minutes)
```bash
#!/bin/bash
# Save as: daily_check.sh
# Run: ./daily_check.sh

echo "=== SERVICE STATUS ==="
sudo supervisorctl status motivai-backend
sudo systemctl status nginx --no-pager | head -5

echo -e "\n=== RESOURCE USAGE ==="
free -h | grep Mem
df -h / | tail -1

echo -e "\n=== HEALTH CHECK ==="
curl -s http://127.0.0.1:8000/health | jq .status

echo -e "\n=== RECENT ERRORS ==="
sudo grep ERROR /var/log/motivai-backend.log | tail -3
```

### Weekly Review (30 minutes)
- [ ] Review logs for any errors
- [ ] Check disk usage (especially logs)
- [ ] Verify backups are working
- [ ] Test all critical endpoints
- [ ] Review resource usage trends

### Monthly Tasks (1 hour)
- [ ] Update dependencies: `pip install --upgrade -r requirements.txt`
- [ ] Clean up old logs
- [ ] Review security settings
- [ ] Test disaster recovery
- [ ] Update SSL certificates (if using)

---

## 🚀 VERIFICATION SCRIPT

### One-Command Verification
```bash
# Save this as verify_all.sh and run: bash verify_all.sh

#!/bin/bash

echo "=== MotivAI Deployment Verification ==="
echo ""

# 1. Services
echo "1. Service Status:"
echo -n "   Backend: "
sudo supervisorctl status motivai-backend | grep -q "RUNNING" && echo "✅" || echo "❌"

echo -n "   Nginx: "
sudo systemctl is-active nginx | grep -q "active" && echo "✅" || echo "❌"

# 2. Connectivity
echo -e "\n2. Connectivity:"
echo -n "   Backend health: "
curl -s http://127.0.0.1:8000/health 2>/dev/null | grep -q "healthy" && echo "✅" || echo "❌"

echo -n "   Nginx proxy: "
curl -s http://127.0.0.1/api/v1/health 2>/dev/null | grep -q "healthy" && echo "✅" || echo "❌"

# 3. Resources
echo -e "\n3. Resources:"
echo -n "   Memory: "
free_mem=$(free -h | awk '/^Mem:/ {print $7}')
echo "$free_mem available ✅"

echo -n "   Disk: "
disk_use=$(df / | awk 'NR==2 {print $5}')
echo "$disk_use used ✅"

# 4. Database
echo -e "\n4. Database:"
result=$(grep "MONGODB_URL" /home/ubuntu/motivai/backend/.env.production)
if [ -z "$result" ]; then
    echo "   ⚠️  MongoDB URL not configured"
else
    echo "   ✅ MongoDB URL configured"
fi

echo -e "\n=== Verification Complete ==="
```

---

## 📞 QUICK REFERENCE COMMANDS

### Start/Stop Services
```bash
# Start backend
sudo supervisorctl start motivai-backend

# Stop backend
sudo supervisorctl stop motivai-backend

# Restart backend
sudo supervisorctl restart motivai-backend

# Start Nginx
sudo systemctl start nginx

# Stop Nginx
sudo systemctl stop nginx

# Restart both
sudo supervisorctl restart motivai-backend && sudo systemctl restart nginx
```

### View Logs
```bash
# Backend live logs
sudo tail -f /var/log/motivai-backend.log

# Nginx access logs
sudo tail -f /var/log/nginx/motivai_access.log

# Nginx errors
sudo tail -f /var/log/nginx/motivai_error.log
```

### Configuration
```bash
# Edit backend config
sudo nano /home/ubuntu/motivai/backend/.env.production

# Edit Nginx config
sudo nano /etc/nginx/sites-available/default

# Check Nginx syntax
sudo nginx -t

# Reload Nginx (without restarting)
sudo systemctl reload nginx
```

---

## ✅ DEPLOYMENT SIGN-OFF

**After completing all checks above, your deployment is verified!**

**Verification Date:** ________  
**Verified By:** ________  
**Status:** ✅ Production Ready

**Check all these boxes:**
- [ ] Backend running (sudo supervisorctl status)
- [ ] Nginx running (sudo systemctl status nginx)
- [ ] Health check passing (curl /health)
- [ ] API docs accessible (http://13.49.73.105/docs)
- [ ] Database connected (test user creation works)
- [ ] CORS headers present
- [ ] Logs showing no critical errors
- [ ] Memory usage normal
- [ ] Disk space adequate

---

## 🎯 SUCCESS!

Your MotivAI production deployment is:
✅ **Running**  
✅ **Verified**  
✅ **Monitored**  
✅ **Ready for users**

**Next Step:** Deploy frontend and share with users!

---

*Generated: 2024-04-03*  
*Deployment: AWS EC2 MotivAI*
