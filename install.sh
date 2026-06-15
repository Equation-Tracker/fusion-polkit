#!/usr/bin/env bash

# Copyright (c) 2024, Hypr Development
# Copyright (c) 2026, Equation Tracker
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

BINARY_NAME="fusion-polkitagent"
BUILD_BIN="build/fusion-polkitagent"
INSTALL_PATH="/usr/local/bin/${BINARY_NAME}"
SERVICE_NAME="fusion-polkitagent"
SERVICE_DIR="${HOME}/.config/systemd/user"
SERVICE_FILE="${SERVICE_DIR}/${SERVICE_NAME}.service"

echo "==> Building fusion-polkitagent..."
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
# cap parallelism to avoid runaway systems
JOBS="$(nproc)"
if [ "${JOBS}" -gt 8 ]; then JOBS=8; fi
make -j"${JOBS}"
cd ..


SHA256_SUM=$(sha256sum "${BUILD_BIN}" | awk '{print $1}')

if [ -w "$(dirname "${INSTALL_PATH}")" ]; then
    echo "==> Installing binary to ${INSTALL_PATH}..."
    cp "${BUILD_BIN}" "${INSTALL_PATH}"
else
    echo "==> Installing binary to ${INSTALL_PATH} with secure permissions..."
    sudo install -m 0755 "${BUILD_BIN}" "${INSTALL_PATH}"
    sudo chown root:root "${INSTALL_PATH}"
    sudo chmod 755 "${INSTALL_PATH}"
fi

INSTALLED_SHA256=$(sha256sum "${INSTALL_PATH}" | awk '{print $1}')
if [ "${INSTALLED_SHA256}" != "${SHA256_SUM}" ]; then
    echo "ERROR: checksum verification failed for ${INSTALL_PATH}" >&2
    exit 1
fi
echo "==> Checksum verified OK."

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

echo "==> Reloading systemd user daemon..."
systemctl --user daemon-reload
echo "==> Done. Enable with: systemctl --user enable --now ${SERVICE_NAME}"