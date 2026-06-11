import httpx
import json
import logging
import re
from app.config import get_settings
from app.models.prescription import Medication, PrescriptionResponse

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = """You are MediVoice AI, a compassionate medical assistant designed to help Indian patients understand their prescriptions in simple language.

Your responsibilities:
1. EXTRACT all medication details from the prescription text.
2. EXPAND all medical abbreviations into plain language:
   - OD / QD = Once daily
   - BD / BID = Twice daily
   - TDS / TID = Three times daily
   - QID = Four times daily
   - HS = At bedtime
   - SOS / PRN = As needed
   - AC = Before food
   - PC = After food
   - TAB = Tablet
   - CAP = Capsule
   - INJ = Injection
   - SYP = Syrup
   - mg = milligram, mcg = microgram, ml = millilitre
3. GENERATE patient-friendly explanations for each medicine's purpose.
4. DO NOT make any diagnosis or suggest changing the doctor's prescription.
5. Use simple, warm, reassuring language that a non-medical person can understand.
6. Always include a safety disclaimer.

IMPORTANT: You MUST respond with ONLY valid JSON. No markdown, no explanation, no code fences.

Output format:
{
  "patient_summary": "A warm 2-3 sentence overview of the prescription in simple terms",
  "medications": [
    {
      "name": "Full medicine name with strength",
      "dosage": "e.g., 1 tablet, 5ml, 2 capsules",
      "frequency": "Expanded frequency in plain English",
      "duration": "e.g., 5 days, 2 weeks, 1 month",
      "purpose": "Simple explanation of what this medicine does — avoid technical jargon",
      "instructions": "When/how to take it, food interactions, storage if mentioned"
    }
  ]
}"""

EXTRACTION_PROMPT_TEMPLATE = """Here is the OCR-extracted text from a prescription:

---
{ocr_text}
---

Extract all medication information and return valid JSON only. If a field is not mentioned in the prescription, use a sensible default like "As prescribed by doctor" or "As directed". Generate helpful, patient-friendly purpose descriptions based on your medical knowledge of each drug."""


class LLMService:
    def __init__(self):
        self.settings = get_settings()

    async def analyze_prescription(self, ocr_text: str) -> PrescriptionResponse:
        """
        Send OCR text to Sarvam 105B and get structured medication data.
        Model: sarvam-105b  (sarvam-m is deprecated)
        Auth:  api-subscription-key header (NOT Bearer token)
        """
        headers = {
            "Authorization": f"Bearer {self.settings.sarvam_api_key}",
            "Content-Type": "application/json",
        }

        payload = {
            "model": self.settings.sarvam_chat_model,  # sarvam-105b in .env
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {
                    "role": "user",
                    "content": EXTRACTION_PROMPT_TEMPLATE.format(ocr_text=ocr_text),
                },
            ],
            "max_tokens": 3000,
            "temperature": 0.1,
        }

        url = f"{self.settings.sarvam_base_url}{self.settings.sarvam_chat_endpoint}"

        print("BASE URL =", self.settings.sarvam_base_url)
        print("CHAT ENDPOINT =", self.settings.sarvam_chat_endpoint)
        print("MODEL =", self.settings.sarvam_chat_model)
        print("KEY PREFIX =", self.settings.sarvam_api_key[:10])

        async with httpx.AsyncClient(timeout=90.0) as client:
            print("\n========== HEADERS SENT ==========")
            print(headers)
            print("\n========== PAYLOAD SENT ==========")
            print(json.dumps(payload, indent=2))
            
            response = await client.post(
                url,
                headers=headers,
                json=payload
            )
            print("\n========== LLM DEBUG ==========")
            print("URL:", url)
            print("MODEL:", self.settings.sarvam_chat_model)
            print("STATUS:", response.status_code)
            print("BODY:", response.text)
            print("================================\n")

            response.raise_for_status()
            data = response.json()

        raw_content = data["choices"][0]["message"]["content"].strip()
        logger.info(f"LLM response: {len(raw_content)} chars")

        # Strip markdown code fences if the model adds them despite instructions
        clean_content = re.sub(r"```(?:json)?\s*|\s*```", "", raw_content).strip()

        parsed = json.loads(clean_content)
        medications = [Medication(**med) for med in parsed.get("medications", [])]

        return PrescriptionResponse(
            success=True,
            patient_summary=parsed.get(
                "patient_summary", "Your prescription has been analyzed successfully."
            ),
            medications=medications,
            raw_ocr_text=ocr_text,
        )