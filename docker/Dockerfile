FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PyTorch CPU-only first (separate layer for caching)
RUN pip install --no-cache-dir \
    torch \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cpu

# Copy ComfyUI requirements and install
COPY comfyui/requirements.txt /tmp/comfyui-requirements.txt
RUN pip install --no-cache-dir -r /tmp/comfyui-requirements.txt

# Copy plugin requirements and install (if they exist)
COPY plugins/ /tmp/plugins/
RUN for req in /tmp/plugins/*/requirements.txt; do \
        if [ -f "$req" ]; then \
            echo "Installing requirements from $req"; \
            pip install --no-cache-dir -r "$req" || true; \
        fi; \
    done && rm -rf /tmp/plugins

# Copy ComfyUI application
COPY comfyui/ /app/

# Copy all plugins into custom_nodes/
COPY plugins/ /app/custom_nodes/

# Create directories for persistence
RUN mkdir -p /app/output /app/input /app/models

# Expose port
EXPOSE 8188

# Default command - CPU mode, listen on all interfaces
CMD ["python", "main.py", "--cpu", "--listen", "0.0.0.0", "--port", "8188"]
