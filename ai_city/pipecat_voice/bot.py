"""Pipecat real-time voice pipeline for Godot AI City.

Uses the same single Groq key for speech-to-text, the LLM, and speech output.
No Deepgram, Cartesia, Daily, or Jev account is needed for this first prototype.
"""

from __future__ import annotations

import os

from loguru import logger
from pipecat.audio.vad.silero import SileroVADAnalyzer
from pipecat.frames.frames import LLMRunFrame
from pipecat.pipeline.pipeline import Pipeline
from pipecat.pipeline.worker import PipelineParams, PipelineWorker
from pipecat.processors.aggregators.llm_context import LLMContext
from pipecat.processors.aggregators.llm_response_universal import (
    LLMContextAggregatorPair,
    LLMUserAggregatorParams,
)
from pipecat.runner.types import RunnerArguments
from pipecat.runner.utils import create_transport
from pipecat.services.groq.llm import GroqLLMService
from pipecat.services.groq.stt import GroqSTTService
from pipecat.services.groq.tts import GroqTTSService
from pipecat.transports.base_transport import BaseTransport, TransportParams
from pipecat.workers.runner import WorkerRunner


VOICE_SYSTEM = """
You are a living character in a 3D Godot game. Speak naturally, warmly, and briefly.
Respond in the language the player uses, including Arabic when the player speaks Arabic.
Stay in character. Do not claim to perform an in-game action unless the game confirms it.
Do not use markdown, lists, emojis, or stage directions in spoken replies.
"""


async def run_bot(transport: BaseTransport, runner_args: RunnerArguments) -> None:
    api_key = os.getenv("GROQ_API_KEY", "").strip()
    if not api_key:
        raise RuntimeError(
            "GROQ_API_KEY is missing. Reuse your existing PhoneAssistant Groq key "
            "in this server's local .env file; do not commit it to GitHub."
        )

    llm = GroqLLMService(
        api_key=api_key,
        settings=GroqLLMService.Settings(
            model=os.getenv("GROQ_LLM_MODEL", "openai/gpt-oss-20b"),
            system_instruction=VOICE_SYSTEM,
            temperature=0.7,
            max_completion_tokens=300,
        ),
    )
    stt = GroqSTTService(
        api_key=api_key,
        settings=GroqSTTService.Settings(
            model=os.getenv("GROQ_STT_MODEL", "whisper-large-v3-turbo"),
            language=None,
        ),
    )
    # Current Groq Arabic speech model; default output is WAV at 24 kHz.
    tts = GroqTTSService(
        api_key=api_key,
        settings=GroqTTSService.Settings(
            model=os.getenv("GROQ_TTS_MODEL", "canopylabs/orpheus-arabic-saudi"),
            voice=os.getenv("GROQ_TTS_VOICE", "fahad"),
            language="ar",
        ),
    )

    context = LLMContext()
    user_aggregator, assistant_aggregator = LLMContextAggregatorPair(
        context,
        user_params=LLMUserAggregatorParams(vad_analyzer=SileroVADAnalyzer()),
    )
    pipeline = Pipeline(
        [
            transport.input(),
            stt,
            user_aggregator,
            llm,
            tts,
            transport.output(),
            assistant_aggregator,
        ]
    )
    worker = PipelineWorker(
        pipeline,
        params=PipelineParams(enable_metrics=True, enable_usage_metrics=True),
        idle_timeout_secs=runner_args.pipeline_idle_timeout_secs,
    )
    runner = WorkerRunner(handle_sigint=runner_args.handle_sigint)

    @transport.event_handler("on_client_connected")
    async def on_client_connected(transport, client):
        logger.info("Voice client connected")
        context.add_message(
            {
                "role": "user",
                "content": "ابدأ بتحية قصيرة للاعب وادعُه إلى التحدث معك.",
            }
        )
        await worker.queue_frames([LLMRunFrame()])

    @transport.event_handler("on_client_disconnected")
    async def on_client_disconnected(transport, client):
        logger.info("Voice client disconnected")
        await runner.cancel()

    await runner.add_workers(worker)
    await runner.run()


async def bot(runner_args: RunnerArguments) -> None:
    transport = await create_transport(
        runner_args,
        {
            "webrtc": lambda: TransportParams(
                audio_in_enabled=True,
                audio_out_enabled=True,
            ),
        },
    )
    await run_bot(transport, runner_args)


if __name__ == "__main__":
    from pipecat.runner.run import main

    main()
