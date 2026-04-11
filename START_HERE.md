# 🚀 AWS EC2 DEPLOYMENT - QUICK START (5 MIN READ)

## Your Deployment Toolkit is Ready!

You now have **7 comprehensive files** to deploy MotivAI to AWS EC2.

---

## 📋 STARTING CHECKLIST (Do This First)

Before starting deployment, you need:

- [ ] AWS EC2 instance running (Ubuntu 22.04)
  - Instance IP: **13.49.73.105**
  - Region: Europe (Ireland)
- [ ] EC2 key file (.pem format)
  - Location: `C:\Users\Samandar\Desktop\Samandar.pem`
  - Note: Might need to convert from .ppk
- [ ] GitHub repo with code
  - URL: https://github.com/AbduvaliyevSamandar/motivai
- [ ] MongoDB Atlas cluster
  - Create free M0 tier
  - Get connection string: `mongodb+srv://user:pass@cluster.xxxxx.mongodb.net/motivai`

---

## 🎯 YOUR DEPLOYMENT FILES

| # | File | Purpose | Time |
|---|------|---------|------|
| 1 | **AWS_EC2_DEPLOYMENT.md** | Complete step-by-step guide | Read first |
| 2 | **EC2_QUICK_REFERENCE.md** | Copy-paste commands | Use constantly |
| 3 | **EC2_DEPLOYMENT_CHECKLIST.md** | Track progress | Check off as you go |
| 4 | **verify_ec2_deployment.sh** | Auto-test environment | Run after setup |
| 5 | **test_mongodb.py** | Test DB connection | Run before backend |
| 6 | **DEPLOYMENT_TOOLKIT_README.md** | Toolkit overview | Reference guide |

---

## ⚡ 3-PHASE QUICK DEPLOYMENT

### PHASE 1: Preparation (5 min)
```bash
# On local machine (Windows PowerShell)

# Test MongoDB connection
cd C:\Users\Samandar\Desktop\MotivAI
python test_mongodb.py -i
# Answer prompts with your MongoDB Atlas details
```

Expected: `✅ TEST PASSED - Ready for deployment!`

---

### PHASE 2: Connect to EC2 (2 min)
```bash
# Windows PowerShell
ssh -i "C:\Users\Samandar\Desktop\Samandar.pem" ubuntu@13.49.73.105

# Type 'yes' when prompted
# Expected: ubuntu@ip-xxx:~$
```

---

### PHASE 3: Deploy (40-50 min)
On **EC2 terminal**, follow **AWS_EC2_DEPLOYMENT.md**:

1. **Security Group** (AWS Console) - 5 min
   - Open ports: 22, 80, 443, 8000

2. **Server Setup** - 10 min
   - Update system, install dependencies

3. **Backend Setup** - 10 min
   - Clone repo, install Python, start with PM2

4. **Frontend Setup** - 10 min
   - Build Flutter web, copy to Nginx

5. **Nginx Config** - 5 min
   - Configure reverse proxy

6. **Testing** - 5 min
   - Verify everything works

---

## 🎬 EXACT STEPS (Copy-Paste)

### Step 1: Open Windows PowerShell
```powershell
# Navigate and connect
ssh -i "C:\Users\Samandar\Desktop\Samandar.pem" ubuntu@13.49.73.105
```

### Step 2: On EC2 Terminal, Update System
```bash
sudo apt update
sudo apt upgrade -y
```

### Step 3: Install Everything
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs python3 python3-pip python3-venv git nginx curl wget build-essential
sudo npm install -g pm2
```

### Step 4: Clone & Setup Backend
```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/AbduvaliyevSamandar/motivai.git
cd motivai/backend

# Create environment file (edit with your MongoDB URL)
cat > .env.production << 'EOF'
ENVIRONMENT=production
DEBUG=false
MONGODB_URL=mongodb+srv://YOUR_USER:YOUR_PASS@cluster.mongodb.net/motivai
DATABASE_NAME=motivai_prod
SECRET_KEY=generate-32-char-random-string-CHANGE-THIS
CORS_ORIGINS=["http://13.49.73.105"]
EOF

# Install backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create startup script
cat > start_backend.sh << 'EOF'
#!/bin/bash
source venv/bin/activate
export $(cat .env.production | xargs)
python3 main.py
EOF
chmod +x start_backend.sh

# Start with PM2
deactivate
pm2 start start_backend.sh --name "motivai-backend"
pm2 status
```

### Step 5: Build & Setup Frontend
```bash
cd ~/projects/motivai/mobile_app
flutter pub get
flutter build web --release

# Copy to Nginx
sudo mkdir -p /var/www/motivai
sudo cp -r build/web/* /var/www/motivai/
sudo chown -R www-data:www-data /var/www/motivai
sudo chmod -R 755 /var/www/motivai
```

### Step 6: Configure Nginx
```bash
# Edit Nginx config
sudo nano /etc/nginx/sites-available/default
```

**Paste this config:**
```nginx
upstream backend {
    server localhost:8000;
}

server {
    listen 80 default_server;
    server_name 13.49.73.105;
    
    root /var/www/motivai;
    
    access_log /var/log/nginx/motivai_access.log;
    error_log /var/log/nginx/motivai_error.log;
    
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
    
    location /api/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /docs {
        proxy_pass http://backend/docs;
        proxy_set_header Host $host;
    }
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

**Save:** Ctrl+X → Y → Enter

```bash
# Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx
```

---

## ✅ VERIFY IT WORKS

```bash
# Test backend
curl http://localhost:8000/health
# Should see: {"status":"healthy"}

# Test API via Nginx
curl http://localhost/api/v1/health
# Should see: {"status":"healthy"}

# Test frontend is running
sudo systemctl status nginx
# Should see: active (running)

# Check PM2 backend
pm2 status
# Should show: motivai-backend ... online
```

---

## 🌐 ACCESS YOUR APP

Open browser and go to:

| What | URL |
|------|-----|
| **Frontend** | http://13.49.73.105 |
| **API Docs** | http://13.49.73.105/docs |
| **Health Check** | http://13.49.73.105/api/v1/health |

✅ You should see your **MotivAI Flutter app** running!

---

## ⚠️ IF SOMETHING BREAKS

### Frontend shows Nginx welcome page:
```bash
ls -la /var/www/motivai/
# If empty, rebuild:
cd ~/projects/motivai/mobile_app
flutter build web --release
sudo cp -r build/web/* /var/www/motivai/
```

### Backend returns 502 error:
```bash
pm2 logs motivai-backend
# Check for errors, restart:
pm2 restart motivai-backend
```

### CORS errors in browser:
```bash
# Restart backend with CORS enabled:
pm2 restart motivai-backend
```

### Database connection error:
```bash
# Check connection string:
cat ~/projects/motivai/backend/.env.production | grep MONGODB_URL
# Verify it's correct format: mongodb+srv://user:pass@host/db
```

---

## 📚 FULL DOCUMENTATION

For detailed explanations and advanced troubleshooting:

- **AWS_EC2_DEPLOYMENT.md** - Full step-by-step with explanations
- **EC2_QUICK_REFERENCE.md** - All commands in one file
- **EC2_DEPLOYMENT_CHECKLIST.md** - Verify each step

---

## 🎉 DONE!

Your MotivAI app is now live at **http://13.49.73.105**

### Next Steps:
- [ ] Test all features
- [ ] Share URL with team
- [ ] Monitor logs: `pm2 logs motivai-backend`
- [ ] Setup SSL certificate (optional)
- [ ] Configure custom domain (optional)

---

**Estimated Time:** 50 minutes for complete deployment  
**Support Files:** 6 comprehensive guides included  
**Status:** Ready to deploy! 🚀

---

## 💡 PRO TIPS

1. **Keep terminal open** while following guide
2. **Copy commands from EC2_QUICK_REFERENCE.md** (don't type)
3. **Check logs immediately** if error occurs
4. **Restart services** after config changes
5. **Use verification script** to test everything

---

**Good luck! You've got this! 🎯**
