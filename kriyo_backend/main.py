"""
Root entrypoint re-exporting FastAPI app from app.main.
Allows running: uvicorn main:app --host 0.0.0.0 --port 8000
"""

from app.main import app

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
