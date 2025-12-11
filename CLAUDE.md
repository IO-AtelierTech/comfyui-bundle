# CLAUDE.md - Project Context for Claude Code

## Project Overview

ComfyUI Setup is a containerized, CPU-only ComfyUI installation with fal.ai cloud GPU integration, community plugins, and MCP server support for Claude Code workflows.

## Architecture

```
comfyui-setup/
├── comfyui/          # Official ComfyUI (submodule)
├── mcp/              # Fork of comfy-mcp-server (submodule)
├── plugins/          # Community plugins (submodules)
├── docker/           # Container configuration
├── scripts/          # Setup and launcher scripts
├── workflows/        # Exported ComfyUI workflows (JSON)
├── data/             # Persistent data (gitignored)
└── docs/             # Documentation and issue tracking
```

## Key Design Decisions

- **CPU-only PyTorch**: No NVIDIA/CUDA dependencies. All inference via fal.ai cloud GPUs.
- **Single Docker image**: All plugins baked into image, not mounted at runtime.
- **Git submodules**: External repos managed as submodules for version control.
- **MCP integration**: Claude Code can trigger ComfyUI workflows via MCP server.

## Common Tasks

### Start/Stop ComfyUI
```bash
cd docker && docker compose up -d    # Start
cd docker && docker compose down     # Stop
cd docker && docker compose logs -f  # Logs
```

### Rebuild after changes
```bash
cd docker && docker compose build --no-cache
```

### Add a new plugin
```bash
git submodule add https://github.com/author/plugin.git plugins/plugin-name
cd docker && docker compose build
```

### Update submodules
```bash
git submodule update --remote --merge
```

## MCP Server (v0.2.0)

The MCP server (`mcp/` submodule) connects Claude Code to ComfyUI with comprehensive workflow automation capabilities.

**Configuration**: `.mcp.json` in project root

### System Tools
- `get_system_stats()` - Server health, version, memory, device info
- `get_queue_status()` - Running and pending jobs
- `get_history(limit)` - Recent generation history
- `cancel_current(prompt_id)` - Interrupt generation
- `clear_queue(delete_ids)` - Clear queue or specific items

### Discovery Tools
- `list_nodes(filter)` - Available ComfyUI nodes
- `get_node_info(node_name)` - Node inputs, outputs, parameters
- `search_nodes(query)` - Search by name, type, category
- `list_models(folder)` - Models in checkpoints/loras/vae/etc.
- `list_embeddings()` - Available embeddings

### Workflow Management
- `list_workflows()` - Saved workflow files
- `load_workflow(name)` / `save_workflow(workflow, name)`
- `create_workflow()` - Empty workflow structure
- `add_node(workflow, node_id, class_type, inputs)` - Build workflows programmatically
- `validate_workflow(workflow)` - Check structure and node types

### Execution Tools
- `generate_image(prompt)` - Simple interface with default workflow
- `run_workflow(name, inputs, output_node_id)` - Execute saved workflow
- `execute_workflow(workflow, output_node_id)` - Execute arbitrary workflow dict
- `submit_workflow(workflow)` - Async submission (returns prompt_id)
- `get_prompt_status(prompt_id)` / `get_result_image(prompt_id, output_node_id)`

**Full Documentation**: See `mcp/README.md` for detailed usage examples

## Environment Variables

| Variable | Description |
|----------|-------------|
| `FAL_KEY` | fal.ai API key for cloud inference |
| `COMFY_URL` | ComfyUI server URL (default: http://localhost:8188) |
| `COMFY_WORKFLOWS_DIR` | Directory containing workflow JSON files |
| `COMFY_WORKFLOW_JSON_FILE` | Default workflow for `generate_image` |
| `PROMPT_NODE_ID` | Default prompt node ID |
| `OUTPUT_NODE_ID` | Default output node ID |
| `OUTPUT_MODE` | `file` (Image) or `url` (string URL) |
| `POLL_TIMEOUT` | Max seconds to wait for workflow (1-300) |
| `POLL_INTERVAL` | Seconds between status polls (0.1-10.0) |

## Workflows

Workflows are stored in `workflows/` as JSON files exported from ComfyUI (API format).

To use with MCP:
1. Create workflow in ComfyUI using fal.ai nodes
2. Export: Settings → Export (API Format)
3. Save to `workflows/`
4. Update `.mcp.json` with node IDs

## Known Issues

See `docs/issues/` for tracked problems and workarounds.

## Plugin Notes

| Plugin | Purpose | Notes |
|--------|---------|-------|
| ComfyUI-fal-Connector | Cloud GPU inference | Requires FAL_KEY |
| ComfyUI-TextOverlay | Text on images | No extra deps |
| ComfyUI-Custom-Scripts | UI improvements | Quality of life |
- each time you're using/testing comfyui mcp, if you hit an error, debug it, fix it (if possible), and update rules so this doesn't happen again. Bonus points if you enhace the code at the mcp[