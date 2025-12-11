# ComfyUI Setup

A containerized ComfyUI setup with fal.ai integration, community plugins, and MCP server support for Claude Code.

## Features

- **Dockerized ComfyUI** - CPU-only setup, no local GPU required
- **fal.ai Integration** - Use cloud GPUs for inference via fal.ai API
- **Pre-configured Plugins** - Community plugins ready to use on startup
- **MCP Server** - Connect Claude Code to ComfyUI for AI-assisted workflows
- **GNOME Desktop Integration** - Pin to dock, launch with one click

## Quick Start

```bash
# Clone the repository with submodules
git clone --recursive https://github.com/YOUR_USERNAME/comfyui-setup.git
cd comfyui-setup

# Run setup
./scripts/setup.sh

# Add your fal.ai API key
nano .env  # Add: FAL_KEY=your_key_here

# Build and start
cd docker && docker compose build
cd .. && ./scripts/comfyui-launcher.sh
```

## Repository Structure

```
comfyui-setup/
├── comfyui/                    # Official ComfyUI (git submodule)
├── mcp/                        # MCP server fork (git submodule) [optional]
├── plugins/                    # Community plugins (git submodules)
│   ├── ComfyUI-fal-Connector/  # fal.ai cloud inference
│   ├── ComfyUI-TextOverlay/    # Text overlay on images
│   └── ComfyUI-Custom-Scripts/ # Quality-of-life improvements
├── docker/
│   ├── Dockerfile              # Single image with all plugins
│   └── docker-compose.yml      # Container orchestration
├── scripts/
│   ├── setup.sh                # One-time setup script
│   └── comfyui-launcher.sh     # Desktop launcher
├── assets/
│   └── comfyui.png             # App icon
├── workflows/                  # Store workflow JSON exports
├── data/                       # Persistent data (gitignored)
│   ├── output/                 # Generated images
│   ├── input/                  # Input images
│   └── models/                 # Model files
├── .mcp.json                   # MCP server configuration
├── .env                        # Environment variables (gitignored)
└── README.md
```

## Included Plugins

| Plugin | Description |
|--------|-------------|
| [ComfyUI-fal-Connector](https://github.com/badayvedat/ComfyUI-fal-Connector) | Use fal.ai cloud GPUs for inference |
| [ComfyUI-TextOverlay](https://github.com/Munkyfoot/ComfyUI-TextOverlay) | Add text overlays to generated images |
| [ComfyUI-Custom-Scripts](https://github.com/pythongosssss/ComfyUI-Custom-Scripts) | Quality-of-life improvements for the UI |

## Configuration

### fal.ai API Key

1. Create an account at [fal.ai](https://fal.ai)
2. Get your API key from the dashboard
3. Add to `.env`: `FAL_KEY=your_key_here`

### MCP Server for Claude Code

The setup creates `.mcp.json` for Claude Code integration. To use:

1. Create a workflow in ComfyUI using fal.ai nodes
2. Export workflow: Settings → Export (API Format)
3. Save to `workflows/default.json`
4. Update `.mcp.json` with correct node IDs:
   - `PROMPT_NODE_ID`: The text input node ID
   - `OUTPUT_NODE_ID`: The final image output node ID

### GNOME Desktop Integration

After running `setup.sh`:
1. Press Super key (Activities)
2. Search for "ComfyUI"
3. Right-click → "Add to Favorites" to pin to dock

## Commands

```bash
# Start ComfyUI
./scripts/comfyui-launcher.sh

# Or manually with docker
cd docker && docker compose up -d

# Stop ComfyUI
cd docker && docker compose down

# View logs
cd docker && docker compose logs -f

# Rebuild after updates
cd docker && docker compose build --no-cache
```

## Updating

```bash
# Pull latest changes
git pull
git submodule update --remote --merge

# Rebuild container
cd docker && docker compose build
```

## Adding More Plugins

To add a new plugin:

```bash
# Add as submodule
git submodule add https://github.com/author/ComfyUI-PluginName.git plugins/ComfyUI-PluginName

# Rebuild container
cd docker && docker compose build
```

## Troubleshooting

### Container won't start
```bash
cd docker && docker compose logs
```

### Plugins not loading
Check that plugins are properly copied:
```bash
docker compose exec comfyui ls /app/custom_nodes/
```

### MCP server not connecting
1. Ensure ComfyUI is running at http://localhost:8188
2. Check `.mcp.json` has correct paths
3. Verify `comfy-mcp-server` is installed: `which comfy-mcp-server`

## License

- ComfyUI: GPL-3.0
- Plugins: See individual plugin licenses
- This setup repository: MIT
