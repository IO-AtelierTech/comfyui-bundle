#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== ComfyUI Setup ==="
echo "Repository: $REPO_DIR"
echo ""

# Initialize and update submodules
echo "1. Initializing git submodules..."
cd "$REPO_DIR"
git submodule update --init --recursive

echo "   Submodules initialized:"
echo "   - comfyui/ (official ComfyUI)"
if [ -d "$REPO_DIR/mcp" ]; then
    echo "   - mcp/ (MCP server)"
fi
echo "   - plugins/ (community plugins)"
ls -1 "$REPO_DIR/plugins" 2>/dev/null | sed 's/^/     - /'

# Create data directories
echo ""
echo "2. Creating data directories..."
mkdir -p "$REPO_DIR/data/output" "$REPO_DIR/data/input" "$REPO_DIR/data/models"

# Create .env file if it doesn't exist
if [ ! -f "$REPO_DIR/.env" ]; then
    echo ""
    echo "3. Creating .env file..."
    cat > "$REPO_DIR/.env" << 'EOF'
# fal.ai API key (get one at https://fal.ai)
FAL_KEY=

# Optional: ComfyUI settings
# COMFYUI_PORT=8188
EOF
    echo "   Created .env file - please add your FAL_KEY"
else
    echo ""
    echo "3. .env file already exists, skipping..."
fi

# Install comfy-mcp-server
echo ""
echo "4. Installing MCP server..."
if [ -d "$REPO_DIR/mcp" ]; then
    # Use local fork
    cd "$REPO_DIR/mcp"
    if command -v uv &> /dev/null; then
        uv pip install -e . 2>/dev/null || pip install -e . 2>/dev/null || echo "   Failed to install local MCP"
    else
        pip install -e . 2>/dev/null || echo "   Failed to install local MCP"
    fi
    cd "$REPO_DIR"
else
    # Use published package
    if command -v uv &> /dev/null; then
        uv tool install comfy-mcp-server 2>/dev/null || echo "   Already installed or failed"
    else
        pip install comfy-mcp-server 2>/dev/null || echo "   pip install failed"
    fi
fi

# Create desktop launcher
echo ""
echo "5. Creating desktop launcher..."
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/.local/share/icons/hicolor/256x256/apps"

# Copy launcher script
cp "$REPO_DIR/scripts/comfyui-launcher.sh" "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/comfyui-launcher.sh"

# Update launcher script with correct path
sed -i "s|COMFYUI_SETUP_DIR=.*|COMFYUI_SETUP_DIR=\"$REPO_DIR\"|" "$HOME/.local/bin/comfyui-launcher.sh"

# Copy icon if exists
if [ -f "$REPO_DIR/assets/comfyui.png" ]; then
    cp "$REPO_DIR/assets/comfyui.png" "$HOME/.local/share/icons/hicolor/256x256/apps/"
fi

# Create desktop file
cat > "$HOME/.local/share/applications/comfyui.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ComfyUI
Comment=Node-based Stable Diffusion UI (Docker)
Exec=$HOME/.local/bin/comfyui-launcher.sh
Icon=comfyui
Terminal=false
Categories=Graphics;Development;
StartupNotify=true
StartupWMClass=comfyui
Keywords=ai;image;generation;stable;diffusion;fal;
EOF

# Update desktop database
update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
gtk-update-icon-cache "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true

# Create MCP config
echo ""
echo "6. Creating MCP configuration..."
cat > "$REPO_DIR/.mcp.json" << EOF
{
  "mcpServers": {
    "comfyui": {
      "command": "comfy-mcp-server",
      "env": {
        "COMFY_URL": "http://localhost:8188",
        "COMFY_WORKFLOW_JSON_FILE": "$REPO_DIR/workflows/default.json",
        "PROMPT_NODE_ID": "6",
        "OUTPUT_NODE_ID": "9",
        "OUTPUT_MODE": "file"
      }
    }
  }
}
EOF

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Installed plugins:"
ls -1 "$REPO_DIR/plugins" 2>/dev/null | sed 's/^/  - /'
echo ""
echo "Next steps:"
echo "1. Add your fal.ai API key to .env file"
echo "2. Build the Docker container: cd docker && docker compose build"
echo "3. Start ComfyUI: ./scripts/comfyui-launcher.sh"
echo "   Or search for 'ComfyUI' in GNOME Activities and pin to dock"
echo ""
echo "4. Create a workflow in ComfyUI and export it to workflows/default.json"
echo "5. Update .mcp.json with the correct node IDs from your workflow"
