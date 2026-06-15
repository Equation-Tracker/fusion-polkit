#!/usr/bin/env bash
set -euo pipefail

BINARY_NAME="fusion-polkitagent"
BUILD_BIN="build/fusion-polkitagent"
INSTALL_PATH="/usr/local/bin/${BINARY_NAME}"
SERVICE_NAME="fusion-polkitagent"
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
    cp "${BUILD_BIN}" "${INSTALL_PATH}"
else
# Compute checksum for verification
SHA256_SUM=$(sha256sum "${BUILD_BIN}" | awk '{print $1}')
echo "==> Installing binary to ${INSTALL_PATH} with secure permissions..."
sudo install -m 0755 "${BUILD_BIN}" "${INSTALL_PATH}"
sudo chown root:root "${INSTALL_PATH}"
sudo chmod 755 "${INSTALL_PATH}"

echo "==> Installing systemd user service..."
mkdir -p "${SERVICE_DIR}"
cat > "${SERVICE_FILE}" <<'EOF'
[Unit]
Description=Fusion Polkit Authentication Agent
PartOf=graphical-session.target
After=graphical-session.target
ConditionEnvironment=WAYLAND_DISPLAY

[Service]
ExecStart=/usr/local/bin/fusion-polkitagent
Slice=session.slice
TimeoutStopSec=5sec
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF
fi

echo "==> Disabling old hyprpolkitagent (if active)..."
systemctl --user disable --now hyprpolkitagent 2>/dev/null || true

echo "==> Enabling fusion-polkitagent..."
systemctl --user daemon-reload
systemctl --user enable --now "${SERVICE_NAME}"

echo "==> Done! ${BINARY_NAME} is running (if service enabled)."
systemctl --user status "${SERVICE_NAME}" --no-pager | head -n 8 || true
