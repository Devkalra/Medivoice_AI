import logging
from fastapi import APIRouter, File, UploadFile, HTTPException, Depends, Query
from app.models.prescription import PrescriptionResponse, TTSRequest, TTSResponse
from app.services.ocr_service import OCRService
from app.services.llm_service import LLMService
from app.services.tts_service import TTSService
from app.config import get_settings, Settings

logger = logging.getLogger(__name__)
router = APIRouter()

ALLOWED_CONTENT_TYPES = {
    "image/jpeg", "image/jpg", "image/png", "image/webp",
    "image/heic", "image/heif",
}


def get_ocr_service() -> OCRService:  return OCRService()
def get_llm_service() -> LLMService:  return LLMService()
def get_tts_service() -> TTSService:  return TTSService()


# ─── Analyze prescription ─────────────────────────────────────────────────────

@router.post("/analyze-prescription", response_model=PrescriptionResponse)
async def analyze_prescription(
    file: UploadFile = File(...),
    settings: Settings = Depends(get_settings),
    ocr: OCRService = Depends(get_ocr_service),
    llm: LLMService = Depends(get_llm_service),
):
    """
    Full pipeline:
      1. Upload image
      2. Sarvam Vision Document Intelligence (OCR)  → raw text
      3. Sarvam 105B chat                           → structured JSON
    """
    content_type = (file.content_type or "").lower()
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type '{content_type}'. Please upload JPEG, PNG, or WebP.",
        )

    image_bytes = await file.read()
    size_mb = len(image_bytes) / (1024 * 1024)
    if size_mb > settings.max_image_size_mb:
        raise HTTPException(
            status_code=400,
            detail=f"Image too large ({size_mb:.1f} MB). Max: {settings.max_image_size_mb} MB.",
        )

    logger.info(f"Analyzing prescription: {file.filename} ({size_mb:.2f} MB)")

    # Step 1: OCR via Sarvam Vision Document Intelligence
    try:
        ocr_text = await ocr.extract_text_from_image(image_bytes, content_type)
    except Exception as e:
        logger.error(f"OCR failed: {e}", exc_info=True)
        raise HTTPException(status_code=502, detail=f"OCR processing failed: {e}")

    if not ocr_text or len(ocr_text.strip()) < 10:
        raise HTTPException(
            status_code=422,
            detail=(
                "Could not extract readable text from the image. "
                "Please ensure the prescription is clear, well-lit, and fully in frame."
            ),
        )

    # Step 2: LLM analysis via Sarvam 105B
    try:
        return await llm.analyze_prescription(ocr_text)
    except Exception as e:
        logger.error(f"LLM analysis failed: {e}", exc_info=True)
        raise HTTPException(status_code=502, detail=f"AI analysis failed: {e}")


# ─── Text-to-speech (single text string) ─────────────────────────────────────

@router.post("/text-to-speech", response_model=TTSResponse)
async def text_to_speech(
    request: TTSRequest,
    tts: TTSService = Depends(get_tts_service),
):
    """Convert arbitrary text to speech (used for per-card listen buttons)."""
    if not request.text.strip():
        raise HTTPException(status_code=400, detail="Text cannot be empty.")
    try:
        return await tts.synthesize_text(request.text, request.language)
    except Exception as e:
        logger.error(f"TTS failed: {e}", exc_info=True)
        raise HTTPException(status_code=502, detail=f"Text-to-speech failed: {e}")


# ─── Text-to-speech (full prescription) ──────────────────────────────────────

@router.post("/prescription-tts", response_model=TTSResponse)
async def prescription_tts(
    prescription: PrescriptionResponse,
    language: str = Query(default="hi-IN", description="hi-IN or en-IN"),
    tts: TTSService = Depends(get_tts_service),
):
    """Convert a full PrescriptionResponse object to speech."""
    try:
        return await tts.synthesize_speech(prescription, language)
    except Exception as e:
        logger.error(f"Prescription TTS failed: {e}", exc_info=True)
        raise HTTPException(status_code=502, detail=f"Text-to-speech failed: {e}")