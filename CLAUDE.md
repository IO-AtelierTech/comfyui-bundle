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
├── workflows-api/    # API format workflows (for MCP execution)
├── workflows-ui/     # UI format workflows (mounted to ComfyUI editor)
├── data/             # Persistent data (gitignored, shared with container)
│   ├── input/        # Input images (accessible in ComfyUI)
│   ├── output/       # Generated outputs (videos, images)
│   └── models/       # Downloaded models
└── docs/             # Documentation and issue tracking
```

## Key Design Decisions

- **CPU-only PyTorch**: No NVIDIA/CUDA dependencies. All inference via fal.ai cloud GPUs.
- **Single Docker image**: All plugins baked into image, not mounted at runtime.
- **Git submodules**: External repos managed as submodules for version control.
- **MCP integration**: Claude Code can trigger ComfyUI workflows via MCP server.
- **Prefer fal.ai Connector**: Always use fal.ai connector nodes over ComfyUI partner nodes (see below).

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
| `COMFY_WORKFLOWS_DIR` | Directory for API format workflows (MCP execution) |
| `COMFY_WORKFLOWS_UI_DIR` | Directory for UI format workflows (ComfyUI editor) |
| `COMFY_WORKFLOW_JSON_FILE` | Default workflow for `generate_image` |
| `PROMPT_NODE_ID` | Default prompt node ID |
| `OUTPUT_NODE_ID` | Default output node ID |
| `OUTPUT_MODE` | `file` (Image) or `url` (string URL) |
| `POLL_TIMEOUT` | Max seconds to wait for workflow (1-300) |
| `POLL_INTERVAL` | Seconds between status polls (0.1-10.0) |

## Workflows

Two directories for different purposes:

| Directory | Format | Purpose |
|-----------|--------|---------|
| `workflows-api/` | API | Execute via MCP (`run_workflow()`) |
| `workflows-ui/` | UI | Load/edit in ComfyUI editor (mounted to container) |

### Workflow Formats

| Format | Structure | Use Case |
|--------|-----------|----------|
| **API** | `{"node_id": {"class_type": "...", "inputs": {...}}}` | Execution, MCP, automation |
| **UI** | `{"nodes": [...], "links": [...], "widgets_values": [...]}` | ComfyUI editor only |

**IMPORTANT**: API format uses explicit parameter names. UI format uses positional `widgets_values` arrays that can become misaligned when nodes are updated, causing validation errors like `resolution Input should be '1080p' [input_value='medium']`.

### Exporting Workflows

1. Create workflow in ComfyUI using fal.ai nodes
2. **Export as API format**: Settings → Export (API Format) → Save to `workflows-api/`
3. **Export as UI format**: Settings → Save → Save to `workflows-ui/`

### Converting Between Formats

```python
# API → UI (for editing in ComfyUI)
mcp__comfyui__convert_workflow_to_ui(workflow)
mcp__comfyui__save_workflow(workflow, name, format="ui")

# UI → API: Re-export from ComfyUI or rebuild programmatically
```

## Outputs

Generated files are saved to `data/output/` which is shared between the container and host:
- Videos: `data/output/video/`
- Images: `data/output/ComfyUI/`

Access outputs directly from your local filesystem without entering the container.

## Known Issues

See `docs/issues/` for tracked problems and workarounds.

### fal.ai Node Widget Ordering

**Issue**: UI format workflows with fal.ai video nodes (Vidu, Kling, Minimax) may fail with parameter validation errors due to `widgets_values` positional misalignment.

**Solution**: Always save and execute workflows in API format where parameters are explicitly named.

## Plugin Notes

| Plugin | Purpose | Notes |
|--------|---------|-------|
| ComfyUI-fal-Connector | Cloud GPU inference | Requires FAL_KEY |
| ComfyUI-TextOverlay | Text on images | No extra deps |
| ComfyUI-Custom-Scripts | UI improvements | Quality of life |

## fal.ai Connector vs Partner Nodes

**ALWAYS prefer Luma nodes over other partner nodes (Vidu, Kling, Minimax).**

### Why Luma?

| Aspect | Luma Nodes | Partner Nodes (Vidu, Kling, Minimax) |
|--------|------------|--------------------------------------|
| Reliability | Consistent, well-maintained | Prone to failures (see issues) |
| Error handling | Robust | Poor (e.g., HTTP 403 on downloads) |
| Features | Camera concepts, start/end frames | Limited parameter control |
| Quality | ray-2 model is excellent | Variable quality |

### Known Partner Node Issues

- **Vidu**: Video downloads fail with HTTP 403 (CloudFront URL expiration). Credits charged even on failure. See `docs/issues/vidu-403-download.md`
- **Kling/Minimax**: Similar download reliability issues

### Recommended Nodes for Video

| Task | Use This | NOT This |
|------|----------|----------|
| Image-to-video | `LumaImageToVideoNode` | `ViduImageToVideoNode` |
| Text-to-video | `LumaVideoNode` | `ViduTextToVideoNode` |
| Start/end frames | `LumaImageToVideoNode` (first_image + last_image) | `ViduStartEndToVideoNode` |
| Camera motion | `LumaConceptsNode` → connect to Luma video nodes | Manual prompting |

## Luma Video Nodes Reference

### LumaImageToVideoNode (Image to Video)
**Best for**: Animating images, transitions between frames

| Input | Type | Options/Default | Description |
|-------|------|-----------------|-------------|
| `prompt` | STRING | required | Video generation prompt |
| `model` | COMBO | `ray-2`, `ray-flash-2`, `ray-1-6` | Model selection |
| `resolution` | COMBO | `540p`, `720p`, `1080p`, `4k` | Output resolution |
| `duration` | COMBO | `5s`, `9s` | Video length |
| `loop` | BOOLEAN | false | Enable looping |
| `seed` | INT | 0 | Reproducibility seed |
| `first_image` | IMAGE | optional | Start frame |
| `last_image` | IMAGE | optional | End frame |
| `luma_concepts` | LUMA_CONCEPTS | optional | Camera motion control |

**Output**: `VIDEO`

### LumaVideoNode (Text to Video)
**Best for**: Pure text-to-video generation

| Input | Type | Options/Default | Description |
|-------|------|-----------------|-------------|
| `prompt` | STRING | required | Video generation prompt |
| `model` | COMBO | `ray-2`, `ray-flash-2`, `ray-1-6` | Model selection |
| `aspect_ratio` | COMBO | `1:1`, `16:9`, `9:16`, `4:3`, `3:4`, `21:9`, `9:21` | Output ratio |
| `resolution` | COMBO | `540p`, `720p`, `1080p`, `4k` | Output resolution |
| `duration` | COMBO | `5s`, `9s` | Video length |
| `loop` | BOOLEAN | false | Enable looping |
| `seed` | INT | 0 | Reproducibility seed |
| `luma_concepts` | LUMA_CONCEPTS | optional | Camera motion control |

**Output**: `VIDEO`

### LumaConceptsNode (Camera Motion)
**Best for**: Controlling camera movement in videos

Supports up to 4 camera concepts combined:
- **Movement**: `push_in`, `pull_out`, `truck_left`, `truck_right`, `dolly_zoom`
- **Pan/Tilt**: `pan_left`, `pan_right`, `tilt_up`, `tilt_down`
- **Rotation**: `roll_left`, `roll_right`, `orbit_left`, `orbit_right`
- **Vertical**: `pedestal_up`, `pedestal_down`, `crane_up`, `crane_down`
- **Angles**: `low_angle`, `high_angle`, `eye_level`, `ground_level`, `overhead`, `aerial`
- **Styles**: `handheld`, `static`, `pov`, `selfie`, `over_the_shoulder`, `bolt_cam`, `tiny_planet`
- **Special**: `zoom_in`, `zoom_out`, `aerial_drone`, `elevator_doors`

**Output**: `LUMA_CONCEPTS` → connect to `luma_concepts` input on video nodes

### SaveVideo (Output)
| Input | Type | Options/Default | Description |
|-------|------|-----------------|-------------|
| `video` | VIDEO | required | Video to save |
| `filename_prefix` | STRING | `video/ComfyUI` | Output path prefix |
| `format` | COMBO | `auto`, `mp4` | Output format |
| `codec` | COMBO | `auto`, `h264` | Video codec |

## fal.ai Connector Plugin Nodes

The `ComfyUI-fal-Connector` plugin provides these utility nodes:

### Input Nodes
| Node | Output | Purpose |
|------|--------|---------|
| `StringInput_fal` | STRING | Text parameter input |
| `IntegerInput_fal` | INT | Integer parameter input |
| `FloatInput_fal` | FLOAT | Float parameter input |
| `BooleanInput_fal` | BOOLEAN | Boolean parameter input |

### I/O Nodes
| Node | Purpose |
|------|---------|
| `LoadImageFromURL_fal` | Load image from HTTP URL |
| `SaveImage_fal` | Save image with metadata |

### Model Loaders
| Node | Purpose |
|------|---------|
| `RemoteCheckpointLoader_fal` | Load checkpoint from URL (HuggingFace, CivitAI) |
| `RemoteLoraLoader_fal` | Load and apply LoRA from URL |

## Example Workflow: Image-to-Video with Camera Motion

```python
wf = create_workflow()

# Load start and end frames
wf = add_node(wf, "1", "LoadImage", {"image": "start_frame.jpg"})
wf = add_node(wf, "2", "LoadImage", {"image": "end_frame.jpg"})

# Set up camera motion (optional)
wf = add_node(wf, "3", "LumaConceptsNode", {
    "concept1": "push_in",
    "concept2": "low_angle",
    "concept3": "None",
    "concept4": "None"
})

# Generate video
wf = add_node(wf, "4", "LumaImageToVideoNode", {
    "prompt": "Smooth cinematic transition, professional quality",
    "model": "ray-2",
    "resolution": "1080p",
    "duration": "5s",
    "loop": False,
    "seed": 0,
    "first_image": ["1", 0],
    "last_image": ["2", 0],
    "luma_concepts": ["3", 0]
})

# Save output
wf = add_node(wf, "5", "SaveVideo", {
    "video": ["4", 0],
    "filename_prefix": "video/output",
    "format": "mp4",
    "codec": "h264"
})

# Validate and execute
validate_workflow(wf)
execute_workflow(wf, output_node_id="5")
```

## Development Notes

- Each time you're using/testing comfyui mcp, if you hit an error, debug it, fix it (if possible), and update rules so this doesn't happen again
- Bonus points if you enhance the code at the mcp submodule