# 📋 AWS EC2 Deployment - Quick Reference Commands

## 🔑 CONNECTION & ACCESS

### Connect to EC2 (Windows PowerShell)
```powershell
ssh -i "C:\Users\Samandar\Desktop\Samandar.pem" ubuntu@13.49.73.105
```

### Convert PPK to PEM (if needed)
```bash
puttygen C:\Users\Samandar\Desktop\Samandar.ppk -O private-openssh -o C:\Users\Samandar\Desktop\Samandar.pem
```

---

## 📦 INITIAL SETUP (Run Once)

### Update system
```bash
sudo apt update && sudo apt upgrade -y
```

### Install all dependencies
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo apt install -y python3 python3-pip python3-venv git nginx curl wget build-essential
sudo npm install -g pm2
```

### Verify installations
```bash
node --version
npm --version
python3 --version
git --version
nginx -v
pm2 --version
```

---

## 🚀 PROJECT SETUP

### Clone project
```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/AbduvaliyevSamandar/motivai.git
cd motivai
```

### Create MongoDB connection string
On your local machine:
1. Go to MongoDB Atlas: https://www.mongodb.com/cloud/atlas
2. Click "Connect" → "Drivers"
3. Copy connection string

### Setup backend environment
```bash
cd ~/projects/motivai/backend

cat > .env.production << 'EOF'
ENVIRONMENT=production
DEBUG=false
MONGODB_URL=mongodb+srv://USERNAME:PASSWORD@cluster.xxxxx.mongodb.net/motivai
DATABASE_NAME=motivai_prod
SECRET_KEY=generate-32-char-random-string
ALGORITHM=HS256
CORS_ORIGINS=["http://13.49.73.105"]
EOF

# Edit and add real values
nano .env.production
```

### Generate SECRET_KEY
```bash
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

---

## ⚙️ BACKEND SETUP

### Install Python dependencies
```bash
cd ~/projects/motivai/backend
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### Test backend locally
```bash
source venv/bin/activate
export $(cat .env.production | xargs)
python3 main.py
# Press Ctrl+C to stop
```

### Create PM2 startup script
```bash
cd ~/projects/motivai/backend

cat > start_backend.sh << 'EOF'
#!/bin/bash
source venv/bin/activate
export $(cat .env.production | xargs)
python3 main.py
EOF

chmod +x start_backend.sh
```

### Start backend with PM2
```bash
deactivate
pm2 start start_backend.sh --name "motivai-backend"
pm2 status
pm2 logs motivai-backend
```

### Test backend
```bash
curl http://localhost:8000/health
curl http://localhost:8000/api/v1/health
```

---

## 🎨 FRONTEND SETUP

### Build Flutter web
```bash
cd ~/projects/motivai/mobile_app
flutter pub get
flutter build web --release
```

### Copy to Nginx
```bash
sudo cp -r build/web/* /var/www/motivai/
sudo chown -R www-data:www-data /var/www/motivai
sudo chmod -R 755 /var/www/motivai
```

### Verify frontend files
```bash
ls -la /var/www/motivai/
```

---

## 🔧 NGINX CONFIGURATION

### Edit Nginx config
```bash
sudo nano /etc/nginx/sites-available/default
```

### Restart Nginx
```bash
sudo systemctl restart nginx
sudo systemctl status nginx
```

### Test Nginx syntax
```bash
sudo nginx -t
```

### View Nginx logs
```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

---

## 🧪 TESTING & VERIFICATION

### Frontend (Flutter web)
```bash
curl http://localhost/
curl http://13.49.73.105/  # From another machine
```

### Backend API
```bash
curl http://localhost:8000/health
curl http://localhost:8000/api/v1/health
```

### API via Nginx reverse proxy
```bash
curl http://localhost/api/v1/health
curl http://13.49.73.105/api/v1/health  # From another machine
```

### API Documentation
```bash
curl http://localhost/docs
curl http://13.49.73.105/docs  # From another machine
```

### Test CORS headers
```bash
curl -X OPTIONS \
  -H "Origin: http://13.49.73.105" \
  -H "Access-Control-Request-Method: POST" \
  http://localhost:8000/api/v1/health -v
```

### Run verification script
```bash
# Upload script to EC2 first
bash ~/verify_ec2_deployment.sh
```

---

## ⚠️ TROUBLESHOOTING

### Backend not running
```bash
pm2 status
pm2 logs motivai-backend
pm2 restart motivai-backend
```

### Nginx not running
```bash
sudo systemctl status nginx
sudo systemctl start nginx
sudo nginx -t  # Check config
```

### CORS errors
```bash
# Check CORS in .env
cat ~/projects/motivai/backend/.env.production | grep CORS

# Restart backend
pm2 restart motivai-backend
```

### Database connection error
```bash
# Verify connection string
cat ~/projects/motivai/backend/.env.production | grep MONGODB_URL

# Test connection
python3 << 'EOF'
from pymongo import MongoClient
try:
    client = MongoClient("YOUR_CONNECTION_STRING_HERE")
    print("✓ MongoDB connected")
except Exception as e:
    print(f"✗ Error: {e}")
EOF
```

### Port already in use
```bash
# Find what's using port 8000
sudo lsof -i :8000
# or
sudo ss -tulpn | grep 8000

# Kill process
sudo kill -9 PID
```

### Permission denied errors
```bash
# Fix Nginx permissions
sudo chown -R www-data:www-data /var/www/motivai
sudo chmod -R 755 /var/www/motivai

# Fix SSH key permissions
chmod 600 ~/.ssh/*
```

---

## 🔄 MAINTENANCE & UPDATES

### View PM2 dashboard
```bash
pm2 monit
```

### Save PM2 processes
```bash
pm2 save
sudo env PATH=$PATH:/usr/local/bin pm2 startup
```

### View system resources
```bash
free -h          # Memory
df -h            # Disk space
top              # CPU usage
```

### Update project from GitHub
```bash
cd ~/projects/motivai
git pull origin main
cd backend && pip install -r requirements.txt
pm2 restart motivai-backend
cd ../mobile_app
flutter build web --release
sudo cp -r build/web/* /var/www/motivai/
sudo systemctl reload nginx
```

### Monitor services
```bash
# Check all running services
systemctl list-units --type=service --state=running

# Check specific service logs
journalctl -u nginx -f
```

---

## 🛑 STOP / RESTART EVERYTHING

### Stop all services
```bash
pm2 stop all
sudo systemctl stop nginx
```

### Restart all services
```bash
sudo systemctl start nginx
pm2 start all
```

### Restart backend only
```bash
pm2 restart motivai-backend
```

### Restart Nginx only
```bash
sudo systemctl restart nginx
```

---

## 📊 QUICK STATUS CHECK

### All-in-one status
```bash
echo "=== Nginx ===" && sudo systemctl status nginx
echo "=== Backend ===" && pm2 status
echo "=== Ports ===" && sudo ss -tulpn | grep -E ':80|:8000'
echo "=== Disk ===" && df -h /
echo "=== Memory ===" && free -h
```

---

## 🌐 PUBLIC ACCESS

### Your application URLs:
```
Frontend:  http://13.49.73.105
API Docs:  http://13.49.73.105/docs
API Health: http://13.49.73.105/api/v1/health
Direct Backend: http://13.49.73.105:8000/health
```

---

## 🔐 AWS SECURITY GROUP

### Required open ports:
- SSH: Port 22 (source: your IP)
- HTTP: Port 80 (source: 0.0.0.0/0)
- HTTPS: Port 443 (source: 0.0.0.0/0)
- API: Port 8000 (source: 0.0.0.0/0)

### Open in AWS Console:
1. EC2 Dashboard → Security Groups
2. Select your security group
3. Inbound Rules → Edit
4. Add rules for ports above

---

## 📱 Browser DevTools

### Check network requests:
1. Open browser DevTools (F12)
2. Go to Network tab
3. Refresh page
4. Look for:
   - ✅ 200 responses = OK
   - ❌ 404 = File not found
   - ❌ 502 = Backend down
   - ❌ CORS error = CORS misconfigured

### Check Console for errors:
1. Open browser DevTools (F12)
2. Go to Console tab
3. Look for red error messages
4. Common errors:
   - CORS error: Fix backend CORS setting
   - 404: Check API endpoint URL
   - Connection refused: Backend not running

---

**Last Updated:** April 3, 2026
**Project:** MotivAI
**Deployment:** AWS EC2 Ubuntu
