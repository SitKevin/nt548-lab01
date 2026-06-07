import os

import httpx
from fastapi import FastAPI

app = FastAPI(title="api-gateway")
ORDERS_SERVICE_URL = os.getenv("ORDERS_SERVICE_URL", "http://orders-service:8000")


@app.get("/health")
def health():
    return {"status": "ok", "service": "api-gateway"}


@app.get("/orders")
def orders():
    with httpx.Client(timeout=5.0) as client:
        response = client.get(f"{ORDERS_SERVICE_URL}/orders")
        response.raise_for_status()
        return response.json()
