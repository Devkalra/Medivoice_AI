#!/usr/bin/env python3
"""
MediVoice AI — FastAPI Backend
Run: python run.py  OR  uvicorn app.main:app --reload
"""
import uvicorn

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info",
    )
