import httpx
import asyncio
import zipfile
import io
import json
import logging

from app.config import get_settings

logger = logging.getLogger(__name__)

# ── Confirmed API endpoints from docs.sarvam.ai/api-reference-docs/document-intelligence ──
# Base:            https://api.sarvam.ai
# Create job:      POST  /doc-digitization/job/v1
# Get upload URLs: POST  /doc-digitization/job/v1/upload-files
# Start job:       POST  /doc-digitization/job/v1/{job_id}/start
# Poll status:     GET   /doc-digitization/job/v1/{job_id}/status
# Get download:    POST  /doc-digitization/job/v1/{job_id}/download-files

BASE_PATH       = "/doc-digitization/job/v1"
UPLOAD_PATH     = "/doc-digitization/job/v1/upload-files"
START_PATH      = "/doc-digitization/job/v1/{job_id}/start"
STATUS_PATH     = "/doc-digitization/job/v1/{job_id}/status"
DOWNLOAD_PATH   = "/doc-digitization/job/v1/{job_id}/download-files"

POLL_INTERVAL_SEC = 4
MAX_WAIT_SEC      = 180
TERMINAL_STATES   = {"Completed", "PartiallyCompleted", "Failed"}


class OCRService:
    def __init__(self):
        self.settings = get_settings()

    def _headers(self, content_type: str | None = "application/json") -> dict:
        h = {"api-subscription-key": self.settings.sarvam_api_key}
        if content_type:
            h["Content-Type"] = content_type
        return h

    def _url(self, path: str) -> str:
        return f"{self.settings.sarvam_base_url}{path}"

    async def extract_text_from_image(
        self, image_bytes: bytes, media_type: str = "image/jpeg"
    ) -> str:
        """
        Extract text from a prescription image using Sarvam Vision
        (Document Intelligence — presigned-URL upload pipeline).

        Real flow (confirmed from live API docs):
          1. POST /doc-digitization/job/v1
             → { job_id, ... }

          2. POST /doc-digitization/job/v1/upload-files
             body: { job_id, files: ["prescription.jpg"] }
             → { upload_urls: { "prescription.jpg": { file_url, ... } } }

          3. PUT  <presigned_url>   (direct Azure Blob upload — no auth header)
             body: raw image bytes

          4. POST /doc-digitization/job/v1/{job_id}/start
             → job kicks off asynchronously

          5. GET  /doc-digitization/job/v1/{job_id}/status
             poll until job_state in { Completed, PartiallyCompleted, Failed }

          6. POST /doc-digitization/job/v1/{job_id}/download-files
             → { download_urls: { "file.json": { file_url } } }

          7. GET  <presigned download url>
             → ZIP/JSON bytes  → extract text
        """
        ext = _ext_from_media_type(media_type)
        filename = f"prescription.{ext}"

        async with httpx.AsyncClient(timeout=60.0) as client:

            # ── Step 1: Create job ────────────────────────────────────────
            r1 = await client.post(
                self._url(BASE_PATH),
                headers=self._headers(),
                json={"job_parameters": {"language": "en-IN", "output_format": "md"}},
            )
            _raise(r1, "Create job")
            job_id: str = r1.json()["job_id"]
            logger.info(f"[OCR] Job created: {job_id}")

            # ── Step 2: Get presigned upload URL ──────────────────────────
            r2 = await client.post(
                self._url(UPLOAD_PATH),
                headers=self._headers(),
                json={"job_id": job_id, "files": [filename]},
            )
            _raise(r2, "Get upload URL")
            upload_info = r2.json()["upload_urls"][filename]
            # upload_info has "file_url" (and optionally "headers")
            presigned_upload_url = upload_info["file_url"]
            presigned_upload_headers = upload_info.get("headers", {})
            logger.info(f"[OCR] Got presigned upload URL for {filename}")

            # ── Step 3: Upload image to presigned URL (Azure Blob) ────────
            # Must NOT include api-subscription-key here — it's a presigned URL
            blob_headers = {
                "Content-Type": media_type,
                "x-ms-blob-type": "BlockBlob",  # required for Azure Blob Storage
                **presigned_upload_headers,
            }
            r3 = await client.put(
                presigned_upload_url,
                headers=blob_headers,
                content=image_bytes,
                timeout=120.0,
            )
            _raise(r3, "Upload to presigned URL")
            logger.info(f"[OCR] Image uploaded ({len(image_bytes)} bytes)")

            # ── Step 4: Start the job ─────────────────────────────────────
            r4 = await client.post(
                self._url(START_PATH.format(job_id=job_id)),
                headers=self._headers(),
                json={},
            )
            _raise(r4, "Start job")
            logger.info(f"[OCR] Job {job_id} started")

        # ── Step 5: Poll status ───────────────────────────────────────────
        job_state = "Running"
        elapsed = 0

        async with httpx.AsyncClient(timeout=30.0) as poll_client:
            while job_state not in TERMINAL_STATES and elapsed < MAX_WAIT_SEC:
                await asyncio.sleep(POLL_INTERVAL_SEC)
                elapsed += POLL_INTERVAL_SEC

                rs = await poll_client.get(
                    self._url(STATUS_PATH.format(job_id=job_id)),
                    headers=self._headers(content_type=None),
                )
                _raise(rs, "Poll status")
                job_state = rs.json().get("job_state", "Running")
                logger.info(f"[OCR] Job {job_id} state={job_state} ({elapsed}s)")

        if job_state == "Failed":
            raise RuntimeError(
                f"Sarvam Vision job {job_id} failed. "
                "Check the image quality and your API key/credits."
            )
        if elapsed >= MAX_WAIT_SEC and job_state not in TERMINAL_STATES:
            raise RuntimeError(
                f"Sarvam Vision job {job_id} timed out after {MAX_WAIT_SEC}s."
            )

        # ── Step 6: Get presigned download URLs ───────────────────────────
        async with httpx.AsyncClient(timeout=30.0) as dl_client:
            r6 = await dl_client.post(
                self._url(DOWNLOAD_PATH.format(job_id=job_id)),
                headers=self._headers(),
                json={},
            )
            _raise(r6, "Get download URLs")
            download_urls: dict = r6.json().get("download_urls", {})
            logger.info(
    f"[OCR] Download response: {json.dumps(r6.json(), indent=2)}"
)
            logger.info(f"[OCR] Download URLs: {list(download_urls.keys())}")

            # ── Step 7: Download each output file and extract text ────────
            all_text_parts: list[str] = []

            for fname, url_info in download_urls.items():
                file_url = url_info["file_url"]
                r7 = await dl_client.get(file_url, timeout=60.0)
                _raise(r7, f"Download {fname}")

                text = _extract_text_from_bytes(fname, r7.content)
                if text:
                    all_text_parts.append(text)
                    logger.info(f"[OCR] Extracted {len(text)} chars from {fname}")

        if not all_text_parts:
            raise ValueError(
                "Sarvam Vision returned no text. "
                "Ensure the prescription image is clear and well-lit."
            )

        return "\n\n".join(all_text_parts)


# ── Helpers ───────────────────────────────────────────────────────────────────

def _raise(response: httpx.Response, step: str) -> None:
    """Raise with a helpful message including the response body."""
    if response.is_error:
        try:
            body = response.json()
        except Exception:
            body = response.text[:400]
        raise httpx.HTTPStatusError(
            f"[{step}] HTTP {response.status_code}: {body}",
            request=response.request,
            response=response,
        )


def _ext_from_media_type(media_type: str) -> str:
    if "png" in media_type:
        return "png"
    if "webp" in media_type:
        return "webp"
    return "jpg"


def _extract_text_from_bytes(filename: str, data: bytes) -> str:
    """
    Handle both ZIP archives and bare JSON/text files returned by Sarvam.
    Output format is 'json' so we expect JSON files, possibly inside a ZIP.
    """
    fname_lower = filename.lower()

    # Case A: ZIP archive — look inside for JSON or MD
    if fname_lower.endswith(".zip"):
        return _extract_from_zip(data)

    # Case B: JSON file
    if fname_lower.endswith(".json"):
        return _extract_from_json(data)

    # Case C: Markdown / plain text
    if fname_lower.endswith((".md", ".txt")):
        return data.decode("utf-8", errors="replace").strip()

    # Case D: HTML
    if fname_lower.endswith(".html"):
        import re
        text = data.decode("utf-8", errors="replace")
        text = re.sub(r"<(script|style)[^>]*>.*?</\1>", "", text, flags=re.S)
        text = re.sub(r"<[^>]+>", " ", text)
        return re.sub(r"\s+", " ", text).strip()

    # Fallback: try UTF-8
    try:
        return data.decode("utf-8", errors="replace").strip()
    except Exception:
        return ""


def _extract_from_zip(data: bytes) -> str:
    parts: list[str] = []
    with zipfile.ZipFile(io.BytesIO(data)) as zf:
        names = zf.namelist()
        logger.info(f"[OCR] ZIP contents: {names}")
        # Priority: json > md > html
        for ext in (".md", ".html", ".txt",".json"):
            matches = sorted(n for n in names if n.lower().endswith(ext))
            for name in matches:
                text = _extract_text_from_bytes(name, zf.read(name))
                if text:
                    parts.append(text)
            if parts:
                break
    return "\n\n".join(parts)


def _extract_from_json(data: bytes) -> str:
    """
    Sarvam JSON output format (observed from SDK):
    { "pages": [ { "text": "...", ... }, ... ] }
    or a list of page objects.
    """
    try:
        obj = json.loads(data.decode("utf-8", errors="replace"))
    except json.JSONDecodeError as e:
        logger.warning(f"[OCR] JSON decode failed: {e}")
        return data.decode("utf-8", errors="replace").strip()

    parts: list[str] = []

    # List of pages
    pages = obj if isinstance(obj, list) else obj.get("pages", [])
    for page in pages:
        if isinstance(page, dict):
            for key in ("text", "markdown", "content", "html"):
                val = page.get(key, "")
                if val:
                    parts.append(str(val))
                    break

    # Flat "text" field at top level
    if not parts and isinstance(obj, dict):
        for key in ("text", "markdown", "content"):
            val = obj.get(key, "")
            if val:
                parts.append(str(val))
                break

    return "\n\n".join(parts)
