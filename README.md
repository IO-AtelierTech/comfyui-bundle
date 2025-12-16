# ComfyUI Bundle - Development Repository

> **Internal development repo for IO-AtelierTech's ComfyUI Docker bundle**

This repository builds the Docker image published to `ioateliertech/comfyui-bundle`. It's a one-command repackage of ComfyUI with curated plugins tailored for our internal creative workflows.

## Purpose

**For IO-AtelierTech developers only.** End users should use [comfyui-template](https://github.com/io-ateliertech/comfyui-template) instead.

This repo:
- Builds the Docker image with all plugins pre-installed
- Manages plugin submodules and upstream updates
- Publishes to Docker Hub via CI/CD

## Architecture

```
comfyui-bundle (this repo)          → Docker Hub: ioateliertech/comfyui-bundle
    │
    ├── comfyui/                    → Upstream: comfyanonymous/ComfyUI
    ├── plugins/genai-connectors/   → io-ateliertech/genai-connectors
    ├── plugins/comfyui-video-utils/→ io-ateliertech/comfyui-video-utils
    └── plugins/[community]/        → Various upstream plugins

comfyui-mcp (separate repo)         → PyPI: io-ateliertech-comfyui-mcp
comfyui-template (separate repo)    → End-user template (docker-compose + Justfile)
```

## Quick Start (Development)

```bash
# Clone with all submodules
git clone --recursive https://github.com/io-ateliertech/comfyui-bundle.git
cd comfyui-bundle

# Add your API keys
cp .env.example .env
nano .env  # Add FAL_KEY, etc.

# Build and start
cd docker && docker compose build
docker compose up -d
```

## Repository Structure

```
comfyui-bundle/
├── comfyui/                      # ComfyUI core (upstream submodule)
├── plugins/                      # Plugin ecosystem
│   ├── genai-connectors/         # Multi-vendor AI connectors (ours)
│   ├── comfyui-video-utils/      # Video utility nodes (ours)
│   ├── ComfyUI-FFmpeg/           # FFmpeg integration (upstream)
│   ├── ComfyUI-TextOverlay/      # Text overlays (upstream)
│   └── ComfyUI-Custom-Scripts/   # UI improvements (upstream)
├── docker/
│   ├── Dockerfile                # Production image build
│   └── docker-compose.yml        # Development compose
├── workflows-api/                # API format workflows
├── workflows-ui/                 # UI format workflows
├── data/                         # Persistent data (gitignored)
├── .env.example                  # Environment template
└── CLAUDE.md                     # AI assistant context
```

## Included Plugins

| Plugin | Ownership | Purpose |
|--------|-----------|---------|
| [genai-connectors](https://github.com/io-ateliertech/genai-connectors) | Ours | Multi-vendor AI inference (fal.ai, Replicate, etc.) |
| [comfyui-video-utils](https://github.com/io-ateliertech/comfyui-video-utils) | Ours | Video processing and FFmpeg integration |
| [ComfyUI-FFmpeg](https://github.com/MoonHugo/ComfyUI-FFmpeg) | Upstream | Video encoding/decoding |
| [ComfyUI-TextOverlay](https://github.com/Munkyfoot/ComfyUI-TextOverlay) | Upstream | Text overlays |
| [ComfyUI-Custom-Scripts](https://github.com/pythongosssss/ComfyUI-Custom-Scripts) | Upstream | UI enhancements |

## Development Workflow

### Building the Docker Image

```bash
# Build image
cd docker && docker compose build

# Tag for Docker Hub
docker tag comfyui-bundle:latest ioateliertech/comfyui-bundle:latest
docker tag comfyui-bundle:latest ioateliertech/comfyui-bundle:v1.0.0

# Push to Docker Hub
docker push ioateliertech/comfyui-bundle:latest
docker push ioateliertech/comfyui-bundle:v1.0.0
```

### Updating Upstream Dependencies

```bash
# Update ComfyUI core
cd comfyui && git pull origin master && cd ..

# Update all upstream plugins
git submodule update --remote --merge

# Update our plugins
cd plugins/genai-connectors && git pull origin main && cd ../..
cd plugins/comfyui-video-utils && git pull origin main && cd ../..

# Rebuild
cd docker && docker compose build
```

### Adding New Plugins

```bash
# Add upstream plugin as submodule
git submodule add https://github.com/author/ComfyUI-Plugin.git plugins/ComfyUI-Plugin

# Update Dockerfile to copy it
# Rebuild and test
cd docker && docker compose build
```

### Testing Changes

```bash
# Start development environment
cd docker && docker compose up -d

# View logs
docker compose logs -f

# Access ComfyUI
open http://localhost:8188

# Stop
docker compose down
```

## Publishing

### Docker Hub

Automated builds via GitHub Actions (see `.github/workflows/docker-publish.yml`):
- Push to `main` → `ioateliertech/comfyui-bundle:latest`
- Git tag `v*` → `ioateliertech/comfyui-bundle:vX.Y.Z`

### Manual Publish

```bash
docker login
docker push ioateliertech/comfyui-bundle:latest
docker push ioateliertech/comfyui-bundle:v1.0.0
```

## Related Repositories

- [comfyui-mcp](https://github.com/io-ateliertech/comfyui-mcp) - MCP server (PyPI: `io-ateliertech-comfyui-mcp`)
- [comfyui-template](https://github.com/io-ateliertech/comfyui-template) - End-user template
- [genai-connectors](https://github.com/io-ateliertech/genai-connectors) - Multi-vendor AI connectors
- [comfyui-video-utils](https://github.com/io-ateliertech/comfyui-video-utils) - Video utility nodes

## License

- ComfyUI: GPL-3.0 (upstream)
- IO-AtelierTech plugins: MIT
- This bundle repository: MIT
