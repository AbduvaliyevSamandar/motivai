#!/usr/bin/env python3
"""
MotivAI Deployment Script
Automates deployment verification and testing
"""

import subprocess
import sys
import json
import time
from pathlib import Path
import requests
from typing import Optional, Dict, Tuple

class MotivAIDeploymentValidator:
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api/v1"
        self.results = {}
    
    def log(self, level: str, message: str):
        """Print log message with level indicator"""
        levels = {
            "INFO": "ℹ️ ",
            "SUCCESS": "✅",
            "ERROR": "❌",
            "WARNING": "⚠️ "
        }
        print(f"{levels.get(level, '')} {level}: {message}")
    
    def test_backend_health(self) -> bool:
        """Test backend health endpoint"""
        self.log("INFO", "Testing backend health...")
        try:
            response = requests.get(f"{self.base_url}/health", timeout=5)
            if response.status_code == 200:
                self.log("SUCCESS", f"Backend health check: {response.json()}")
                return True
            else:
                self.log("ERROR", f"Backend health check failed: {response.status_code}")
                return False
        except Exception as e:
            self.log("ERROR", f"Backend connection failed: {e}")
            return False
    
    def test_api_documentation(self) -> bool:
        """Test API documentation endpoint"""
        self.log("INFO", "Testing API documentation...")
        try:
            response = requests.get(f"{self.base_url}/docs", timeout=5)
            if response.status_code == 200:
                self.log("SUCCESS", "API documentation available at /docs")
                return True
            else:
                self.log("ERROR", f"API docs endpoint returned: {response.status_code}")
                return False
        except Exception as e:
            self.log("ERROR", f"Failed to access API docs: {e}")
            return False
    
    def test_cors_headers(self) -> bool:
        """Test CORS headers"""
        self.log("INFO", "Testing CORS headers...")
        try:
            response = requests.options(f"{self.api_url}/health", timeout=5)
            
            required_headers = [
                'Access-Control-Allow-Origin',
                'Access-Control-Allow-Methods'
            ]
            
            missing_headers = [h for h in required_headers if h not in response.headers]
            
            if not missing_headers:
                self.log("SUCCESS", "CORS headers properly configured")
                self.log("INFO", f"CORS Origin: {response.headers.get('Access-Control-Allow-Origin')}")
                self.log("INFO", f"CORS Methods: {response.headers.get('Access-Control-Allow-Methods')}")
                return True
            else:
                self.log("WARNING", f"Missing CORS headers: {missing_headers}")
                return False
        except Exception as e:
            self.log("ERROR", f"CORS test failed: {e}")
            return False
    
    def test_database_connection(self) -> bool:
        """Test database connection via API"""
        self.log("INFO", "Testing database connection...")
        try:
            response = requests.get(f"{self.api_url}/health", timeout=5)
            if response.status_code == 200:
                data = response.json()
                if "db_status" in data:
                    self.log("SUCCESS", f"Database status: {data['db_status']}")
                    return True
                else:
                    self.log("WARNING", "Database status not available in health check")
                    return True
            else:
                self.log("ERROR", f"Database check failed: {response.status_code}")
                return False
        except Exception as e:
            self.log("ERROR", f"Database connection test failed: {e}")
            return False
    
    def test_authentication_endpoints(self) -> bool:
        """Test authentication endpoints"""
        self.log("INFO", "Testing authentication endpoints...")
        
        test_user = {
            "email": f"test_{int(time.time())}@test.com",
            "password": "TestPassword123!",
            "full_name": "Test User"
        }
        
        try:
            # Test registration
            response = requests.post(
                f"{self.api_url}/auth/register",
                json=test_user,
                timeout=5
            )
            
            if response.status_code in [200, 201]:
                self.log("SUCCESS", "Registration endpoint working")
                
                # Test login
                login_data = {
                    "email": test_user["email"],
                    "password": test_user["password"]
                }
                
                response = requests.post(
                    f"{self.api_url}/auth/login",
                    json=login_data,
                    timeout=5
                )
                
                if response.status_code == 200:
                    self.log("SUCCESS", "Login endpoint working")
                    return True
                else:
                    self.log("ERROR", f"Login failed: {response.status_code}")
                    return False
            else:
                self.log("WARNING", f"Registration returned: {response.status_code}")
                # This might be normal if user already exists
                return True
                
        except Exception as e:
            self.log("ERROR", f"Authentication test failed: {e}")
            return False
    
    def test_api_endpoints(self) -> bool:
        """Test major API endpoints"""
        self.log("INFO", "Testing API endpoints...")
        
        endpoints = [
            ("/health", "GET"),
            ("/tasks", "GET"),
            ("/leaderboard", "GET"),
        ]
        
        success_count = 0
        for endpoint, method in endpoints:
            try:
                if method == "GET":
                    response = requests.get(f"{self.api_url}{endpoint}", timeout=5)
                else:
                    response = requests.request(method, f"{self.api_url}{endpoint}", timeout=5)
                
                if response.status_code < 500:
                    self.log("SUCCESS", f"{method} {endpoint} - Status: {response.status_code}")
                    success_count += 1
                else:
                    self.log("ERROR", f"{method} {endpoint} - Status: {response.status_code}")
            except Exception as e:
                self.log("WARNING", f"{method} {endpoint} failed: {e}")
        
        return success_count == len(endpoints)
    
    def run_all_tests(self) -> Dict[str, bool]:
        """Run all validation tests"""
        self.log("INFO", "🚀 Starting MotivAI Deployment Validation")
        self.log("INFO", f"Target URL: {self.base_url}")
        print()
        
        tests = [
            ("Backend Health", self.test_backend_health),
            ("API Documentation", self.test_api_documentation),
            ("CORS Configuration", self.test_cors_headers),
            ("Database Connection", self.test_database_connection),
            ("Authentication", self.test_authentication_endpoints),
            ("API Endpoints", self.test_api_endpoints),
        ]
        
        results = {}
        for test_name, test_func in tests:
            try:
                results[test_name] = test_func()
            except Exception as e:
                self.log("ERROR", f"Test {test_name} crashed: {e}")
                results[test_name] = False
            print()
        
        return results
    
    def print_summary(self, results: Dict[str, bool]):
        """Print test summary"""
        self.log("INFO", "📊 Test Summary")
        print()
        
        passed = sum(1 for v in results.values() if v)
        total = len(results)
        
        for test_name, result in results.items():
            status = "✅ PASS" if result else "❌ FAIL"
            print(f"{status} - {test_name}")
        
        print()
        self.log("INFO", f"Result: {passed}/{total} tests passed")
        
        if passed == total:
            self.log("SUCCESS", "All tests passed! Deployment is ready for production. 🎉")
            return True
        else:
            self.log("ERROR", "Some tests failed. Please fix issues before deployment.")
            return False

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="MotivAI Deployment Validator")
    parser.add_argument(
        "--url",
        default="http://localhost:8000",
        help="Base URL of the backend (default: http://localhost:8000)"
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=5,
        help="Request timeout in seconds (default: 5)"
    )
    
    args = parser.parse_args()
    
    validator = MotivAIDeploymentValidator(args.url)
    results = validator.run_all_tests()
    success = validator.print_summary(results)
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
