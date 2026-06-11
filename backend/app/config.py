from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    sarvam_api_key: str = ""
    sarvam_base_url: str = "https://api.sarvam.ai"

    # Chat / LLM
    sarvam_chat_endpoint: str = "/v1/chat/completions"
    sarvam_chat_model: str = "sarvam-105b"          # sarvam-m is DEPRECATED

    # TTS  (Bulbul)
    sarvam_tts_endpoint: str = "/text-to-speech"

    # Document Intelligence  (Sarvam Vision — job-based, no simple endpoint)
    # The OCRService builds the job URLs itself from JOBS_ENDPOINT constants.
    # No single endpoint field needed here.

    max_image_size_mb: int = 10

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    return Settings()