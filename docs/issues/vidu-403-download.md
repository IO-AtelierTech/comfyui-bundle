# Vidu 403 Download Error

## Issue
Video generation succeeds but download fails with HTTP 403.

## Error Log
```
Vidu task 896660856530558976 succeeded. Video URL: https://video.cf.vidu.com/...
Exception: Failed to download (HTTP 403).
```

## Root Cause
- Vidu returns a CloudFront signed URL with expiration
- The download code in `comfy_api_nodes/nodes_vidu.py` (line 550) fails if URL expires
- Credits are charged even when download fails

## Affected Nodes
- ViduStartEndToVideoNode
- ViduImageToVideoNode
- ViduTextToVideoNode
- ViduReferenceVideoNode

## Workaround
1. Use fal.ai API directly instead of partner nodes
2. Or manually download the video URL from logs before expiration

## Fix Required
The `nodes_vidu.py` should:
1. Download immediately after task completion
2. Retry with fresh URL if 403
3. Cache video locally before returning

## Status
Upstream bug in `comfy_api_nodes` package
