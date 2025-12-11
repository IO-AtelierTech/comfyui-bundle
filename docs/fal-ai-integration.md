# fal.ai Integration Guide

## Overview

This project integrates with [fal.ai](https://fal.ai) for cloud GPU inference, enabling image generation without local GPU hardware. There are two distinct integration methods available.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        fal.ai Cloud                              │
│  ┌──────────────────────┐    ┌──────────────────────────────┐  │
│  │  Direct Model APIs   │    │  ComfyUI Cloud Instance      │  │
│  │  - flux/schnell      │    │  (fal-ai/comfy-server/stream) │  │
│  │  - flux/dev          │    │  - Full workflow support      │  │
│  │  - recraft-v3        │    │  - Custom nodes available     │  │
│  └──────────────────────┘    └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
           ▲                              ▲
           │ REST API                     │ /fal/execute
           │                              │
┌──────────┴──────────────────────────────┴───────────────────────┐
│                     Local Environment                            │
│  ┌─────────────┐    ┌─────────────┐    ┌────────────────────┐  │
│  │ Claude Code │◄──►│ MCP Server  │◄──►│ ComfyUI (CPU-only) │  │
│  │             │    │             │    │ + fal Connector    │  │
│  └─────────────┘    └─────────────┘    └────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Integration Methods

### Method 1: Direct fal.ai Model APIs

Call fal.ai's pre-built model endpoints directly. Best for simple, single-model generation.

**Endpoint format:** `https://fal.run/{model-id}`

**Example:**
```python
import urllib.request
import json

url = "https://fal.run/fal-ai/flux/schnell"
data = json.dumps({
    "prompt": "a tiny robot waving hello, pixel art style",
    "image_size": "square",
    "num_images": 1
}).encode()

req = urllib.request.Request(url, data=data, headers={
    "Authorization": f"Key {FAL_KEY}",
    "Content-Type": "application/json"
})

with urllib.request.urlopen(req) as resp:
    result = json.loads(resp.read().decode())
    print(result["images"][0]["url"])
```

**Response:**
```json
{
  "images": [
    {
      "url": "https://v3b.fal.media/files/.../image.jpg",
      "width": 512,
      "height": 512,
      "content_type": "image/jpeg"
    }
  ],
  "timings": {"inference": 0.077},
  "seed": 698116268,
  "prompt": "a tiny robot waving hello, pixel art style"
}
```

**Available Models:**

| Model ID | Description | Speed |
|----------|-------------|-------|
| `fal-ai/flux/schnell` | FLUX.1 Schnell - Fast generation | ~0.08s |
| `fal-ai/flux/dev` | FLUX.1 Dev - Higher quality | ~2-3s |
| `fal-ai/flux-pro/v1.1-ultra` | FLUX Pro - 2K resolution | ~5s |
| `fal-ai/recraft-v3` | Recraft V3 - SOTA quality | ~3s |
| `fal-ai/stable-diffusion-v35-large` | SD 3.5 Large | ~2s |

### Method 2: ComfyUI-fal-Connector (Remote Workflow Execution)

Send entire ComfyUI workflows to fal.ai's cloud ComfyUI instance for execution. Best for complex, multi-step workflows.

**Endpoint:** `/fal/execute` (via ComfyUI web interface)

**How it works:**
1. User designs workflow in ComfyUI web interface
2. Click "Run on fal.ai" button
3. Connector uploads local files to fal.ai storage
4. Workflow is sent to `fal-ai/comfy-server/stream`
5. Results stream back via SSE

**fal.ai Input Nodes:**

| Node | Input Fields | Output |
|------|--------------|--------|
| `StringInput_fal` | `name`, `value` | STRING |
| `IntegerInput_fal` | `name`, `number`, `min`, `max`, `step` | INT |
| `FloatInput_fal` | `name`, `number`, `min`, `max`, `step` | FLOAT |
| `BooleanInput_fal` | `name`, `value` | BOOLEAN |

**fal.ai I/O Helper Nodes:**

| Node | Purpose |
|------|---------|
| `SaveImage_fal` | Save output images to fal.ai storage |
| `LoadImageFromURL_fal` | Load images from URLs |
| `RemoteCheckpointLoader_fal` | Load model weights from URL |
| `RemoteLoraLoader_fal` | Load LoRA weights from URL |

## Configuration

### Environment Variables

```bash
# Required: fal.ai API key
FAL_KEY=your-key-id:your-key-secret

# Optional: Custom ComfyUI endpoint on fal.ai
FAL_COMFY_ENDPOINT=fal-ai/comfy-server/stream
```

### Config File (plugins/ComfyUI-fal-Connector/fal-config.ini)

```ini
[fal]
application_name = fal-ai/comfy-server/stream
api_key = your_fal:_api_key  # Fallback if FAL_KEY not set

[huggingface]
token = your_huggingface_token  # For private HF models
```

## Authentication

fal.ai uses API keys in format `key-id:key-secret`.

**Priority order for API key lookup:**
1. `FAL_KEY` environment variable
2. `fal-config.ini` file
3. fal CLI credentials (`~/.fal/credentials`)

**Get your API key:** https://fal.ai/dashboard/keys

## MCP Server Integration

### Current Status

The MCP server (`mcp/`) submits workflows to local ComfyUI's `/prompt` endpoint. For CPU-only setups, this means:
- Local execution won't work for AI inference (no GPU)
- Use fal.ai nodes with the web interface for cloud execution
- Direct fal.ai API calls work independently

### Future Enhancement

A potential `fal_generate_image` tool could wrap the direct API:

```python
@mcp.tool()
def fal_generate_image(
    prompt: str,
    model: str = "fal-ai/flux/schnell",
    image_size: str = "square"
) -> str:
    """Generate image using fal.ai cloud GPU."""
    # Direct API call to fal.ai
    # Returns image URL
```

## Workflow Examples

### Simple Text-to-Image (Direct API)

```bash
curl -X POST "https://fal.run/fal-ai/flux/schnell" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "cyberpunk cityscape at night"}'
```

### ComfyUI Workflow with fal Nodes

```json
{
  "1": {
    "class_type": "StringInput_fal",
    "inputs": {"name": "prompt", "value": "cyberpunk cityscape"}
  },
  "2": {
    "class_type": "RemoteCheckpointLoader_fal",
    "inputs": {"ckpt_url": "https://huggingface.co/.../model.safetensors"}
  },
  "3": {
    "class_type": "SaveImage_fal",
    "inputs": {"images": ["2", 0], "filename_prefix": "output"}
  }
}
```

## Troubleshooting

### "MissingCredentialsError: No FAL API key found"

1. Check `FAL_KEY` is set: `echo $FAL_KEY`
2. Ensure format is `key-id:key-secret`
3. Verify key at https://fal.ai/dashboard/keys

### Workflow fails on fal.ai cloud

1. Check all nodes are supported on fal.ai's ComfyUI instance
2. Ensure custom nodes are available (limited to common extensions)
3. File paths must be URLs, not local paths

### Slow response times

1. Use `flux/schnell` for faster generation (~0.08s)
2. Reduce image size
3. Check fal.ai status: https://status.fal.ai

## Cost Considerations

fal.ai charges based on GPU time:
- Inference time is measured precisely
- Image uploads don't use GPU time
- Check pricing: https://fal.ai/pricing

## Resources

- [fal.ai Documentation](https://docs.fal.ai)
- [fal.ai Model Gallery](https://fal.ai/models)
- [ComfyUI-fal-Connector GitHub](https://github.com/fal-ai/comfyui-fal-connector)
- [FLUX Models Guide](https://docs.fal.ai/model-apis/fast-flux)
