# 🚀 MotivAI - Complete Deployment Guide
## From Local Development to Cloud Production

---

## 📋 PROJECT ANALYSIS

### ✅ Current Tech Stack Identified:

| Component | Technology | Status |
|-----------|-----------|--------|
| **Backend** | FastAPI (Python 3.8+) | ✓ Running on localhost:8000 |
| **Frontend** | Flutter Web (Dart) | ✓ Running on Chrome (localhost:57863) |
| **Database** | MongoDB | ✓ Running on localhost:27017 |
| **Authentication** | JWT (python-jose) | ✓ Configured |
| **CORS** | FastAPI CORSMiddleware | ✓ Fixed |
| **API Docs** | Swagger UI | ✓ Available at /docs |

### 📁 Project Structure:
```
MotivAI/
├── backend/                    # FastAPI application
│   ├── main.py                # Entry point (RUNNING)
│   ├── app/
│   │   ├── api/               # API routes
│   │   ├── db/                # Database connection
│   │   ├── core/              # Configuration
│   │   └── schemas/           # Request/response models
│   ├── requirements.txt        # Python dependencies
│   ├── .env                   # Environment variables
│   └── venv/                  # Virtual environment
│
├── mobile_app/                # Flutter web application
│   ├── lib/
│   │   ├── main.dart          # Entry point
│   │   ├── models/            # Data models
│   │   ├── services/          # API client
│   │   ├── providers/         # State management
│   │   ├── screens/           # UI screens
│   │   └── widgets/           # Reusable components
│   ├── pubspec.yaml           # Flutter dependencies
│   └── web/                   # Web build artifacts
│
├── database/                  # Database schemas & migrations
├── docs/                      # Documentation
└── README.md                  # Project overview
```

---

## 🔧 PHASE 1: LOCAL DEPLOYMENT (ALREADY DONE ✓)

### Current Local Status:
✅ MongoDB: Running on localhost:27017
✅ Backend: Running on localhost:8000
✅ Frontend: Running on localhost:57863
✅ CORS: Configured and working
✅ Authentication: JWT implemented
✅ Documentation: Available at http://localhost:8000/docs

### Verify All Services:
```bash
# Check MongoDB
mongosh
> db.adminCommand('ping')
# Should return: { ok: 1 }

# Check Backend
curl http://127.0.0.1:8000/health
# Should return: {"status":"healthy","app":"MotivAI"}

# Check Flutter app
# Open browser to Chrome (should be running)
```

---

## 📦 PHASE 2: PREPARE FOR CLOUD DEPLOYMENT

### Step 1: Create Production Environment Files

#### A. Backend .env File (Production)
Location: `C:\Users\Samandar\Desktop\MotivAI\backend\.env.production`

```env
# FastAPI Settings
ENVIRONMENT=production
DEBUG=false
HOST=0.0.0.0
PORT=8000
APP_NAME=MotivAI
APP_VERSION=1.0.0

# Database
MONGODB_URL=mongodb+srv://username:password@cluster.mongodb.net/motivai
DATABASE_NAME=motivai_prod

# Security
SECRET_KEY=your-super-secret-key-min-32-chars-CHANGE-IN-PRODUCTION
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS
CORS_ORIGINS=["https://motivai.app","https://www.motivai.app"]

# API Settings
MAX_WORKERS=4
```

#### B. Backend requirements.txt (Already exists)
Verify: `C:\Users\Samandar\Desktop\MotivAI\backend\requirements.txt`

Should contain:
```
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.5.3
pydantic-settings==2.1.0
motor==3.3.2
pymongo==4.6.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
python-dotenv==1.0.0
```

#### C. Create .dockerignore
Location: `C:\Users\Samandar\Desktop\MotivAI\backend\.dockerignore`

```
venv/
__pycache__/
*.pyc
.env
.env.local
.pytest_cache/
.coverage
htmlcov/
*.log
.git
.gitignore
README.md
```

#### D. Create Dockerfile (Backend)
Location: `C:\Users\Samandar\Desktop\MotivAI\backend\Dockerfile`

```dockerfile
# Build Stage
FROM python:3.11-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Final Stage
FROM python:3.11-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy Python dependencies from builder
COPY --from=builder /root/.local /root/.local

# Copy application code
COPY . .

# Set environment variables
ENV PATH=/root/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000

# Run application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

#### E. Create docker-compose.yml
Location: `C:\Users\Samandar\Desktop\MotivAI\docker-compose.yml`

```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: motivai_mongodb
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    environment:
      MONGO_INITDB_DATABASE: motivai_prod
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build: ./backend
    container_name: motivai_backend
    ports:
      - "8000:8000"
    environment:
      ENVIRONMENT: production
      MONGODB_URL: mongodb://mongodb:27017
      DATABASE_NAME: motivai_prod
    depends_on:
      mongodb:
        condition: service_healthy
    healthcheck:
      test: [ "CMD", "curl", "-f", "http://localhost:8000/health" ]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    image: node:18-alpine
    container_name: motivai_frontend
    working_dir: /app
    ports:
      - "3000:3000"
    volumes:
      - ./mobile_app:/app
    command: npm run serve
    depends_on:
      - backend

volumes:
  mongodb_data:
```

---

## 🐳 PHASE 3: DOCKER SETUP (LOCAL TESTING)

### Step 1: Build and Run Docker Locally

#### Windows (PowerShell):
```powershell
# Navigate to project root
cd C:\Users\Samandar\Desktop\MotivAI

# Build all containers
docker-compose build

# Start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

#### Linux/Mac (Terminal):
```bash
cd ~/path/to/MotivAI

# Build all containers
docker-compose build

# Start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down
```

### Step 2: Verify Docker Setup
```bash
# Check backend health
curl http://localhost:8000/health

# Check MongoDB
docker exec motivai_mongodb mongosh --eval "db.adminCommand('ping')"

# View container logs
docker logs motivai_backend
```

---

## ☁️ PHASE 4: CLOUD DEPLOYMENT OPTIONS

### **OPTION A: Render (Recommended - Easy & Free Tier)**

#### Step 1: Prepare for Render
```bash
# Create render.yaml in project root
# Location: C:\Users\Samandar\Desktop\MotivAI\render.yaml
```

```yaml
services:
  - type: web
    name: motivai-backend
    env: python
    plan: starter
    buildCommand: pip install -r backend/requirements.txt
    startCommand: uvicorn main:app --host 0.0.0.0 --port $PORT
    envVars:
      - key: ENVIRONMENT
        value: production
      - key: MONGODB_URL
        fromDatabase:
          name: motivai-db
          property: connectionString
      - key: SECRET_KEY
        generateValue: true

  - type: pserv
    name: motivai-db
    plan: starter
    ipAllowList: []
```

#### Step 2: Deploy to Render (Web UI)
1. Go to https://render.com
2. Sign up with GitHub account
3. Create new Web Service
4. Connect your GitHub repo
5. Select Python environment
6. Set build command: `pip install -r backend/requirements.txt`
7. Set start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
8. Click Deploy

#### Step 3: Configure Environment Variables in Render UI
```
ENVIRONMENT = production
DEBUG = false
MONGODB_URL = [Enter MongoDB Atlas URL]
SECRET_KEY = [Generate a secure key]
```

---

### **OPTION B: Railway (Simple & Powerful)**

#### Step 1: Install Railway CLI
```bash
# Windows (PowerShell)
iwr https://railway.app/install.ps1 -useb | iex

# Linux/Mac
curl -fsSL https://railway.app/install.sh | sh
```

#### Step 2: Login and Deploy
```bash
railway login

cd C:\Users\Samandar\Desktop\MotivAI

railway init

# Select project name: motivai

# Add MongoDB service from Railway UI

railway up
```

#### Step 3: View Logs
```bash
railway logs
```

---

### **OPTION C: AWS (Scalable)**

#### Step 1: Create EC2 Instance

**Via AWS Console:**
1. Go to https://console.aws.amazon.com
2. Launch new EC2 instance (Ubuntu 22.04 LTS)
3. Instance type: t2.micro (free tier)
4. Security group: Allow ports 22 (SSH), 80 (HTTP), 443 (HTTPS), 8000 (API)
5. Create and download .pem key file

#### Step 2: Connect to EC2
```bash
# Find your instance public IP in AWS Console
# Example: 54.123.45.67

# Connect via SSH (Windows PowerShell)
ssh -i "C:\path\to\key.pem" ubuntu@54.123.45.67

# Linux/Mac
ssh -i path/to/key.pem ubuntu@54.123.45.67
```

#### Step 3: Setup Ubuntu Server
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io docker-compose

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Install Git
sudo apt install -y git

# Clone your repository
git clone https://github.com/yourusername/motivai.git
cd motivai
```

#### Step 4: Deploy with Docker
```bash
# Create .env production file
sudo nano backend/.env.production
# Paste your production environment variables

# Build and run Docker
sudo docker-compose up -d

# Setup Nginx reverse proxy
sudo apt install -y nginx

# Create Nginx config
sudo nano /etc/nginx/sites-available/motivai
```

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/motivai /etc/nginx/sites-enabled/

# Test Nginx config
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Setup SSL with Let's Encrypt
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

---

### **OPTION D: Vercel (Frontend Only)**

For Flutter web frontend, you can build it as static site:

#### Step 1: Build Flutter Web
```bash
cd C:\Users\Samandar\Desktop\MotivAI\mobile_app

# Build web release
flutter build web --release
```

#### Step 2: Deploy to Vercel
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod

# Connect to your frontend API endpoint
# Update lib/services/api_service.dart with production URL
```

---

## 🔑 PHASE 5: ENVIRONMENT VARIABLES REFERENCE

### Backend (.env.production)
```env
# Server
ENVIRONMENT=production
DEBUG=false
HOST=0.0.0.0
PORT=8000
APP_NAME=MotivAI
APP_VERSION=1.0.0

# Database (MongoDB Atlas)
MONGODB_URL=mongodb+srv://user:password@cluster0.xxxxx.mongodb.net/motivai
DATABASE_NAME=motivai_prod

# Authentication
SECRET_KEY=generate-random-32-char-string-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS
CORS_ORIGINS=["https://motivai.app","https://app.motivai.app","http://localhost:3000"]

# API
MAX_WORKERS=4
LOG_LEVEL=info
```

### Frontend (lib/services/api_service.dart)
```dart
// For Production
const String apiBaseUrl = 'https://api.motivai.app/api/v1';

// For Staging
// const String apiBaseUrl = 'https://staging-api.motivai.app/api/v1';

// For Development
// const String apiBaseUrl = 'http://localhost:8000/api/v1';
```

---

## 📊 PHASE 6: MONITORING & MAINTENANCE

### Health Checks
```bash
# Backend health
curl https://api.motivai.app/health

# Database connection
# Create monitoring endpoint in backend

# Logs
# Configure logging service (e.g., Sentry, DataDog)
```

### Backup Strategy
```bash
# MongoDB Atlas automatic backups (configured in web console)

# Application code backups
git push origin main

# Database export
mongoexport --uri "mongodb+srv://user:pass@cluster.mongodb.net/motivai" \
  --collection users --out users_backup.json
```

---

## 🚨 TROUBLESHOOTING GUIDE

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| CORS errors after deployment | Update CORS_ORIGINS in .env with production domain |
| MongoDB connection fails | Verify MongoDB Atlas IP whitelist includes server IP |
| Port 8000 already in use | `lsof -i :8000` then `kill PID` |
| Docker container crashes | Check logs: `docker logs container-name` |
| Frontend can't reach backend | Verify API_BASE_URL in frontend matches deployed backend URL |

---

## ✅ DEPLOYMENT CHECKLIST

- [ ] Backend requirements.txt verified
- [ ] .env.production file created with secure SECRET_KEY
- [ ] CORS origins updated for production domain
- [ ] Docker images built successfully
- [ ] Local Docker deployment tested
- [ ] MongoDB Atlas cluster created and credentials added
- [ ] Cloud platform account created (Render/Railway/AWS)
- [ ] Environment variables configured in cloud platform
- [ ] Application deployed and health checks passing
- [ ] Frontend points to production API URL
- [ ] SSL/HTTPS enabled
- [ ] Error logging configured
- [ ] Database backups scheduled
- [ ] Domain name configured to point to deployed app

---

## 📞 NEXT STEPS

1. **Choose your cloud provider** (Render recommended for quickstart)
2. **Prepare MongoDB Atlas** (create cloud database)
3. **Deploy backend** to chosen platform
4. **Update frontend** with production API URL
5. **Test all functionality** in production
6. **Setup monitoring** for errors and performance
7. **Configure custom domain** (optional)
8. **Enable SSL/HTTPS** for security

---

Generated: April 3, 2026
Project: MotivAI - AI-Powered Student Motivation Platform
Tech Stack: FastAPI + Flutter + MongoDB
