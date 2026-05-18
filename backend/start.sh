#!/bin/sh
# Render start script. Launch an embedded MongoDB in the background,
# then start the FastAPI app in the foreground (Render needs the
# foreground process bound to $PORT).
set -e

mkdir -p /data/db

# WiredTiger cache sized for ~256 MB so Python + uvicorn + Mongo fit
# inside the 512 MB free-tier RAM ceiling.
mongod --dbpath /data/db --bind_ip 127.0.0.1 --port 27017 \
       --wiredTigerCacheSizeGB 0.25 \
       --logpath /tmp/mongod.log --fork

# Probe until the socket is ready (up to ~30 s).
python3 - <<'PY'
import socket, time, sys
for _ in range(60):
    try:
        s = socket.create_connection(("127.0.0.1", 27017), timeout=1)
        s.close()
        print("mongod ready", flush=True)
        sys.exit(0)
    except OSError:
        time.sleep(0.5)
print("mongod did not become ready in 30s — continuing anyway", flush=True)
PY

exec uvicorn main:app --host 0.0.0.0 --port "${PORT:-8000}"
