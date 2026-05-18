FROM python:3.11-slim

# Install MongoDB Community Edition (embedded in the same container so
# the backend has zero external DB dependencies — useful when no Atlas
# is available).
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        curl gnupg ca-certificates \
 && curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc \
        | gpg --dearmor -o /etc/apt/keyrings/mongodb-7.0.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/mongodb-7.0.gpg] \
http://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" \
        > /etc/apt/sources.list.d/mongodb-org-7.0.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends mongodb-org-server \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# MongoDB stores data in /data/db (ephemeral inside the container —
# fine for demo / thesis-defence purposes; resets on every redeploy).
RUN mkdir -p /data/db && chown -R nobody:nogroup /data/db

EXPOSE 8000

CMD ["sh", "/app/start.sh"]
