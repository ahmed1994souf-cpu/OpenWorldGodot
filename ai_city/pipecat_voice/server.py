"""SmallWebRTC signaling server for the Pipecat voice prototype."""

from __future__ import annotations

import os
from contextlib import asynccontextmanager
from pathlib import Path

import uvicorn
from dotenv import load_dotenv
from fastapi import BackgroundTasks, FastAPI
from fastapi.responses import FileResponse
from pipecat.transports.smallwebrtc.request_handler import (
    SmallWebRTCPatchRequest,
    SmallWebRTCRequest,
    SmallWebRTCRequestHandler,
)

from bot import run_bot

ROOT = Path(__file__).resolve().parent
load_dotenv(ROOT / ".env", override=False)
handler = SmallWebRTCRequestHandler()


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    await handler.close()


app = FastAPI(title="Godot AI City Pipecat Voice", lifespan=lifespan)


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "voice_engine": "Pipecat",
        "llm_model": os.getenv("GROQ_LLM_MODEL", "openai/gpt-oss-20b"),
        "key_configured": bool(os.getenv("GROQ_API_KEY", "").strip()),
    }


@app.post("/api/offer")
async def offer(request: SmallWebRTCRequest, background_tasks: BackgroundTasks):
    async def connection_callback(connection):
        background_tasks.add_task(run_bot_for_connection, connection)

    return await handler.handle_web_request(
        request=request,
        webrtc_connection_callback=connection_callback,
    )


async def run_bot_for_connection(connection):
    # The request handler creates a SmallWebRTCConnection; use Pipecat's standard
    # runner transport adapter so audio stays on WebRTC rather than HTTP chunks.
    from types import SimpleNamespace
    from pipecat.transports.smallwebrtc.transport import SmallWebRTCTransport
    from pipecat.transports.base_transport import TransportParams

    transport = SmallWebRTCTransport(
        webrtc_connection=connection,
        params=TransportParams(audio_in_enabled=True, audio_out_enabled=True),
    )
    # Runner arguments are normally created by the CLI. This direct web endpoint
    # is deliberately kept separate until the Godot-native client is connected.
    await run_bot(
        transport,
        SimpleNamespace(handle_sigint=False, pipeline_idle_timeout_secs=300),
    )


@app.patch("/api/offer")
async def patch_offer(request: SmallWebRTCPatchRequest):
    await handler.handle_patch_request(request)
    return {"status": "success"}


@app.get("/")
async def index():
    return FileResponse(ROOT / "index.html")


if __name__ == "__main__":
    uvicorn.run(
        "server:app",
        host=os.getenv("VOICE_HOST", "0.0.0.0"),
        port=int(os.getenv("VOICE_PORT", "7860")),
        reload=False,
    )
