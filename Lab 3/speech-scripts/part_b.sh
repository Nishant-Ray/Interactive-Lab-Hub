#!/usr/bin/env bash
# Place beside transcribe.py, with your virtual environment activated.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VOICES_DIR="$SCRIPT_DIR/../voices"
QUESTION="${1:-Hi there, what is your zip code?}"

RECORDING_DIR="$(mktemp -d)"
trap 'rm -rf -- "$RECORDING_DIR"' EXIT

if [[ ! -f "$SCRIPT_DIR/transcribe.py" ]]; then
    echo "Error: place this script beside transcribe.py." >&2
    exit 1
fi

echo "Question: $QUESTION"
python3 -m piper \
    --model en_US-kusal-medium \
    --data-dir "$VOICES_DIR" \
    --output-raw \
    -- "$QUESTION" \
    | aplay -r 22050 -f S16_LE -t raw -

# Playback finishes before recording starts.
echo "Speak now! Recording for 5 seconds..."
arecord -d 5 -f S16_LE -c 1 -r 16000 "$RECORDING_DIR/response.wav"

echo "Transcribing your response..."
OUTPUT=$(python3 "$SCRIPT_DIR/transcribe.py" \
    "$RECORDING_DIR/response.wav" --model base.en)
TRANSCRIPT=$(printf '%s\n' "$OUTPUT" | awk 'NF {print; exit}')
echo "You said: $TRANSCRIPT"