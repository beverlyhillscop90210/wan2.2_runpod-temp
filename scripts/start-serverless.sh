#!/usr/bin/env bash
set -e
echo "WAN 2.2 RunPod SERVERLESS Starting..."
/scripts/runtime-init.sh
/scripts/download_models.sh
TCMALLOC="$(ldconfig -p | grep -Po 'libtcmalloc.so.\d' | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"
: "${COMFY_LOG_LEVEL:=DEBUG}"
echo "Starting ComfyUI..."
python -u /comfyui/main.py --disable-auto-launch --disable-metadata --listen 127.0.0.1 --port 8188 --verbose "${COMFY_LOG_LEVEL}" --log-stdout --use-sage-attention &
echo "Starting RunPod Handler..."
python -u /handler.py
