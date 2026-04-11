# 🔧 TROUBLESHOOTING & MAINTENANCE GUIDE
## MotivAI Production Support Handbook

**Purpose:** Fix issues, maintain system, optimize performance  
**Audience:** DevOps, system administrators, developers  
**Updated:** 2024-04-03  

---

## 📚 TABLE OF CONTENTS

1. [Quick Troubleshooting (5-10 min)](#quick-troubleshooting)
2. [Connection Issues](#connection-issues)
3. [Backend Problems](#backend-problems)
4. [Nginx/Proxy Issues](#nginx-proxy-issues)
5. [Database Issues](#database-issues)
6. [Performance Problems](#performance-problems)
7. [Security Issues](#security-issues)
8. [Maintenance Tasks](#maintenance-tasks)
9. [Emergency Recovery](#emergency-recovery)

---

## 🚨 QUICK TROUBLESHOOTING

### "App is down / not responding"

**Step 1: SSH to EC2 (30 seconds)**
```bash
ssh -i "C:\Users\Samandar\Desktop\Samandar.pem" ubuntu@13.49.73.105
```

**Step 2: Check services (1 minute)**
```bash
# Check backend
sudo supervisorctl status motivai-backend

# Check Nginx
sudo systemctl status nginx

# Quick health test
curl http://127.0.0.1:8000/health
```

**Step 3: Restart if needed (2 minutes)**
```bash
# If backend not running
sudo supervisorctl restart motivai-backend

# If Nginx not running
sudo systemctl restart nginx

# Check again
curl http://127.0.0.1:8000/health
```

**Step 4: Check logs if still failing (5 minutes)**
```bash
sudo tail -100 /var/log/motivai-backend.log
sudo tail -50 /var/log/nginx/motivai_error.log
```

**Step 5: Hard restart (3 minutes)**
```bash
# Stop everything
sudo supervisorctl stop motivai-backend
sudo systemctl stop nginx

# Wait 10 seconds
sleep 10

# Start everything
sudo systemctl start nginx
sudo supervisorctl start motivai-backend

# Verify
curl http://127.0.0.1:8000/health
```

---

## 🔌 CONNECTION ISSUES

### Issue: "Connection refused" / "Cannot connect to server"

#### Symptom
```
curl: (7) Failed to connect to 13.49.73.105 port 80: Connection refused
```

#### Diagnosis (Progressive)
```bash
# 1. Can you SSH to EC2?
ssh -i key.pem ubuntu@13.49.73.105
# If NO → EC2 instance down or IP wrong

# 2. Is Nginx running?
sudo systemctl status nginx
# Expected: active (running)

# 3. Is Nginx listening on port 80?
sudo netstat -tulpn | grep :80
# Expected: tcp 0 0 0.0.0.0:80 ... LISTEN

# 4. Can you reach Nginx locally?
curl http://127.0.0.1
# Expected: HTML response or 502 error (not connection refused)

# 5. AWS Security Group allows port 80?
# Check in AWS Console → EC2 → Security Groups
# Should have rule: Inbound 80 from 0.0.0.0/0
```

#### Fixes

**If Nginx not running:**
```bash
# Check for errors
sudo nginx -t

# If syntax OK, try starting
sudo systemctl start nginx

# If fails, check logs
sudo tail -50 /var/log/nginx/error.log
```

**If Nginx running but port 80 not listening:**
```bash
# Check config
cat /etc/nginx/sites-available/default | grep "listen"

# Should show: listen 80 default_server;

# If not, edit:
sudo nano /etc/nginx/sites-available/default

# Restart Nginx
sudo nginx -t && sudo systemctl restart nginx
```

**If Nginx listening but connection refused:**
```bash
# AWS issue - check Security Group
# Go to AWS Console:
# - EC2 → Security Groups
# - Find your group
# - Inbound Rules → Check port 80 allowed from 0.0.0.0/0

# Add rule if missing:
# Type: HTTP, Port: 80, Source: 0.0.0.0/0
```

**If EC2 unreachable:**
```bash
# Check instance running in AWS Console
# Check instance has Elastic IP or public IP assigned
# Try restarting instance from AWS Console
# Wait 2-3 minutes for startup
```

---

### Issue: "Connection timeout" (loads forever)

#### Symptom
```
curl -v http://13.49.73.105
# Hangs for 30+ seconds then times out
```

#### Causes & Fixes

**Cause 1: Nginx listening but backend not responding**
```bash
# Check backend
sudo supervisorctl status motivai-backend
# If not RUNNING, restart it
sudo supervisorctl restart motivai-backend

# Wait 5 seconds
sleep 5

# Test again
curl http://127.0.0.1:8000/health
```

**Cause 2: Both services up but slow response**
```bash
# Check resource usage
free -h
df -h /

# If low memory/disk, free up space
# Kill any unnecessary processes
ps aux | sort -k3 -r | head -5
```

**Cause 3: MongoDB connection slow**
```bash
# Check if MongoDB whitelisting is the issue
# Temporarily add all IPs to MongoDB Atlas:
# Go to https://cloud.mongodb.com → Network Access → Add 0.0.0.0/0

# Then restart backend
sudo supervisorctl restart motivai-backend

# If speeds up, problem is firewall/network delay
# Restrict back to your IP when fixed
```

---

## 🚀 BACKEND PROBLEMS

### Issue: Backend crashes repeatedly

#### Symptom
```bash
sudo supervisorctl status motivai-backend
# OUTPUT: FATAL Exited too quickly (process log may have details)
```

#### Diagnosis
```bash
# 1. Check error log
sudo tail -100 /var/log/motivai-backend.log

# Look for common patterns:
# - "ModuleNotFoundError" → Missing dependency
# - "ConnectionError" → Database connection issue
# - "SyntaxError" → Code error
# - "Address already in use" → Port conflict
```

#### Fixes by Error Type

**Error: ModuleNotFoundError (e.g., cannot import fastapi)**
```bash
# Reinstall dependencies
cd /home/ubuntu/motivai/backend
source venv/bin/activate
pip install -r requirements.txt

# Restart
sudo supervisorctl restart motivai-backend
```

**Error: ConnectionError (MongoDB)**
```bash
# 1. Check MongoDB URL
cat /home/ubuntu/motivai/backend/.env.production | grep MONGODB_URL

# 2. Test connection manually
python3 << 'EOF'
from pymongo import MongoClient
url = open('/home/ubuntu/motivai/backend/.env.production').read()
mongodb_url = [line.split('=')[1].strip() 
               for line in url.split('\n') 
               if 'MONGODB_URL' in line][0]
try:
    MongoClient(mongodb_url, serverSelectionTimeoutMS=5000).admin.command('ping')
    print("✅ Connection OK")
except Exception as e:
    print(f"❌ Error: {e}")
EOF

# 3. If fails, check:
#    - MongoDB URL format correct
#    - Username/password correct (no special chars without URL encoding)
#    - EC2 IP whitelisted in MongoDB Atlas
#    - MongoDB cluster started (not paused)
```

**Error: Address already in use**
```bash
# Something else is using port 8000
sudo lsof -i :8000

# Kill it
sudo kill -9 PID

# Restart backend
sudo supervisorctl restart motivai-backend
```

**Error: SyntaxError or runtime exception**
```bash
# Read full error from logs
sudo tail -200 /var/log/motivai-backend.log | grep -A 50 "Traceback"

# Common fixes:
# - Check main.py for errors
# - Verify all imports work: python3 -c "import fastapi; print('OK')"
# - Check requirements.txt versions

# If code issue, need to fix and redeploy:
cd ~/motivai
git pull origin main
cd backend
source venv/bin/activate
pip install -r requirements.txt
sudo supervisorctl restart motivai-backend
```

### Issue: Backend responding slowly

#### Symptom
```
curl http://13.49.73.105/api/v1/health
# Takes 3+ seconds to respond
```

#### Diagnosis
```bash
# 1. Check resource usage
top -bn1 | head -10
# CPU and Memory usage

# 2. Check database query time
# Tail the logs (make a request in another terminal)
sudo tail -f /var/log/motivai-backend.log
# Look for database query times

# 3. Check if network is the issue
# Ping MongoDB cluster
python3 -c "import time; start=time.time(); \
from pymongo import MongoClient; \
MongoClient('YOUR_URL').admin.command('ping'); \
print(f'MongoDB latency: {(time.time()-start)*1000:.0f}ms')"
```

#### Fixes

**High CPU usage:**
```bash
# 1. Check what's using CPU
ps aux | sort -k3 -r | head -5

# 2. If backend is high, it's likely a slow query
#    Check recent code changes
#    Optimize database queries
#    Consider adding indexes

# 3. Temporarily increase instance size if critical
```

**High memory usage:**
```bash
# 1. Check memory by process
ps aux | grep motivai | grep -v grep

# 2. If over 300MB, likely memory leak
#    Restart backend
sudo supervisorctl restart motivai-backend

#    Check if memory grows again
#    If yes, need to fix code (check for unclosed connections)
```

**MongoDB slow:**
```bash
# 1. Check if cluster is paused
# Go to https://cloud.mongodb.com → Clusters
# Click your cluster → Pause/Resume

# 2. Check network latency
#    Sometimes free tier is slow late at night
#    Consider upgrading cluster

# 3. Optimize queries in code
#    Add database indexes
#    Cache frequently requested data
```

---

## 🔶 NGINX / PROXY ISSUES

### Issue: 502 Bad Gateway

#### Symptom
```
curl http://13.49.73.105
# Returns: HTTP/1.1 502 Bad Gateway
```

#### Diagnosis
```bash
# 1. Is backend running?
sudo supervisorctl status motivai-backend
# If not RUNNING → start it

# 2. Is backend listening on 8000?
sudo netstat -tulpn | grep 8000
# If not in list → backend crashed

# 3. Check Nginx error log
sudo tail -50 /var/log/nginx/error.log
# Look for: "connect() failed" or "Connection refused"

# 4. Test backend directly
curl http://127.0.0.1:8000/health
# If works locally but 502 via Nginx, config issue
# If fails, backend issue (see Backend Problems above)
```

#### Fixes

**Backend not running:**
```bash
sudo supervisorctl restart motivai-backend
sleep 2
curl http://127.0.0.1:8000/health
```

**Backend crashed:**
```bash
# Check why it crashed
sudo tail -100 /var/log/motivai-backend.log

# Restart
sudo supervisorctl restart motivai-backend

# If it crashes again immediately, there's an error
# Follow Backend Problems section above
```

**Nginx config issue:**
```bash
# Check configuration
cat /etc/nginx/sites-available/default | grep -A 5 "upstream backend"

# Should show:
# upstream backend {
#     server 127.0.0.1:8000;
# }

# If wrong, fix it
sudo nano /etc/nginx/sites-available/default

# Test syntax
sudo nginx -t

# Restart
sudo systemctl restart nginx
```

### Issue: 404 Not Found

#### Symptom
```
curl http://13.49.73.105/api/v1/health
# Returns: HTTP/1.1 404 Not Found
```

#### Causes

**Backend is running but endpoint doesn't exist:**
```bash
# Check what endpoints are available
curl http://127.0.0.1:8000/docs
# Look at Swagger UI for available routes

# If /health endpoint exists but returning 404, check:
# - Main.py has the route defined
# - Route is under correct api version
# - No middleware blocking it
```

**Nginx misconfigured for path:**
```bash
# Check if /api/ is being forwarded correctly
cat /etc/nginx/sites-available/default | grep -A 10 "location /api"

# Should have: proxy_pass http://backend;

# If different, Nginx is not forwarding to backend
# Edit and fix:
sudo nano /etc/nginx/sites-available/default
sudo systemctl restart nginx
```

---

## 💾 DATABASE ISSUES

### Issue: "MongoDB connection failed"

#### Symptom
```
[ERROR] MONGODB ERROR: Failed to connect to server
or
requests return 500 with database error
```

#### Diagnosis
```bash
# 1. Check URL is correct
grep MONGODB_URL /home/ubuntu/motivai/backend/.env.production

# 2. Test connection manually
python3 << 'EOF'
from pymongo import MongoClient
import os

url = "YOUR_URL_HERE"  # Paste from .env.production
try:
    client = MongoClient(url, serverSelectionTimeoutMS=5000)
    client.admin.command('ping')
    print("✅ Connection successful")
    print("Databases:", client.list_database_names())
except Exception as e:
    print(f"❌ Error: {type(e).__name__}: {e}")
EOF

# 3. Check MongoDB Atlas status
# Go to https://cloud.mongodb.com → Clusters
# Should show green checkmark = running
```

#### Fixes by Error Type

**Error: "Cannot resolve host"**
```
Cause: Connection string hostname is wrong
Fix: Copy correct connection string from MongoDB Atlas:
1. Go to https://cloud.mongodb.com
2. Click Connect
3. Copy connection string (Driver: Python)
4. Edit: sudo nano /home/ubuntu/motivai/backend/.env.production
5. Update MONGODB_URL=
6. Restart: sudo supervisorctl restart motivai-backend
```

**Error: "authentication failed"**
```
Cause: Username or password wrong
Fix: 
1. Verify credentials at https://cloud.mongodb.com
2. If special chars in password, URL encode:
   @ → %40
   ! → %21
   $ → %24
   etc.
3. Update .env.production with encoded version
4. Restart backend
```

**Error: "IP not whitelisted"**
```
Cause: EC2 IP not allowed to connect to MongoDB
Fix:
1. Go to https://cloud.mongodb.com
2. Network Access → IP Whitelist
3. Add 13.49.73.105 (your EC2 public IP)
4. Or add 0.0.0.0/0 temporarily (less secure)
5. Restart backend
```

**Error: "no replica set"** (if using specific options)
```
Cause: Connection string requires replicaSet but cluster uses standalone
Fix:
1. Check if your cluster is replica set (most free tier are standalone)
2. Remove "?retryWrites=true" from connection string if present
3. Try without that parameter
4. Update and restart backend
```

### Issue: "Database full" or operations slow

#### Symptom
```
Requests getting slower
MongoDB taking >1 second per query
Storage warning from MongoDB Atlas
```

#### Diagnosis
```bash
# Check database storage used
python3 << 'EOF'
from pymongo import MongoClient
url = "YOUR_URL_HERE"
client = MongoClient(url)
db = client['motivai']

# Get collection sizes
for collection_name in db.list_collection_names():
    collection = db[collection_name]
    stats = db.command('collStats', collection_name)
    print(f"{collection_name}: {stats['size'] / 1024 / 1024:.2f} MB")
EOF

# Check in MongoDB Atlas GUI
# Cluster → Metrics → Storage
```

#### Fixes

**Running out of space (free tier limited):**
```bash
# Option 1: Delete old/test data
# From MongoDB Atlas → Collections → Delete documents manually

# Option 2: Upgrade to paid tier
# Go to https://cloud.mongodb.com → Clusters → Change Tier

# Option 3: Archive old data
# Copy old records to backup, then delete
```

**Slow queries:**
```bash
# 1. Add indexes to frequently queried fields
# From code (app/db/database.py):
db.users.create_index('email')  # If not exists

# 2. Use MongoDB Atlas Query Profiler:
# Cluster → Profiler → Check slow queries
# Add indexes for common queries

# 3. Check query optimization in code
# Avoid full collection scans
# Use specific projections (select only needed fields)
```

---

## ⚡ PERFORMANCE PROBLEMS

### Issue: Memory usage keeps growing

#### Symptom
```
Backend process using 100MB → 200MB → 300MB+ over hours
```

#### Diagnosis
```bash
# Monitor memory usage
ps aux | grep motivai | awk '{print $6}'  # Memory in KB

# Check if it keeps growing
for i in {1..10}; do 
  ps aux | grep motivai | grep -v grep
  sleep 10
done
```

#### Fixes

**Memory leak in code:**
```bash
# 1. Restart backend (temporary fix)
sudo supervisorctl restart motivai-backend

# 2. Review code for:
#    - Unclosed MongoDB connections
#    - Accumulating objects in memory
#    - Large data structures not being cleaned up

# 3. Check if specific endpoint causes it
#    Make requests only to specific endpoints
#    Monitor which one causes growth

# 4. Add memory limit to Supervisor to prevent crash
sudo nano /etc/supervisor/conf.d/motivai.conf

# Add line under [program:motivai-backend]:
# memstop=500000  # Kill if exceeds 500MB

# Restart supervisor
sudo supervisorctl reread
sudo supervisorctl update
```

**Too many connections:**
```bash
# Check open connections from backend
sudo lsof -i -P | grep python | wc -l

# If high (>100), backend has connection leak
# Review MongoDB connection pooling settings
# Make sure connections are properly closed

# Temporary fix: restart every X hours
# Add to crontab:
sudo crontab -e

# Add line:
0 */12 * * * sudo supervisorctl restart motivai-backend  # Restart every 12 hours
```

### Issue: High CPU usage

#### Symptom
```
Backend using 50%+ CPU even at idle
```

#### Diagnosis
```bash
# See what's taking CPU
ps aux --sort=-%cpu | head -10

# If backend is high, check for:
# 1. Infinite loops
# 2. Busy-waiting
# 3. Inefficient algorithms
```

#### Fixes

**Python process stuck in loop:**
```bash
# 1. Check code with profiler
#    Not recommended for production, but can identify issue

# 2. Restart to reset
sudo supervisorctl restart motivai-backend

# 3. Check logs for patterns
sudo tail -200 /var/log/motivai-backend.log | grep -i "loop\|error"

# 4. Review recent changes that might cause this
# Revert if needed
```

---

## 🔒 SECURITY ISSUES

### Issue: Suspicious requests / Potential attack

#### Symptoms
```
- Logs filling up very fast
- Requests to random endpoints (404s)
- SQL injection attempts visible
- Many requests from single IP
```

#### Response

**Rate limiting (if Nginx):**
```bash
# Check current rate limit config
cat /etc/nginx/sites-available/default | grep -A 5 "limit"

# Add rate limiting to Nginx
sudo nano /etc/nginx/sites-available/default

# Add before server block:
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req_status 429;

# Add in server block, location /:
limit_req zone=general burst=20 nodelay;

# Test and restart
sudo nginx -t
sudo systemctl restart nginx
```

**Block specific IP:**
```bash
# Check suspicious IPs in logs
sudo tail -100 /var/log/nginx/motivai_access.log | awk '{print $1}' | sort | uniq -c | sort -rn

# Block IP with firewall
sudo ufw insert 1 deny from 192.168.x.x

# Or in Nginx:
sudo nano /etc/nginx/sites-available/default

# Add in server block:
deny 192.168.x.x;

# Restart Nginx
sudo systemctl restart nginx
```

**Enable request logging for investigation:**
```bash
# Already enabled, but check if detailed
cat /etc/nginx/sites-available/default | grep access_log

# Logs should be in:
/var/log/nginx/motivai_access.log
```

### Issue: Unauthorized access / credentials exposed

#### If credentials leaked:

```bash
# 1. IMMEDIATELY generate new credentials
#    New MongoDB password in Atlas dashboard
#    New SECRET_KEY in .env

# 2. Update backend config
sudo nano /home/ubuntu/motivai/backend/.env.production

# 3. Restart backend
sudo supervisorctl restart motivai-backend

# 4. Invalidate existing sessions (if possible)
#    Or force users to re-login

# 5. Review logs for unauthorized access
sudo tail -500 /var/log/motivai-backend.log | grep -i "unauthorized\|denied"

# 6. Rotate any API keys/tokens used
```

---

## 🔧 MAINTENANCE TASKS

### Weekly Tasks

**1. Check Disk Space (2 min)**
```bash
df -h

# If > 80%, clean up logs:
sudo apt clean
sudo journalctl --vacuum=2w  # Keep only 2 weeks of logs

# Clean application logs if they're huge:
sudo truncate -s 0 /var/log/motivai-backend.log
```

**2. Review Error Logs (5 min)**
```bash
# Check for patterns
sudo grep -i "error\|exception" /var/log/motivai-backend.log | tail -20

# If many errors, investigate and fix
```

**3. Security Updates (10 min)**
```bash
# Check for system updates
sudo apt update
sudo apt list --upgradable

# For critical security updates:
sudo apt upgrade -y  # May restart services

# After update, verify services still running:
sudo supervisorctl status motivai-backend
sudo systemctl status nginx
```

### Monthly Tasks

**1. Update Dependencies (15 min)**
```bash
cd /home/ubuntu/motivai/backend
source venv/bin/activate

# Check for outdated packages
pip list --outdated

# Update specific packages carefully:
pip install --upgrade fastapi uvicorn motor

# Test that everything still works
source venv/bin/activate
python3 -c "from app.main import app; print('✅ App loads OK')"

# Restart backend
sudo supervisorctl restart motivai-backend
```

**2. Database Maintenance (15 min)**
```bash
# Create MongoDB backup (Atlas handles this automatically)
# But you can export:
# Go to https://cloud.mongodb.com → Backup → Download

# Check collection sizes
python3 << 'EOF'
from pymongo import MongoClient
url = "YOUR_URL"
client = MongoClient(url)
db = client['motivai']
for col in db.list_collection_names():
    stats = db.command('collStats', col)
    print(f"{col}: {stats['count']} docs, {stats['size']/1024:.0f}KB")
EOF
```

**3. Audit Access Log (10 min)**
```bash
# Check for unusual access patterns
sudo tail -1000 /var/log/nginx/motivai_access.log | awk '{print $1}' | sort | uniq -c | sort -rn | head -20

# If any IP appears too much, might be attack
# Or monitor bot traffic
```

### Quarterly Tasks

**1. Full Security Audit (30 min)**
```bash
# Check firewall rules
sudo ufw status

# Verify only necessary ports open:
# 22 (SSH) - only from your IP ideally
# 80 (HTTP) - from anywhere
# 443 (HTTPS) - from anywhere if using

# Check for rogue processes
ps aux | grep -v root | grep -v ubuntu | grep -v supervisor

# Review user accounts
getent passwd

# Ensure no extra users created
```

**2. Capacity Planning (20 min)**
```bash
# Check current usage trends
df -h
free -h

# Predict when you'll run out of space
# Current: X GB used
# Daily growth: Y MB
# Free space: Z GB
# Days until full: Z*1024 / Y

# If < 30 days, consider:
# - Archive/delete old data
# - Upgrade instance
# - Add EBS volume
```

**3. Disaster Recovery Test (30 min)**
```bash
# Simulate server crash and recovery
#
# 1. So backup configuration:
# - Save .env.production
# - Save /etc/supervisor/conf.d/motivai.conf
# - Save /etc/nginx/sites-available/default

# 2. Could you restore from:
# - GitHub repo? (yes)
# - Database backup? (check MongoDB Atlas automated backups)
# - Secret keys? (saved securely? ✅)

# 3. Test process:
# - Stop all services
# - Restart instance (or just services)
# - Can everything auto-recover?

sudo supervisorctl stop motivai-backend
sudo systemctl stop nginx
sleep 5
sudo systemctl start nginx
sudo supervisorctl start motivai-backend

# Verify everything came back
curl http://127.0.0.1:8000/health
```

---

## 🆘 EMERGENCY RECOVERY

### "Help, server is completely down!"

#### Step 1: Assess the Situation (2 min)
```bash
# Can you SSH?
ssh -i key.pem ubuntu@13.49.73.105

# If NO:
# - Check if EC2 instance is running (AWS Console)
# - Check instance has public IP assigned
# - Check security group allows SSH (22)
# - Restart instance from AWS Console
# - Try SSH again

# If YES, continue...
```

#### Step 2: Check All Services (3 min)
```bash
sudo supervisorctl status motivai-backend
sudo systemctl status nginx
sudo systemctl status supervisor
```

#### Step 3: Restart Everything (3 min)
```bash
# Safest approach: restart all services
sudo systemctl restart supervisor
sudo systemctl restart nginx

# Wait 5 seconds
sleep 5

# Verify
curl http://127.0.0.1:8000/health
curl http://127.0.0.1/api/v1/health
```

#### Step 4: If Services Won't Start (5 min)
```bash
# Check reason for each service
sudo supervisorctl status motivai-backend
# If error, check:
sudo tail -50 /var/log/motivai-backend.log

sudo systemctl status nginx
# If error, check:
sudo nginx -t
sudo tail -50 /var/log/nginx/error.log
```

#### Step 5: Last Resort - Redeploy (10 min)
```bash
# If can't figure out what's wrong:

# Stop existing
sudo supervisorctl stop motivai-backend
sudo systemctl stop nginx

# Re-pull code (might be file corruption)
cd ~/motivai
git pull origin main
cd backend

# Reinstall deps
source venv/bin/activate
pip install -r requirements.txt --force-reinstall

# Start again
cd ..
sudo supervisorctl start motivai-backend
sudo systemctl start nginx

# Verify
curl http://127.0.0.1:8000/health
```

#### Step 6: If Database is the Problem
```bash
# Can't connect to MongoDB?

# Option 1: MongoDB cluster paused
# Go to https://cloud.mongodb.com → Resume cluster

# Option 2: IP whitelist changed
# Check network access, re-add 13.49.73.105

# Option 3: Connection string wrong
# Check: grep MONGODB_URL /home/ubuntu/motivai/backend/.env.production
# Verify format with MongoDB documentation

# Restart after fix
sudo supervisorctl restart motivai-backend
```

### Full System Restore from Scratch

**If everything is corrupted and need to rebuild:**

```bash
# Connect to EC2
ssh -i key.pem ubuntu@13.49.73.105

# 1. Backup current state (if possible)
tar czf ~/motivai-backup.tar.gz ~/motivai /etc/supervisor/conf.d/motivai.conf /etc/nginx/sites-available/default

# 2. Remove everything
sudo systemctl stop nginx
sudo supervisorctl stop motivai-backend
rm -rf ~/motivai

# 3. Re-run deployment script
bash -c "$(curl -fsSL https://raw.githubusercontent.com/AbduvaliyevSamandar/motivai/main/deploy.sh)"

# Follow prompts for MongoDB URL when prompted

# 4. Verify everything
curl http://127.0.0.1:8000/health
curl http://127.0.0.1/api/v1/health
```

---

## 📞 SUPPORT CONTACT

**For critical issues:**
1. Try quick troubleshooting above
2. Check logs thoroughly
3. If unresolved, contact:
   - DevOps Lead: [contact]
   - System Administrator: [contact]

**For questions:**
- Check logs first: `sudo tail -f /var/log/motivai-backend.log`
- Search this guide for similar issues
- Review AWS documentation

---

## 📝 MAINTENANCE CHECKLIST

Use this template daily/weekly as needed:

```
[ ] Daily:
  [ ] Check services running: supervisorctl status
  [ ] Spot check logs: tail -20 /var/log/motivai-backend.log
  [ ] Quick health test: curl http://127.0.0.1:8000/health

[ ] Weekly:
  [ ] Disk space check: df -h
  [ ] Errors review: grep ERROR /var/log/motivai-backend.log
  [ ] System updates: apt list --upgradable

[ ] Monthly:
  [ ] Update packages: pip list --outdated
  [ ] Database maintenance
  [ ] Audit access logs
  [ ] Full system check

[ ] Quarterly:
  [ ] Security audit
  [ ] Capacity planning
  [ ] Disaster recovery test
```

---

**Last Updated:** 2024-04-03  
**Version:** 1.0  
**Status:** ✅ Production

For more info, see:
- PRODUCTION_DEPLOYMENT_GUIDE.md (how to deploy)
- POST_DEPLOYMENT_CHECKLIST.md (verification tests)
- AWS_EC2_DEPLOYMENT.md (detailed EC2 steps)
