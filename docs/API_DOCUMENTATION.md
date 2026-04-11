# MotivAI API Documentation

## Base URL
```
http://localhost:8000/api/v1
```

## Authentication
All endpoints (except `/auth/register` and `/auth/login`) require JWT token in header:
```
Authorization: Bearer <ACCESS_TOKEN>
```

---

## 🔐 Authentication Endpoints

### Register User
- **Endpoint**: `POST /auth/register`
- **Auth Required**: No
- **Request Body**:
```json
{
  "email": "user@example.com",
  "username": "username",
  "full_name": "User Name",
  "password": "SecurePassword123!"
}
```
- **Success Response** (200):
```json
{
  "message": "User registered successfully",
  "user_id": "ObjectId",
  "email": "user@example.com",
  "username": "username"
}
```

### Login
- **Endpoint**: `POST /auth/login`
- **Auth Required**: No
- **Request Body**:
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```
- **Success Response** (200):
```json
{
  "access_token": "eyJ...token...",
  "refresh_token": "eyJ...token...",
  "token_type": "bearer",
  "user": {
    "id": "ObjectId",
    "email": "user@example.com",
    "username": "username",
    "full_name": "User Name",
    "role": "student",
    "points": 0,
    "level": 1
  }
}
```

### Refresh Token
- **Endpoint**: `POST /auth/refresh`
- **Auth Required**: No
- **Request Body**:
```json
{
  "refresh_token": "eyJ...token..."
}
```
- **Success Response** (200):
```json
{
  "access_token": "eyJ...new_token...",
  "token_type": "bearer"
}
```

### Logout
- **Endpoint**: `POST /auth/logout`
- **Auth Required**: Yes
- **Success Response** (200):
```json
{
  "message": "Logged out successfully"
}
```

---

## 👤 User Endpoints

### Get Current User Profile
- **Endpoint**: `GET /users/me`
- **Auth Required**: Yes
- **Success Response** (200):
```json
{
  "id": "ObjectId",
  "email": "user@example.com",
  "username": "username",
  "full_name": "User Name",
  "role": "student",
  "points": 150,
  "level": 3,
  "avatar_url": null,
  "bio": "User bio",
  "total_tasks_completed": 15,
  "streak": 5,
  "created_at": "2024-01-01T00:00:00Z"
}
```

### Get User by ID
- **Endpoint**: `GET /users/{user_id}`
- **Auth Required**: No
- **Path Parameters**: `user_id` (ObjectId)
- **Success Response** (200):
```json
{
  "id": "ObjectId",
  "username": "username",
  "full_name": "User Name",
  "points": 150,
  "level": 3,
  "avatar_url": null,
  "bio": "User bio",
  "total_tasks_completed": 15,
  "streak": 5
}
```

### Update User Profile
- **Endpoint**: `PUT /users/me`
- **Auth Required**: Yes
- **Request Body**:
```json
{
  "full_name": "New Name",
  "bio": "New bio",
  "avatar_url": "https://example.com/avatar.jpg"
}
```
- **Success Response** (200):
```json
{
  "message": "Profile updated successfully"
}
```

### Get User Statistics
- **Endpoint**: `GET /users/stats/me`
- **Auth Required**: Yes
- **Success Response** (200):
```json
{
  "total_points": 500,
  "current_level": 5,
  "total_tasks_completed": 25,
  "current_streak": 10,
  "completion_rate": 85.5,
  "rank": 12,
  "achievements_count": 5,
  "last_activity": "2024-01-15T10:30:00Z"
}
```

### List All Users
- **Endpoint**: `GET /users?skip=0&limit=10`
- **Auth Required**: No
- **Query Parameters**: 
  - `skip` (default: 0)
  - `limit` (default: 10)
- **Success Response** (200):
```json
{
  "total": 100,
  "skip": 0,
  "limit": 10,
  "users": [...]
}
```

---

## 📚 Task Endpoints

### List Tasks
- **Endpoint**: `GET /tasks?category=learning&difficulty=medium&skip=0&limit=20`
- **Auth Required**: No
- **Query Parameters**:
  - `category`: learning, health, productivity, creativity, social, exercise
  - `difficulty`: easy, medium, hard
  - `skip`: Pagination offset
  - `limit`: Items per page
- **Success Response** (200):
```json
{
  "total": 50,
  "skip": 0,
  "limit": 20,
  "tasks": [
    {
      "id": "ObjectId",
      "title": "Morning Meditation",
      "description": "10-minute meditation",
      "category": "health",
      "difficulty": "easy",
      "points_reward": 10,
      "duration_minutes": 10,
      "created_at": "2024-01-01T00:00:00Z"
    },
    ...
  ]
}
```

### Get Task Details
- **Endpoint**: `GET /tasks/{task_id}`
- **Auth Required**: No
- **Path Parameters**: `task_id` (ObjectId)
- **Success Response** (200):
```json
{
  "id": "ObjectId",
  "title": "Morning Meditation",
  "description": "10-minute meditation",
  "category": "health",
  "difficulty": "easy",
  "points_reward": 10,
  "duration_minutes": 10,
  "created_at": "2024-01-01T00:00:00Z",
  "completion_count": 5
}
```

### Create Task
- **Endpoint**: `POST /tasks/create`
- **Auth Required**: Yes (Admin only)
- **Request Body**:
```json
{
  "title": "Task Title",
  "description": "Task description",
  "category": "learning",
  "difficulty": "medium",
  "points_reward": 50,
  "duration_minutes": 45
}
```
- **Success Response** (200):
```json
{
  "message": "Task created successfully",
  "task_id": "ObjectId"
}
```

### Update Task
- **Endpoint**: `PUT /tasks/{task_id}`
- **Auth Required**: Yes (Admin only)
- **Request Body**: Same as create (all fields optional)
- **Success Response** (200):
```json
{
  "message": "Task updated successfully"
}
```

### Delete Task
- **Endpoint**: `DELETE /tasks/{task_id}`
- **Auth Required**: Yes (Admin only)
- **Success Response** (200):
```json
{
  "message": "Task deleted successfully"
}
```

---

## ⏱️ Progress Endpoints

### Start Task
- **Endpoint**: `POST /progress/start`
- **Auth Required**: Yes
- **Request Body**:
```json
{
  "task_id": "ObjectId"
}
```
- **Success Response** (200):
```json
{
  "message": "Task started successfully",
  "progress_id": "ObjectId",
  "task_id": "ObjectId"
}
```

### Complete Task
- **Endpoint**: `POST /progress/complete`
- **Auth Required**: Yes
- **Request Body**:
```json
{
  "task_id": "ObjectId",
  "notes": "Optional completion notes"
}
```
- **Success Response** (200):
```json
{
  "message": "Task completed successfully",
  "points_earned": 50,
  "new_total_points": 200,
  "level": 2
}
```

### Get User Progress
- **Endpoint**: `GET /progress/user/me?skip=0&limit=20`
- **Auth Required**: Yes
- **Success Response** (200):
```json
{
  "total": 50,
  "skip": 0,
  "limit": 20,
  "progress": [
    {
      "id": "ObjectId",
      "task_id": "ObjectId",
      "status": "completed",
      "started_at": "2024-01-15T10:00:00Z",
      "completed_at": "2024-01-15T10:30:00Z",
      "points_earned": 50,
      "created_at": "2024-01-15T10:00:00Z"
    },
    ...
  ]
}
```

### Get Weekly Stats
- **Endpoint**: `GET /progress/stats/weekly`
- **Auth Required**: Yes
- **Success Response** (200):
```json
{
  "week_starting": "2024-01-08T00:00:00Z",
  "tasks_completed": 10,
  "total_points": 250,
  "daily_breakdown": {
    "2024-01-08": 50,
    "2024-01-09": 75,
    "2024-01-10": 50,
    ...
  }
}
```

### Get Category Stats
- **Endpoint**: `GET /progress/category-stats`
- **Auth Required**: Yes
- **Success Response** (200):
```json
{
  "categories": [
    {
      "category": "learning",
      "tasks_completed": 5,
      "total_points": 150,
      "last_completed": "2024-01-15T10:30:00Z"
    },
    ...
  ]
}
```

---

## 🤖 AI & Motivation Endpoints

### Get Daily Motivation Plan
- **Endpoint**: `GET /ai/motivation-plan`
- **Auth Required**: Yes
- **Success Response** (200):
```json
{
  "task": {
    "id": "ObjectId",
    "title": "Morning Meditation",
    "description": "10-minute meditation",
    "category": "health",
    "difficulty": "easy",
    "points_reward": 10,
    "duration_minutes": 10
  },
  "reason": "Based on your preferences, this task will help you grow.",
  "motivation_quote": "Success is 1% inspiration and 99% perspiration. Keep going!",
  "difficulty_adjusted": false,
  "user_level": 1,
  "completion_rate": 85.5
}
```

### Get Daily Insight
- **Endpoint**: `GET /ai/daily-insight`
- **Auth Required**: Yes
- **Success Response** (200):
```json
{
  "date": "2024-01-15T00:00:00Z",
  "total_tasks": 5,
  "completed_tasks": 3,
  "completion_rate": 60.0,
  "points_earned": 100,
  "motivation_message": "Great start! Complete your first task to build momentum.",
  "next_recommendation": {
    "task_id": "ObjectId",
    "title": "Study Math",
    "points_reward": 75
  },
  "streak": 5
}
```

### Get Recommendations
- **Endpoint**: `GET /ai/recommendations?count=5`
- **Auth Required**: Yes
- **Query Parameters**: `count` (default: 5)
- **Success Response** (200):
```json
{
  "recommendations": [
    {
      "task": {
        "id": "ObjectId",
        "title": "Task 1",
        "category": "learning",
        "difficulty": "medium",
        "points_reward": 50
      },
      "reason": "Based on your interest in learning, this task..."
    },
    ...
  ],
  "count": 5
}
```

### Get Motivation Quote
- **Endpoint**: `GET /ai/motivation-quote`
- **Auth Required**: No
- **Success Response** (200):
```json
{
  "quote": "The only way to do great work is to love what you do."
}
```

---

## 🏆 Leaderboard Endpoints

### Get Global Leaderboard
- **Endpoint**: `GET /leaderboard/global?limit=100`
- **Auth Required**: No
- **Query Parameters**: `limit` (default: 100)
- **Success Response** (200):
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "user_id": "ObjectId",
      "username": "topuser",
      "points": 5000,
      "level": 10,
      "avatar_url": null,
      "total_tasks_completed": 50
    },
    ...
  ],
  "total_entries": 100
}
```

### Get User Rank
- **Endpoint**: `GET /leaderboard/user-rank`
- **Auth Required**: Yes
- **Success Response** (200):
```json
{
  "rank": 25,
  "total_users": 500,
  "user_id": "ObjectId",
  "username": "username",
  "points": 1500,
  "level": 3,
  "completion_rate": 15,
  "percentage": 5.0
}
```

### Get Nearby Users
- **Endpoint**: `GET /leaderboard/nearby?range=10`
- **Auth Required**: Yes
- **Query Parameters**: `range` (default: 10)
- **Success Response** (200):
```json
{
  "nearby_users": [
    {
      "rank": 24,
      "user_id": "ObjectId",
      "username": "nearby_user",
      "points": 1600,
      "level": 3,
      "is_current_user": false
    },
    {
      "rank": 25,
      "user_id": "ObjectId",
      "username": "current_user",
      "points": 1500,
      "level": 3,
      "is_current_user": true
    },
    ...
  ]
}
```

### Get Leaderboard by Level
- **Endpoint**: `GET /leaderboard/by-level/{level}`
- **Auth Required**: No
- **Path Parameters**: `level` (integer)
- **Success Response** (200):
```json
{
  "level": 5,
  "leaderboard": [...],
  "total_entries": 50
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "status_code": 400,
  "message": "Bad request",
  "detail": "Email or username already registered"
}
```

### 401 Unauthorized
```json
{
  "status_code": 401,
  "message": "Unauthorized",
  "detail": "Invalid or expired token"
}
```

### 403 Forbidden
```json
{
  "status_code": 403,
  "message": "Forbidden",
  "detail": "Only admins can perform this action"
}
```

### 404 Not Found
```json
{
  "status_code": 404,
  "message": "Not found",
  "detail": "User not found"
}
```

### 500 Internal Server Error
```json
{
  "status_code": 500,
  "message": "Internal server error"
}
```

---

## Rate Limiting
Currently no rate limiting is implemented. Recommended for production:
- 100 requests per minute per IP
- 1000 requests per day per user

---

## Pagination
Use `skip` and `limit` parameters:
- `skip`: Number of items to skip (default: 0)
- `limit`: Number of items to return (default: 10-20)

Example: `GET /tasks?skip=20&limit=10` (items 21-30)

---

## Data Types

**ObjectId**: MongoDB ObjectId representation (string)
**datetime**: ISO 8601 format (2024-01-15T10:30:00Z)
**integer**: Whole number
**string**: Text
**boolean**: true/false
**array**: List of items
**object**: JSON object

---

## Testing with cURL

```bash
# Register user
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","username":"test","full_name":"Test","password":"Pass123!"}'

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Pass123!"}'

# Get user profile (replace TOKEN)
curl -X GET http://localhost:8000/api/v1/users/me \
  -H "Authorization: Bearer TOKEN"

# Get leaderboard
curl -X GET http://localhost:8000/api/v1/leaderboard/global
```

---

**API Version**: 1.0.0
**Last Updated**: April 2026
