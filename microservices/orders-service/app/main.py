from fastapi import FastAPI

app = FastAPI(title="orders-service")

ORDERS = [
    {"id": "ord-001", "item": "terraform", "status": "prepared"},
    {"id": "ord-002", "item": "cloudformation", "status": "prepared"},
]


@app.get("/health")
def health():
    return {"status": "ok", "service": "orders-service"}


@app.get("/orders")
def list_orders():
    return {"orders": ORDERS}
