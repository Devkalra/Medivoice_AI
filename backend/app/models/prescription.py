from pydantic import BaseModel
from typing import List, Optional


class Medication(BaseModel):
    name: str
    dosage: str
    frequency: str
    duration: str
    purpose: str
    instructions: str


class PrescriptionResponse(BaseModel):
    success: bool
    patient_summary: str
    medications: List[Medication]
    disclaimer: Optional[str] = (
        "This information is for educational purposes only. "
        "Always follow your doctor's advice and consult a healthcare professional for medical decisions."
    )
    raw_ocr_text: Optional[str] = None


class TTSRequest(BaseModel):
    text: str
    language: str = "hi-IN"  # hi-IN for Hindi, en-IN for Indian English


class TTSResponse(BaseModel):
    success: bool
    audio_base64: Optional[str] = None
    error: Optional[str] = None
