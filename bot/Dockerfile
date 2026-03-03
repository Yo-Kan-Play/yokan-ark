FROM docker.io/library/python:3.12-slim

WORKDIR /app

# Placeholder: add dependencies later (e.g. discord.py, pyyaml, podman client).
# COPY requirements.txt /app/requirements.txt
# RUN pip install --no-cache-dir -r /app/requirements.txt

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Source code placeholder (implement later)
COPY src/ /app/src/

ENV PYTHONUNBUFFERED=1
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
