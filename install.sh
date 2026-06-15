#!/usr/bin/env bash
set -euo pipefail

BINARY_NAME="quill-polkit-agent"
BUILD_BIN="build/hyprpolkitagent"
INSTALL_PATH="/usr/local/bin/${BINARY_NAME}"
SERVICE_NAME="quill-polkit-agent"
SERVICE_DIR="${HOME}/.config/systemd/user"
SERVICE_FILE="${SERVICE_DIR}/${SERVICE_NAME}.service"

echo "==> Building quillpolkit..."
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
# cap parallelism to avoid runaway systems
JOBS="$(nproc)"
if [ "${JOBS}" -gt 8 ]; then JOBS=8; fi
make -j"${JOBS}"
cd ..

if [ -w "$(dirname "$INSTALL_PATH")" ]; then
    cp build/hyprpolkitagent "$INSTALL_PATH"
else
    echo "==> Need root permissions to install binary"
    sudo cp build/hyprpolkitagent "$INSTALL_PATH"
fi

# Compute checksum for verification
SHA256_SUM=$(sha256sum "${BUILD_BIN}" | awk '{print $1}')
echo "Built binary checksum: ${SHA256_SUM}"

read -r -p "Do you want to install the built binary to ${INSTALL_PATH} (requires sudo)? [y/N] " resp
if [[ "${resp}" != "y" && "${resp}" != "Y" ]]; then
    echo "Installation aborted by user."
    exit 0
fi

echo "==> Installing binary to ${INSTALL_PATH} with secure permissions..."
# use install to set proper owner and permissions
sudo install -m 0755 "${BUILD_BIN}" "${INSTALL_PATH}"
sudo chown root:root "${INSTALL_PATH}"
sudo chmod 755 "${INSTALL_PATH}"

echo "==> Installing systemd user service..."
mkdir -p "${SERVICE_DIR}"
cat > "${SERVICE_FILE}" << 'EOF'
[Unit]
Description=Quill Polkit Authentication Agent
PartOf=graphical-session.target
After=graphical-session.target
ConditionEnvironment=WAYLAND_DISPLAY

[Service]
ExecStart=/usr/local/bin/quill-polkit-agent
Slice=session.slice
TimeoutStopSec=5sec
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF

echo "==> Disabling old hyprpolkitagent (if active)..."
systemctl --user disable --now hyprpolkitagent 2>/dev/null || true

echo "==> Enabling quill-polkit-agent..."
systemctl --user daemon-reload
systemctl --user enable --now "${SERVICE_NAME}"

echo "==> Done! ${BINARY_NAME} is running (if service enabled)."
systemctl --user status "${SERVICE_NAME}" --no-pager | head -n 8 || true
