#!/bin/bash
# ComfyUI Launcher - Starts the Docker container and opens browser

COMFYUI_SETUP_DIR="/home/danyiel/Packages/ComfyUI/comfyui-setup"
COMFYUI_URL="http://localhost:8188"

cd "$COMFYUI_SETUP_DIR/docker" || exit 1

# Load environment variables
if [ -f "$COMFYUI_SETUP_DIR/.env" ]; then
    export $(grep -v '^#' "$COMFYUI_SETUP_DIR/.env" | xargs)
fi

# Check if container is already running
if docker compose ps --status running 2>/dev/null | grep -q comfyui; then
    echo "ComfyUI is already running"
else
    echo "Starting ComfyUI..."
    docker compose up -d

    # Wait for server to be ready
    echo "Waiting for ComfyUI to start..."
    for i in {1..60}; do
        if curl -s "$COMFYUI_URL" > /dev/null 2>&1; then
            echo "ComfyUI is ready!"
            break
        fi
        sleep 1
    done
fi

# Open browser
xdg-open "$COMFYUI_URL" 2>/dev/null || echo "Open $COMFYUI_URL in your browser"
