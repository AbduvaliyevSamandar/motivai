"""Generate and deploy Nginx HTTPS configuration"""
import subprocess
import base64

config_content = """# HTTP to HTTPS redirect
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

# HTTPS Server
server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;
    server_name _;
    
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    client_max_body_size 50M;
    
    upstream backend {
        server 127.0.0.1:8000;
    }
    
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
    }
    
    location /health {
        proxy_pass http://backend/health;
        access_log off;
    }
}
"""

# Encode config as base64 for safe transmission
config_b64 = base64.b64encode(config_content.encode()).decode()

cmd = [
    r'C:\Program Files\PuTTY\plink.exe',
    '-i', r'C:\Users\Samandar\Desktop\Samandar.ppk',
    'ubuntu@13.49.73.105',
    f"echo '{config_b64}' | base64 -d | sudo tee /etc/nginx/sites-available/default > /dev/null && sudo nginx -t && sudo systemctl restart nginx && echo '✅ Nginx HTTPS configured'"
]

result = subprocess.run(cmd, shell=False, capture_output=True, text=True, timeout=30)
print(result.stdout)
if result.stderr:
    print("Stderr:", result.stderr[:200])
