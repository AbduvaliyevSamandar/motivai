# Start from the official MongoDB image (Debian-based, mongod present)
# and add Python on top. This is the most reliable way to get MongoDB
# inside the same container without flaky apt key handling.
FROM mongo:7.0

# Install Python 3.11 + pip via Debian repos (the base is Debian 12).
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv \
        ca-certificates curl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# pydantic-core etc. install cleanly via pip on Debian 12 / Python 3.11.
ENV PIP_BREAK_SYSTEM_PACKAGES=1

WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

# MongoDB stores data in /data/db (created by the base image).
EXPOSE 8000

# Override the base image's mongod entrypoint with our supervisor.
ENTRYPOINT []
CMD ["sh", "/app/start.sh"]
