"""
ComfyUI Video Utilities

Provides utility nodes for video operations:
- SaveVideoGetPath: Save video and output the file path for FFmpeg integration
"""

from __future__ import annotations

import os
import time
from typing import Optional

import folder_paths


class SaveVideoGetPath:
    """
    Save a VIDEO to disk and output the file path.

    Useful for connecting to FFmpeg nodes that require STRING paths.
    """

    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "video": ("VIDEO", {
                    "tooltip": "The video to save"
                }),
                "filename_prefix": ("STRING", {
                    "default": "video/ComfyUI",
                    "tooltip": "Output path prefix"
                }),
            },
            "optional": {
                "format": (["auto", "mp4"], {
                    "default": "mp4",
                    "tooltip": "Video format"
                }),
                "codec": (["auto", "h264"], {
                    "default": "h264",
                    "tooltip": "Video codec"
                }),
            }
        }

    RETURN_TYPES = ("VIDEO", "STRING")
    RETURN_NAMES = ("video", "video_path")
    FUNCTION = "save_video"
    CATEGORY = "video/utils"
    OUTPUT_NODE = True

    def save_video(
        self,
        video,
        filename_prefix: str = "video/ComfyUI",
        format: str = "mp4",
        codec: str = "h264",
    ):
        """Save video and return both the video object and the file path."""
        from comfy_api.latest._util import VideoContainer, VideoCodec

        # Get dimensions for path generation
        width, height = video.get_dimensions()

        # Generate output path
        full_output_folder, filename, counter, subfolder, filename_prefix = folder_paths.get_save_image_path(
            filename_prefix,
            folder_paths.get_output_directory(),
            width,
            height
        )

        # Determine extension
        ext = "mp4" if format in ["auto", "mp4"] else format
        file = f"{filename}_{counter:05}_.{ext}"
        video_path = os.path.join(full_output_folder, file)

        # Save the video
        video.save_to(
            video_path,
            format=VideoContainer(format),
            codec=VideoCodec(codec),
        )

        # Return video passthrough and the path
        return (video, video_path)


class GetVideoPath:
    """
    Extract the file path from a VIDEO that was loaded from disk.

    Note: Only works with videos loaded via LoadVideo, not generated videos.
    For generated videos, use SaveVideoGetPath first.
    """

    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "video": ("VIDEO", {
                    "tooltip": "The video to get path from"
                }),
            },
        }

    RETURN_TYPES = ("STRING",)
    RETURN_NAMES = ("video_path",)
    FUNCTION = "get_path"
    CATEGORY = "video/utils"

    def get_path(self, video):
        """Get the file path from a VideoFromFile object."""
        # VideoFromFile stores path in _VideoFromFile__file
        if hasattr(video, '_VideoFromFile__file'):
            path = video._VideoFromFile__file
            if isinstance(path, str):
                return (path,)

        raise ValueError(
            "Cannot extract path from this video. "
            "Use SaveVideoGetPath to save it first and get the path."
        )


# Node registration
NODE_CLASS_MAPPINGS = {
    "SaveVideoGetPath": SaveVideoGetPath,
    "GetVideoPath": GetVideoPath,
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "SaveVideoGetPath": "Save Video (Get Path)",
    "GetVideoPath": "Get Video Path",
}
