# 🩺 MediVoice AI

> Prescription understanding assistant application built with Flutter and Python with **Sarvam AI**.

Upload or capture a doctor's prescription → get clear medicine explanations → listen in **Hindi or English**.

## App Architecture

```
medivoice_ai/
├── backend/                      # Python FastAPI backend
│   ├── app/
│   │   ├── main.py               # FastAPI app entry
│   │   ├── config.py             # Environment settings
│   │   ├── routers/
│   │   │   └── prescription.py   # API endpoints
│   │   ├── services/
│   │   │   ├── ocr_service.py   
│   │   │   ├── llm_service.py   
│   │   │   └── tts_service.py    
│   │   └── models/
│   │       └── prescription.py   # Response schemas
│   ├── requirements.txt
│   ├── .env.example
│   └── run.py
│
├── flutter_app/                  # Flutter Mobile App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── theme.dart            # Colors, typography, gradients
│   │   ├── models/
│   │   │   └── prescription.dart
│   │   ├── services/
│   │   │   ├── api_service.dart  # HTTP client for backend
│   │   │   └── audio_service.dart
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── image_preview_screen.dart
│   │   │   ├── analysis_screen.dart
│   │   │   └── results_screen.dart
│   │   └── widgets/
│   │       └── medication_card.dart
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
└── README.md

```
## Core Workflow

```
User captures/uploads prescription image
        ↓
[POST /api/v1/analyze-prescription]
        ↓
OCR Service → Sarvam sarvam-105b (/v1/chat/completions)
  • Image encoded as base64
  • Sent as a text prompt to the chat API
  • Model extracts all prescription text (medicine names, dosages,
    frequencies, durations, doctor notes, abbreviations)
        ↓
LLM Service → Sarvam sarvam-105b (/v1/chat/completions)
  • Expands abbreviations (BD→Twice daily, OD→Once daily, etc.)
  • Generates patient-friendly purpose descriptions
  • Returns structured JSON with medication details
        ↓
Flutter displays medication cards
        ↓
[POST /api/v1/prescription-tts  OR  /api/v1/text-to-speech]
        ↓
TTS Service → Sarvam Bulbul v1 (/v1/text-to-speech)
  • Builds a spoken summary from the structured JSON
  • Returns base64-encoded WAV audio
        ↓
Flutter writes WAV to a temp file and plays it via just_audio (Hindi or English)
```
---

## Sarvam AI Models Used

| Task | Model / API | Notes |
|------|-------------|-------|
| Vision OCR | Sarvam Document Intelligence | Async job pipeline — presigned Azure upload |
| LLM Analysis | `sarvam-105b` | Parses medications, expands abbreviations, generates explanations |
| Text-to-Speech | `bulbul:v1` | Hindi (`meera` voice) and English (`arvind` voice) |

---
## Quick Start Guide

```bash
# 1. Clone the repo
git clone https://github.com/Devkalra/Medivoice_AI.git
cd Medivoice_AI

# 2. Backend setup
cd backend
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # Mac/Linux
pip install -r requirements.txt
cp .env.example .env
# Edit .env → set your SARVAM_API_KEY

# 3. Start backend
python run.py
# API docs: http://localhost:8000/docs

# 4. Flutter (in a new terminal)
cd ../flutter_app
flutter pub get
flutter run
```


## Safety & Disclaimer

MediVoice AI is designed to **help patients understand** their prescriptions, not to provide medical advice. Every response includes a disclaimer reminding users to follow their doctor's instructions.

---
## 📖 Read More

Built this project and wrote about the journey : the challenges, the debugging, and the idea behind it.

Medium Article: [Is Your Doctor's Handwriting a Mystery? I Built an AI to Decode It](https://medium.com/@kalradev50/is-your-doctors-handwriting-a-mystery-i-built-an-ai-to-decode-it-bc9e4be977cf)

### Shoutout to Resources: 
* Sarvam AI: Documentation : https://docs.sarvam.ai
* Flutter: Documentation: https://docs.flutter.dev/
