# MotivAI Production - Quick Reference Guide

**Production Instance:** http://13.49.73.105  
**Instance IP:** 13.49.73.105  
**SSH User:** ubuntu  
**Status:** ✅ RUNNING

---

## 🚀 Quick Commands

### Check All Services
```bash
echo "=== BACKEND ===" && sudo supervisorctl status motivai-backend
echo "=== NGINX ===" && sudo systemctl status nginx
echo "=== FIREWALL ===" && sudo ufw status
echo "=== HEALTH ===" && curl -s http://13.49.73.105/health | python3 -m json.tool
```

### Restart Services
```bash
# Restart backend only
sudo supervisorctl restart motivai-backend

# Restart Nginx only
sudo systemctl restart nginx

# Restart all
sudo supervisorctl restart motivai-backend && sudo systemctl restart nginx
```

### View Logs
```bash
# Backend logs (real-time)
sudo tail -f /var/log/motivai-backend.log

# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log

# System logs
sudo journalctl -xe
```

---

## 🔧 Common Tasks

### Update MongoDB Connection
SSH to instance first:
```bash
ssh -i Samandar.ppk ubuntu@13.49.73.105
```

Then edit config:
```bash
nano /home/ubuntu/motivai/backend/.env.production
```

Update the line:
```
MONGODB_URL=mongodb+srv://username:password@cluster.mongodb.net/motivai
```

Save (Ctrl+X, Y, Enter), then restart:
```bash
sudo supervisorctl restart motivai-backend
sleep 2
sudo supervisorctl status motivai-backend  # Should show RUNNING
```

### Update CORS Origins
```bash
nano /home/ubuntu/motivai/backend/main.py
```

Change this line:
```python
allow_origins=["*"],  # Change to specific domains
```

To:
```python
allow_origins=["https://yourmobileapp.com", "https://yourwebapp.com"],
```

Restart:
```bash
sudo supervisorctl restart motivai-backend
```

### Deploy New Backend Code
1. SSH to instance
2. Update code:
   ```bash
   cd /home/ubuntu/motivai/backend
   git pull origin main  # or git clone for first time
   ```

3. Install dependencies:
   ```bash
   source venv/bin/activate
   pip install -r requirements.txt
   deactivate
   ```

4. Restart backend:
   ```bash
   sudo supervisorctl restart motivai-backend
   ```

### Enable SSL/TLS
```bash
# SSH to instance first
ssh -i Samandar.ppk ubuntu@13.49.73.105

# Install certbot
sudo apt-get update
sudo apt-get install -y certbot python3-certbot-nginx

# Get certificate (replace with your domain)
sudo certbot --nginx -d yourdomain.com

# Auto-renewal is configured automatically
```

---

## 📊 Monitoring URLs

| Component | URL | Expected Response |
|-----------|-----|-------------------|
| Health | http://13.49.73.105/health | `{"status":"healthy",…}` |
| API Docs | http://13.49.73.105/docs | Swagger UI |
| ReDoc | http://13.49.73.105/redoc | ReDoc documentation |
| Root | http://13.49.73.105/ | `{"message":"MotivAI Backend Running",…}` |

---

## 🐛 Troubleshooting Quick Links

### Backend not responding
```bash
sudo supervisorctl status motivai-backend
# If BACKOFF/FATAL:
sudo supervisorctl restart motivai-backend
sleep 3
sudo tail -10 /var/log/motivai-backend.log
```

### 502 Bad Gateway
```bash
# Check Nginx
sudo systemctl status nginx
sudo nginx -t

# Check backend on port 8000
curl http://127.0.0.1:8000/health

# Check firewall
sudo ufw status
```

### Port already in use
```bash
# Find and kill process on port 8000
sudo lsof -i :8000
sudo kill -9 <PID>

# Restart
sudo supervisorctl restart motivai-backend
```

### Cannot connect SSH
```bash
# Check EC2 security group allows port 22
# Check firewall on instance
sudo ufw status

# Verify key permissions
chmod 600 Samandar.ppk

# Test connectivity
ping 13.49.73.105
```

---

## 📈 Performance Monitoring

```bash
# System resources
free -h                    # Memory
df -h                      # Disk space
top -b -n 1               # CPU usage
ps aux | grep python3     # Backend process

# Network
netstat -tlnp | grep 8000 # Backend listening
netstat -tlnp | grep 80   # Nginx listening
ss -an | grep ESTABLISHED  # Active connections

# Logs analysis
grep ERROR /var/log/motivai-backend.log | wc -l
tail -100 /var/log/motivai-backend.log | grep ERROR
```

---

## 🔐 Security Commands

```bash
# Check active firewall rules
sudo ufw show added

# Restrict port 8000 to localhost (recommended)
sudo ufw delete allow 8000/tcp
sudo ufw allow from 127.0.0.1 to any port 8000

# View SSH authorized keys
cat ~/.ssh/authorized_keys

# Check failed SSH attempts
sudo grep "Failed password" /var/log/auth.log | tail -20
```

---

## 📋 Deployment Verification

Run this to verify all systems:
```bash
#!/bin/bash

echo "=== SSH CONNECTION ==="
echo "Connected as: $USER"

echo -e "\n=== BACKEND SERVICE ==="
sudo supervisorctl status motivai-backend

echo -e "\n=== NGINX SERVICE ==="
sudo systemctl status nginx --no-pager | head -3

echo -e "\n=== HEALTH CHECK ==="
curl -s http://127.0.0.1:8000/health | python3 -m json.tool

echo -e "\n=== FIREWALL ==="
sudo ufw status | grep -E "20|80|8"

echo -e "\n=== LISTENING PORTS ==="
sudo ss -tlnp | grep -E "nginx|python"

echo -e "\n=== SYSTEM RESOURCES ==="
echo "Memory:" && free -h | head -2
echo "Disk:" && df -h | grep ' / '
echo "Uptime:" && uptime

echo -e "\n=== ALL SYSTEMS OPERATIONAL ==="
```

---

## 🚨 Emergency Procedures

### Complete Service Restart (if all else fails)
```bash
# 1. Stop backend
sudo supervisorctl stop motivai-backend

# 2. Stop nginx
sudo systemctl stop nginx

# 3. Wait
sleep 2

# 4. Check nothing is listening on ports
sudo ss -tlnp | grep -E ":8000|:80"

# 5. Start nginx
sudo systemctl start nginx

# 6. Start backend
sudo supervisorctl start motivai-backend

# 7. Verify
sleep 3
sudo supervisorctl status motivai-backend
curl -s http://13.49.73.105/health
```

### Rollback to Known Good State
```bash
# 1. View git history
cd /home/ubuntu/motivai/backend
git log --oneline -10

# 2. Revert to last known good commit
git reset --hard <commit-hash>

# 3. Restart
sudo supervisorctl restart motivai-backend
```

### Free Up Disk Space
```bash
# Clean logs (keep 7 days)
sudo journalctl --vacuum=time=7d

# Clean package cache
sudo apt-get clean
sudo apt-get autoclean

# Check space
df -h
```

---

## 📞 Useful Links

- **AWS Console:** https://console.aws.amazon.com/ec2/v2/
- **Instance Status:** Check EC2 dashboard for 13.49.73.105
- **CloudWatch:** https://console.aws.amazon.com/cloudwatch/
- **Security Groups:** Verify port configurations in EC2 security group
- **FastAPI Docs:** http://13.49.73.105/docs
- **Swagger API:** Open in browser for interactive testing

---

## 📝 Change Log

- **2026-04-03 09:16 UTC:** Initial production deployment
  - Backend: FIXED (CORSMiddleware import corrected)
  - Nginx: Configured and active
  - Firewall: All ports open
  - Status: RUNNING ✅

---

**Last Updated:** April 3, 2026  
**Maintenance Window:** Recommend during low-traffic hours  
**Support:** Review PRODUCTION_DEPLOYMENT_FINAL.md for detailed documentation
