# MotivAI - Complete Setup & Run Guide

## Quick Start (5 Minutes)

### Step 1: Start MongoDB
```bash
# Windows (PowerShell as Admin)
mongod

# macOS
brew services start mongodb-community

# Linux
sudo systemctl start mongodb
```

### Step 2: Start Backend
```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate

pip install -r requirements.txt
python main.py
```
✅ Backend running at: `http://localhost:8000`
✅ API Docs at: `http://localhost:8000/api/docs`

### Step 3: Run Flutter App
```bash
cd mobile_app
flutter pub get
flutter run
```

---

## Detailed Setup Instructions

### Requirements
- **Python 3.8+**
- **MongoDB 4.0+**
- **Flutter 3.0+**
- **Dart 3.0+**

### Option 1: Run Everything on Windows

#### 1. Install MongoDB on Windows
```bash
# Using Chocolatey (recommended)
choco install mongodb

# OR download from https://www.mongodb.com/try/download/community
# Run installer and follow prompts
```

#### 2. Start MongoDB Service
```powershell
# PowerShell (Admin)
net start MongoDB

# Or if using Homebrew
mongod
```

#### 3. Setup and Run Backend
```powershell
cd C:\Users\YourUsername\Desktop\MotivAI\backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Run server
python main.py
```

#### 4. Setup and Run Flutter App
```powershell
cd C:\Users\YourUsername\Desktop\MotivAI\mobile_app

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Or specify device
flutter devices  # List available devices
flutter run -d DEVICE_ID
```

---

### Option 2: Run Everything on macOS

#### 1. Install MongoDB
```bash
# Using Homebrew
brew tap mongodb/brew
brew install mongodb-community

# Start MongoDB
brew services start mongodb-community
```

#### 2. Setup and Run Backend
```bash
cd ~/Desktop/MotivAI/backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run server
python main.py
```

#### 3. Setup and Run Flutter App
```bash
cd ~/Desktop/MotivAI/mobile_app

# Get dependencies
flutter pub get

# Run on iOS Simulator
flutter run -d ios

# Or Android Emulator
flutter run -d android
```

---

### Option 3: Run Everything on Linux (Ubuntu/Debian)

#### 1. Install MongoDB
```bash
# Install MongoDB
sudo apt-get update
sudo apt-get install -y mongodb

# Start service
sudo systemctl start mongodb

# Enable on startup
sudo systemctl enable mongodb
```

#### 2. Setup and Run Backend
```bash
cd ~/Desktop/MotivAI/backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run server
python main.py
```

#### 3. Setup and Run Flutter App
```bash
cd ~/Desktop/MotivAI/mobile_app

# Get dependencies
flutter pub get

# Run on connected device
flutter run
```

---

## MongoDB Compass (GUI Management)

### Install MongoDB Compass
1. Download from https://www.mongodb.com/products/compass
2. Install and launch
3. Connect to `mongodb://localhost:27017`
4. View and manage your databases

---

## Verify Installation

### Check Backend is Running
```bash
# In another terminal/PowerShell
curl http://localhost:8000/health

# Expected response:
# {"status":"healthy","service":"MotivAI - Student Motivation Platform","version":"1.0.0"}
```

### Check MongoDB is Running
```bash
mongo --eval "db.adminCommand('ping')"

# Expected response:
# { "ok" : 1 }
```

### Check Flutter Installation
```bash
flutter --version
flutter doctor
```

---

## Troubleshooting

### MongoDB Not Starting
**Error**: `mongod: command not found`
- **Solution**: Install MongoDB or check PATH
  ```bash
  # Add MongoDB to PATH
  export PATH=$PATH:/usr/local/bin  # macOS
  export PATH=$PATH:/opt/mongodb/bin  # Linux
  ```

### Port 8000 Already in Use
**Error**: `Address already in use`
- **Solution**: Kill process on port 8000
  ```bash
  # macOS/Linux
  lsof -ti:8000 | xargs kill -9
  
  # Windows PowerShell
  netstat -ano | findstr :8000
  taskkill /PID <PID> /F
  ```

### Python Module Not Found
**Error**: `ModuleNotFoundError: No module named 'fastapi'`
- **Solution**: Ensure virtual environment is activated and dependencies installed
  ```bash
  # Activate venv
  source venv/bin/activate  # macOS/Linux
  # or
  venv\Scripts\Activate.ps1  # Windows
  
  # Install dependencies
  pip install -r requirements.txt
  ```

### Flutter Build Issues
**Error**: `Flutter command not found`
- **Solution**: Add Flutter to PATH
  ```bash
  export PATH="$PATH:~/flutter/bin"
  ```

### Database Connection Failed
**Error**: `Failed to connect to MongoDB`
- **Solution**: Check MongoDB is running and connection string is correct
  ```bash
  # Check MongoDB
  mongo --version
  
  # Update .env
  MONGODB_URL=mongodb://localhost:27017
  ```

---

## Testing the Application

### 1. Register New User

**URL**: http://localhost:8000/api/v1/auth/register
**Method**: POST
**Headers**: `Content-Type: application/json`

**Request Body**:
```json
{
  "email": "test@example.com",
  "username": "testuser",
  "full_name": "Test User",
  "password": "SecurePass123!"
}
```

**Expected Response**:
```json
{
  "message": "User registered successfully",
  "user_id": "...ObjectId...",
  "email": "test@example.com",
  "username": "testuser"
}
```

### 2. Login

**URL**: http://localhost:8000/api/v1/auth/login
**Method**: POST

**Request Body**:
```json
{
  "email": "test@example.com",
  "password": "SecurePass123!"
}
```

**Expected Response**:
```json
{
  "access_token": "eyJ...token...",
  "refresh_token": "eyJ...token...",
  "token_type": "bearer",
  "user": {
    "id": "...ObjectId...",
    "email": "test@example.com",
    "username": "testuser",
    "full_name": "Test User",
    "role": "student",
    "points": 0,
    "level": 1
  }
}
```

### 3. Get Daily Motivation Plan

**URL**: http://localhost:8000/api/v1/ai/motivation-plan
**Method**: GET
**Headers**: `Authorization: Bearer YOUR_ACCESS_TOKEN`

**Expected Response**:
```json
{
  "task": {
    "id": "...ObjectId...",
    "title": "Morning Meditation",
    "description": "Start your day with a 10-minute meditation session",
    "category": "health",
    "difficulty": "easy",
    "points_reward": 10,
    "duration_minutes": 10
  },
  "reason": "Based on your health preferences, this task will help you grow.",
  "motivation_quote": "Success is 1% inspiration and 99% perspiration. Keep going!",
  "difficulty_adjusted": false,
  "user_level": 1,
  "completion_rate": 0.0
}
```

### 4. Get Global Leaderboard

**URL**: http://localhost:8000/api/v1/leaderboard/global
**Method**: GET

**Expected Response**:
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "user_id": "...ObjectId...",
      "username": "topuser",
      "points": 5000,
      "level": 10,
      "avatar_url": null,
      "total_tasks_completed": 50
    },
    ...
  ],
  "total_entries": 10
}
```

---

## Using Postman for API Testing

1. **Import API Collection**:
   - Open Postman
   - Click "Import"
   - Select `MotivAI-Postman-Collection.json`

2. **Set Environment Variables**:
   - Create new environment
   - Set `{{base_url}}` = `http://localhost:8000/api/v1`
   - Set `{{token}}` = Your access token after login

3. **Test Endpoints**:
   - Use the collection to test all endpoints
   - Responses will show data structure

---

## File Locations

```
C:\Users\YourUsername\Desktop\MotivAI\
├── backend/
│   ├── main.py (Run this for backend)
│   ├── config.py (Configuration)
│   ├── requirements.txt (Python dependencies)
│   └── .env (Environment variables)
├── mobile_app/
│   ├── lib/
│   ├── pubspec.yaml (Flutter dependencies)
│   └── main.dart (App entry point)
└── README.md (This file)
```

---

## Environment Variables

### Backend (.env file)
```
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=motivai_db
SECRET_KEY=your-secret-key-change-in-production
DEBUG=True
PORT=8000
```

---

## Performance Tips

1. **Use MongoDB Indexing**: Create indexes for frequently queried fields
2. **Enable Caching**: Implement Redis for better performance
3. **Optimize Images**: Compress images before upload
4. **Use CDN**: Serve static assets from CDN
5. **Database Connection Pooling**: Use connection pools

---

## Production Deployment

### Backend Deployment (Heroku, AWS, etc.)

1. **Prepare for Production**:
   ```bash
   - Set DEBUG=False in .env
   - Update MONGODB_URL to production database
   - Update SECRET_KEY to secure random key
   - Set CORS_ORIGINS to frontend domain
   ```

2. **Deploy to Heroku**:
   ```bash
   heroku create motivai-backend
   heroku config:set MONGODB_URL=your_production_url
   git push heroku main
   ```

### Flutter App Deployment

1. **Build APK (Android)**:
   ```bash
   flutter build apk --release
   ```

2. **Build Bundle (iOS)**:
   ```bash
   flutter build ios --release
   ```

3. **Upload to Store**:
   - Google Play Console (Android)
   - Apple App Store (iOS)

---

**You're all set! 🚀 Start building amazing things with MotivAI!**
