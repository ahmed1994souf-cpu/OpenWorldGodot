# AI City

## Real-time voice NPC prototype

The first Pipecat voice bridge is in [`pipecat_voice/`](pipecat_voice/README.md).

It uses the existing Groq provider for STT + LLM + Arabic TTS, avoiding separate Deepgram/Cartesia/Daily credentials. This is a backend/browser proof of concept; the native Godot client and in-world NPC event bridge are still pending.
