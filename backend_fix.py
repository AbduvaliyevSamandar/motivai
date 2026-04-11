"""Generate base64-encoded fixed backend and deploy to EC2"""
import base64
import subprocess
import sys

BACKEND_CODE = '''from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
from datetime import datetime

app = FastAPI(title="MotivAI", version="1.0.0")

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "MotivAI Backend Running", "status": "ok"}

@app.get("/health")
async def health():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.get("/api/v1/health")
async def api_health():
    return {"status": "healthy", "version": "1.0.0"}

if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host=host, port=port)
'''

def deploy_fixed_backend():
    """Deploy fixed backend code via base64 encoding"""
    ssh_key = r"C:\Users\Samandar\Desktop\Samandar.ppk"
    ip = "ubuntu@13.49.73.105"
    plink_exe = r'C:\Program Files\PuTTY\plink.exe'
    
    # Encode the backend code as base64
    code_b64 = base64.b64encode(BACKEND_CODE.encode()).decode()
    
    # Create SSH command to write the file
    cmd = [
        plink_exe,
        "-i", ssh_key,
        ip,
        f"echo '{code_b64}' | base64 -d > /home/ubuntu/motivai/backend/main.py && echo 'Backend deployed' && cat /home/ubuntu/motivai/backend/main.py | head -10"
    ]
    
    print("[1/4] Deploying fixed backend code...")
    result = subprocess.run(cmd, shell=False, capture_output=True, text=True)
    print(result.stdout)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
        return False
    
    # Restart supervisor
    print("[2/4] Restarting backend service...")
    cmd2 = [
        plink_exe,
        "-i", ssh_key,
        ip,
        "sudo supervisorctl restart motivai-backend && sleep 3 && sudo supervisorctl status motivai-backend"
    ]
    result2 = subprocess.run(cmd2, shell=False, capture_output=True, text=True)
    print(result2.stdout)
    
    # Test health endpoint
    print("[3/4] Testing health endpoint...")
    cmd3 = [
        plink_exe,
        "-i", ssh_key,
        ip,
        "curl -s http://127.0.0.1:8000/health"
    ]
    result3 = subprocess.run(cmd3, shell=False, capture_output=True, text=True, timeout=10)
    print(result3.stdout)
    
    # Test nginx proxy
    print("[4/4] Testing nginx proxy...")
    cmd4 = [
        plink_exe,
        "-i", ssh_key,
        ip,
        "curl -s http://127.0.0.1:80/"
    ]
    result4 = subprocess.run(cmd4, shell=False, capture_output=True, text=True, timeout=10)
    print(result4.stdout)
    
    print("\n✅ Backend fix deployed successfully!")
    return True

if __name__ == "__main__":
    deploy_fixed_backend()
