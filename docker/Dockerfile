# =============================================================================
# Stage 1: Dependencies Builder
# =============================================================================
FROM python:3.11-slim AS deps-builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install PyTorch CPU-only (largest dependency, cached separately)
RUN pip install --no-cache-dir \
    torch \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cpu

# Copy ONLY requirements files (not full directories) for better caching
# These layers only invalidate when requirements.txt changes
COPY comfyui/requirements.txt /tmp/comfyui-requirements.txt
RUN pip install --no-cache-dir -r /tmp/comfyui-requirements.txt

# Copy plugin requirements files (only for plugins that have them)
# Each COPY creates a layer - changes to plugin code won't invalidate these
COPY plugins/ComfyUI-fal-Connector/requirements.txt /tmp/fal-connector-requirements.txt
COPY plugins/ComfyUI-FFmpeg/requirements.txt /tmp/ffmpeg-requirements.txt

# Install all plugin requirements
RUN pip install --no-cache-dir \
    -r /tmp/fal-connector-requirements.txt \
    -r /tmp/ffmpeg-requirements.txt \
    || true

# =============================================================================
# Stage 2: Runtime Image
# =============================================================================
FROM python:3.11-slim AS runtime

WORKDIR /app

# Install runtime system dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy installed packages from builder
COPY --from=deps-builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=deps-builder /usr/local/bin /usr/local/bin

# Create directories for persistence
RUN mkdir -p /app/output /app/input /app/models

# Copy ComfyUI application (changes more frequently than deps)
COPY comfyui/ /app/

# Copy all plugins into custom_nodes/ (changes most frequently)
COPY plugins/ /app/custom_nodes/

# Expose port
EXPOSE 8188

# Default command - CPU mode, listen on all interfaces
CMD ["python", "main.py", "--cpu", "--listen", "0.0.0.0", "--port", "8188"]
