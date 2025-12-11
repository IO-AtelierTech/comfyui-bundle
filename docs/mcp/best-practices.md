# MCP Server Best Practices

Based on official MCP documentation and industry standards.

## Architectural Principles

### 1. Single Responsibility
Each MCP server should have one clear, well-defined purpose. Our ComfyUI MCP server focuses solely on ComfyUI workflow management.

### 2. Defense in Depth Security
Layer security controls:
- Input validation (Pydantic models)
- Output sanitization
- Environment variable validation at startup
- Error messages that don't expose internals

### 3. Fail-Safe Design
- Graceful degradation when ComfyUI is unavailable
- Timeout handling for long-running operations
- Clear error messages with actionable guidance

## Code Organization

### Use Pydantic for All Data Structures

```python
from pydantic import BaseModel, Field

class WorkflowNode(BaseModel):
    class_type: str = Field(description="Node class name")
    inputs: dict = Field(default_factory=dict)

class Workflow(BaseModel):
    nodes: dict[str, WorkflowNode] = Field(default_factory=dict)
```

### Tool Parameter Validation

```python
from pydantic import Field

@mcp.tool()
def list_nodes(
    filter: str = Field(None, description="Filter nodes by name pattern"),
    limit: int = Field(100, ge=1, le=1000, description="Max results")
) -> list[str]:
    ...
```

### Structured Return Types

```python
class SystemStats(BaseModel):
    comfyui_version: str
    pytorch_version: str
    device_type: str
    ram_free_gb: float

@mcp.tool()
def get_system_stats() -> SystemStats:
    ...
```

## Testing Strategy

### Four-Layer Testing Approach

1. **Unit Tests**: Test individual functions in isolation
2. **Integration Tests**: Test against running ComfyUI instance
3. **Contract Tests**: Validate MCP protocol compliance
4. **Load Tests**: Verify performance under concurrent requests

### Testing with pytest

```python
import pytest
from mcp.client.session import ClientSession
from mcp.shared.memory import create_connected_server_and_client_session

@pytest.fixture
async def client_session():
    async with create_connected_server_and_client_session(app) as session:
        yield session

@pytest.mark.anyio
async def test_get_system_stats(client_session: ClientSession):
    result = await client_session.call_tool("get_system_stats", {})
    assert "comfyui_version" in result.structuredContent
```

## Error Handling

### Error Classification

| Type | Description | Example |
|------|-------------|---------|
| Client Error | Invalid input | Missing required parameter |
| Server Error | Internal fault | Unexpected exception |
| External Error | Dependency issue | ComfyUI unavailable |

### Error Response Pattern

```python
class ErrorResponse(BaseModel):
    error: str
    code: str
    details: dict | None = None
    retry_after: int | None = None  # seconds

def handle_error(e: Exception) -> ErrorResponse:
    if isinstance(e, ValidationError):
        return ErrorResponse(error=str(e), code="VALIDATION_ERROR")
    elif isinstance(e, URLError):
        return ErrorResponse(
            error="ComfyUI unavailable",
            code="COMFY_UNAVAILABLE",
            retry_after=5
        )
    return ErrorResponse(error="Internal error", code="INTERNAL_ERROR")
```

## Configuration Management

### Environment Variables

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    comfy_url: str = "http://localhost:8188"
    workflows_dir: str | None = None
    output_mode: str = "file"
    poll_timeout: int = 60
    poll_interval: float = 1.0

    class Config:
        env_prefix = "COMFY_"
```

### Validate at Startup

```python
def run_server():
    settings = Settings()
    if not validate_comfy_connection(settings.comfy_url):
        print(f"Warning: Cannot connect to {settings.comfy_url}")
    mcp.run()
```

## Performance Considerations

### Connection Pooling
Reuse HTTP connections for multiple requests.

### Async Operations
Use async/await for I/O-bound operations.

### Timeouts
Always set explicit timeouts:

```python
resp = request.urlopen(req, timeout=30)
```

### Caching
Cache static data like node info:

```python
from functools import lru_cache

@lru_cache(maxsize=1)
def get_all_nodes():
    return comfy_get("/object_info")
```

## Logging

### Structured Logging

```python
import logging
import json

logger = logging.getLogger(__name__)

def log_tool_call(tool_name: str, args: dict, result: Any):
    logger.info(json.dumps({
        "event": "tool_call",
        "tool": tool_name,
        "args": args,
        "result_type": type(result).__name__
    }))
```

## Sources

- [MCP Best Practices Guide](https://modelcontextprotocol.info/docs/best-practices/)
- [MCP Python SDK Documentation](https://github.com/modelcontextprotocol/python-sdk)
- [MCP Specification](https://modelcontextprotocol.io/specification/2025-06-18)
- [7 MCP Server Best Practices - MarkTechPost](https://www.marktechpost.com/2025/07/23/7-mcp-server-best-practices-for-scalable-ai-integrations-in-2025/)
