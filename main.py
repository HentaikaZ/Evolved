from fastapi import FastAPI
from typing import Dict
import uvicorn

app = FastAPI()

# База ключей + HWID
valid_keys: Dict[str, str] = {
    "TEST-KEY-123": "E1A2B3C4-1234-5678-9ABC-DEF012345678",
    "TEST-KEY-456": "D4F5G6H7-8765-4321-9XYZ-9876543210AB"
}

@app.get("/check")
def check_access(hwid: str, key: str):
    if valid_keys.get(key) == hwid:
        return "VALID"
    return "INVALID"

# Запуск сервера (локально)
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
