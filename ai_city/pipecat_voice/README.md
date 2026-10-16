# Pipecat voice prototype for Godot AI City

This folder starts a separate real-time voice pipeline based on the architecture in the video: microphone audio → Pipecat → speech recognition → LLM → speech synthesis → audio back to the client.

## Avoid creating a new provider key

The PhoneAssistant project already uses Groq with model `openai/gpt-oss-20b`. This prototype is designed to reuse that **same existing Groq key** for all three stages:
- LLM: `openai/gpt-oss-20b`
- Speech recognition: `whisper-large-v3-turbo`
- Arabic speech: `canopylabs/orpheus-arabic-saudi`

No new Deepgram, Cartesia, Daily, or Jev keys are configured. Groq's Arabic TTS currently uses a Saudi dialect, so it may not sound Algerian. See the current [Groq TTS models](https://console.groq.com/docs/text-to-speech).

## Important limitation

Pipecat's WebRTC signaling and audio pipeline need a running Python server. This folder is a **browser-based voice prototype**, not yet a native Godot microphone client. The next integration step is to connect Godot's nearby-NPC selection, world state, and character actions to this running voice session. Do not treat the browser prototype alone as proof that the NPCs in the Godot scene already speak.

## Run on a computer or server

1. Install Python 3.12+ and `uv`.
2. From this folder, create the local configuration file `.env` from `.env.example`.
3. Paste the existing Groq key into `GROQ_API_KEY` in that local file only. **Never commit `.env` to GitHub.**
4. Install and run:
   ```bash
   uv sync
   uv run python server.py
   ```
5. Open `http://127.0.0.1:7860` in a browser and allow microphone access.

The server exposes `/health` for a basic status check. A working `/health` response only confirms the server is up; a successful spoken conversation is the real end-to-end test.

## Phone-only constraint

A GitHub repository cannot run a persistent microphone/WebRTC agent by itself. If you have only the Android phone, the backend must run on a reachable server or another device; otherwise the browser page cannot connect to a voice agent. This prototype does not secretly create or host a server.
