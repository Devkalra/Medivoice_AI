import httpx
import logging
from app.config import get_settings
from app.models.prescription import TTSResponse, PrescriptionResponse

logger = logging.getLogger(__name__)

# Sarvam TTS character limit per request
MAX_CHARS = 500


def build_tts_text(prescription: PrescriptionResponse, language: str) -> str:
    """Build a human-friendly spoken summary from prescription data."""
    if language == "hi-IN":
        lines = [f"आपकी दवाइयों की जानकारी। {prescription.patient_summary}"]
        for i, med in enumerate(prescription.medications, 1):
            lines.append(
                f"दवाई नंबर {i}: {med.name}। "
                f"खुराक: {med.dosage}। "
                f"कब लें: {med.frequency}। "
                f"कितने दिन: {med.duration}। "
                f"यह दवाई क्यों है: {med.purpose}। "
                f"विशेष निर्देश: {med.instructions}।"
            )
        lines.append(
            "सावधानी: यह जानकारी केवल समझने के लिए है। "
            "अपने डॉक्टर की सलाह का पालन करें।"
        )
    else:
        lines = [f"Here is your prescription summary. {prescription.patient_summary}"]
        for i, med in enumerate(prescription.medications, 1):
            lines.append(
                f"Medicine {i}: {med.name}. "
                f"Dosage: {med.dosage}. "
                f"Frequency: {med.frequency}. "
                f"Duration: {med.duration}. "
                f"Purpose: {med.purpose}. "
                f"Instructions: {med.instructions}."
            )
        lines.append(
            "Disclaimer: This information is for understanding purposes only. "
            "Always follow your doctor's advice."
        )
    return " ".join(lines)


class TTSService:
    def __init__(self):
        self.settings = get_settings()

    def _headers(self) -> dict:
        return {
            "Authorization": f"Bearer {self.settings.sarvam_api_key}",
            "Content-Type": "application/json",
        }

    async def synthesize_speech(
        self, prescription: PrescriptionResponse, language: str = "hi-IN"
    ) -> TTSResponse:
        """
        Convert prescription summary to speech using Sarvam Bulbul TTS.
        Supported languages: hi-IN (Hindi), en-IN (Indian English)
        Auth: api-subscription-key header
        """
        text = build_tts_text(prescription, language)
        return await self._call_tts(text[:MAX_CHARS], language)

    async def synthesize_text(self, text: str, language: str = "hi-IN") -> TTSResponse:
        """Convert arbitrary text to speech (used for per-card listen buttons)."""
        return await self._call_tts(text[:MAX_CHARS], language)

    async def _call_tts(self, text: str, language: str) -> TTSResponse:
        """
        Sarvam Bulbul TTS REST call.
        POST https://api.sarvam.ai/text-to-speech
        Returns audios[] array of base64-encoded WAV strings.
        """
        # Speaker selection — meera (female) for Hindi, arvind (male) for English
        # Full speaker list: meera, pavithra, maitreyi, arvind, amol, amartya,
        #                    diya, neel, misha, vian, arjun, maya
        speaker = "priya" if language == "hi-IN" else "shubh"

        payload = {
            "inputs": [text],
            "target_language_code": language,
            "speaker": speaker,
            "pace": 1.0,
            "speech_sample_rate": 22050,
            "enable_preprocessing": True,
            "model": "bulbul:v3",
        }

        url = f"{self.settings.sarvam_base_url}{self.settings.sarvam_tts_endpoint}"
        print("\n========== TTS DEBUG ==========")
        print("URL:", url)
        print("LANGUAGE:", language)
        print("PAYLOAD:", payload)

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(url, headers=self._headers(), json=payload)
            print("STATUS:", response.status_code)
            print("BODY:", response.text)
            response.raise_for_status()
            data = response.json()

        # Response: { "audios": ["<base64_wav_string>", ...] }
        audio_base64 = data.get("audios", [""])[0]
        if not audio_base64:
            raise ValueError("Sarvam TTS returned an empty audio payload.")

        return TTSResponse(success=True, audio_base64=audio_base64)