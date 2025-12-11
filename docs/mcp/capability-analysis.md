# MCP Server Capability Analysis

## Current State (comfy-mcp-server v0.1.x)

### Available Tools

| Tool | Description | Limitations |
|------|-------------|-------------|
| `generate_image(prompt)` | Execute workflow with text prompt | Single hardcoded workflow, single text input node |
| `generate_prompt(topic)` | Generate prompt via Ollama | Requires separate Ollama server |

### Current Architecture

```
Claude Code → MCP Server → ComfyUI API
                ↓
         Single workflow JSON
         (COMFY_WORKFLOW_JSON_FILE)
```

**Key limitations:**
- Only one workflow can be used (set at startup)
- Only one input node (PROMPT_NODE_ID) can receive text
- No visibility into ComfyUI state
- No workflow management
- No queue/history access
- 20-second hardcoded timeout (may fail for complex generations)

## ComfyUI API Capabilities (Unexposed)

### Core Endpoints Available

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/prompt` | POST | Submit workflow for execution |
| `/queue` | GET | View running/pending jobs |
| `/queue` | POST | Clear queue (delete/interrupt) |
| `/history` | GET | View generation history |
| `/history/{id}` | GET | Get specific job result |
| `/history` | POST | Delete history entries |
| `/interrupt` | POST | Stop current generation |
| `/object_info` | GET | List all available nodes (566 nodes) |
| `/object_info/{node}` | GET | Get node parameters/inputs |
| `/models` | GET | List model folders |
| `/models/{folder}` | GET | List models in folder |
| `/system_stats` | GET | Server health/resources |
| `/upload/image` | POST | Upload image for workflows |
| `/view` | GET | Retrieve generated images |
| `/embeddings` | GET | List available embeddings |
| `/extensions` | GET | List loaded extensions |

### fal.ai Nodes Available

```
IntegerInput_fal    - Integer parameter input
FloatInput_fal      - Float parameter input
BooleanInput_fal    - Boolean toggle input
StringInput_fal     - Text/string input
SaveImage_fal       - Save to fal.ai storage
LoadImageFromURL_fal - Load image from URL
RemoteLoraLoader_fal - Load LoRA from fal.ai
RemoteCheckpointLoader_fal - Load checkpoint from fal.ai
```

## Recommended Improvements

### Priority 1: Core Functionality

1. **Dynamic Workflow Selection**
   ```python
   @mcp.tool()
   def list_workflows() -> list[str]:
       """List available workflow files in workflows/ directory"""

   @mcp.tool()
   def run_workflow(workflow_name: str, inputs: dict) -> Image | str:
       """Execute a named workflow with dynamic inputs"""
   ```

2. **Queue Management**
   ```python
   @mcp.tool()
   def get_queue_status() -> dict:
       """Get current queue state (running/pending jobs)"""

   @mcp.tool()
   def cancel_current() -> str:
       """Interrupt the currently running generation"""

   @mcp.tool()
   def clear_queue() -> str:
       """Clear all pending jobs from queue"""
   ```

3. **History Access**
   ```python
   @mcp.tool()
   def get_history(limit: int = 10) -> list[dict]:
       """Get recent generation history"""

   @mcp.tool()
   def get_image_from_history(prompt_id: str) -> Image:
       """Retrieve image from a previous generation"""
   ```

### Priority 2: Workflow Building

4. **Node Discovery**
   ```python
   @mcp.tool()
   def list_nodes(filter: str = None) -> list[str]:
       """List available nodes, optionally filtered (e.g., 'fal', 'image')"""

   @mcp.tool()
   def get_node_info(node_name: str) -> dict:
       """Get detailed info about a node (inputs, outputs, parameters)"""
   ```

5. **Model Discovery**
   ```python
   @mcp.tool()
   def list_models(folder: str = "checkpoints") -> list[str]:
       """List available models (checkpoints, loras, etc.)"""
   ```

### Priority 3: Advanced Features

6. **Image Upload**
   ```python
   @mcp.tool()
   def upload_image(image_path: str) -> str:
       """Upload an image to ComfyUI for use in workflows"""
   ```

7. **System Info**
   ```python
   @mcp.tool()
   def get_system_stats() -> dict:
       """Get ComfyUI server stats (memory, device, version)"""
   ```

8. **Multi-Input Workflow Support**
   ```python
   @mcp.tool()
   def run_workflow_advanced(
       workflow_name: str,
       text_inputs: dict[str, str],      # node_id -> text
       number_inputs: dict[str, float],  # node_id -> number
       image_inputs: dict[str, str]      # node_id -> image_path
   ) -> Image | str:
       """Execute workflow with multiple typed inputs"""
   ```

## Implementation Roadmap

### Phase 1: Essential (High Impact, Low Effort)
- [ ] `list_workflows()` - Enumerate workflows/ directory
- [ ] `get_queue_status()` - Simple GET to /queue
- [ ] `cancel_current()` - POST to /interrupt
- [ ] `get_system_stats()` - GET /system_stats

### Phase 2: Workflow Flexibility
- [ ] `run_workflow(name, inputs)` - Dynamic workflow loading
- [ ] `list_nodes(filter)` - Node discovery
- [ ] `get_node_info(name)` - Node details for workflow building

### Phase 3: Full Integration
- [ ] `get_history()` - Browse past generations
- [ ] `upload_image()` - Support img2img workflows
- [ ] `list_models()` - Model discovery
- [ ] Multi-input workflow support

## Architecture Proposal

```
Current:
  Claude → generate_image(prompt) → hardcoded workflow → ComfyUI

Proposed:
  Claude → list_workflows() → see available workflows
        → get_node_info("Fal*") → understand fal.ai nodes
        → run_workflow("flux-dev", {
            "6": {"text": "prompt"},
            "12": {"seed": 42}
          }) → dynamic execution
        → get_queue_status() → monitor progress
        → get_history() → review past work
```

## Notes

- Remove langchain/ollama dependency (prompt generation better done by Claude directly)
- Consider WebSocket support for real-time progress updates
- Add timeout configuration per-workflow
- Consider adding workflow validation before execution
