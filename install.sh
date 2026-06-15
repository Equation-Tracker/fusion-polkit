#!/bin/bash
set -e

BINARY_NAME="quill-polkit-agent"
INSTALL_PATH="/usr/local/bin/$BINARY_NAME"
SERVICE_NAME="quill-polkit-agent"
SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SERVICE_DIR/$SERVICE_NAME.service"

echo "==> Building quillpolkit..."
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j"$(nproc)"
cd ..

if [ -w "$(dirname "$INSTALL_PATH")" ]; then
    cp build/hyprpolkitagent "$INSTALL_PATH"
else
    echo "==> Need root permissions to install binary"
    sudo cp build/hyprpolkitagent "$INSTALL_PATH"
fi

echo "==> Installing systemd user service..."
mkdir -p "$SERVICE_DIR"
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Quill Polkit Authentication Agent
PartOf=graphical-session.target
After=graphical-session.target
ConditionEnvironment=WAYLAND_DISPLAY

[Service]
ExecStart=$INSTALL_PATH
Slice=session.slice
TimeoutStopSec=5sec
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF

echo "==> Disabling hyprpolkitagent (if active)..."
systemctl --user disable --now hyprpolkitagent 2>/dev/null || true

echo "==> Enabling quill-polkit-agent..."
systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE_NAME"

echo "==> Done! quill-polkit-agent is running."
systemctl --user status "$SERVICE_NAME" --no-pager | head -5
