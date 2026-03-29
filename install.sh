#!/usr/bin/env bash
# ── bento IDE installer ──────────────────────────────────────────
# Symlinks the bento launcher and widget scripts into ~/.local/bin,
# and installs the yazi config for the bento file browser pane.
set -euo pipefail

BENTO_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
YAZI_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yazi-bento"


echo "bento IDE installer"
echo "==================="
echo ""
echo "Source:  ${BENTO_DIR}"
echo "Bin:     ${BIN_DIR}"
echo "Yazi:    ${YAZI_CONFIG_DIR}"
echo ""

# ── Check dependencies ────────────────────────────────────────────
MISSING=()
for cmd in zellij yazi micro python3 git; do
    if ! command -v "$cmd" &>/dev/null; then
        MISSING+=("$cmd")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "Missing required dependencies: ${MISSING[*]}"
    echo ""
    echo "On Arch Linux / Hyprland:"
    echo "  sudo pacman -S zellij yazi micro python git"
    echo ""
    echo "Optional (audio visualizer):"
    echo "  sudo pacman -S cava"
    echo ""
    read -rp "Continue anyway? [y/N] " yn
    case "$yn" in [yY]*) ;; *) exit 1 ;; esac
fi

# Check for cava separately (optional)
if ! command -v cava &>/dev/null; then
    echo "Note: cava not found — bcava pane will show a placeholder."
    echo "      Install with: sudo pacman -S cava"
    echo ""
fi

# ── Create directories ────────────────────────────────────────────
mkdir -p "$BIN_DIR"

# ── Symlink launcher ─────────────────────────────────────────────
ln -sf "${BENTO_DIR}/bento" "${BIN_DIR}/bento"
echo "  ✓ ${BIN_DIR}/bento → ${BENTO_DIR}/bento"

# ── Symlink widget scripts ────────────────────────────────────────
for script in bmon smon bgit bcava yazi-open yazi-pick; do
    chmod +x "${BENTO_DIR}/widgets/${script}"
    ln -sf "${BENTO_DIR}/widgets/${script}" "${BIN_DIR}/${script}"
    echo "  ✓ ${BIN_DIR}/${script}"
done

# ── Install yazi config (bento-specific) ──────────────────────────
# Uses a separate yazi config dir so it doesn't stomp the user's
# existing yazi setup.  The yazi-pick wrapper sets YAZI_CONFIG_HOME.
if [ -d "$YAZI_CONFIG_DIR" ]; then
    echo ""
    echo "Yazi config already exists at ${YAZI_CONFIG_DIR}"
    read -rp "Overwrite? [y/N] " yn
    case "$yn" in [yY]*) ;; *) echo "  skipped yazi config"; echo ""; ;; esac
fi

# Copy yazi config (not symlink — users may want to customise)
mkdir -p "${YAZI_CONFIG_DIR}/plugins/cwd-sync.yazi"
mkdir -p "${YAZI_CONFIG_DIR}/plugins/sftp-nav.yazi"
cp "${BENTO_DIR}/yazi/yazi.toml"    "${YAZI_CONFIG_DIR}/yazi.toml"
cp "${BENTO_DIR}/yazi/keymap.toml"  "${YAZI_CONFIG_DIR}/keymap.toml"
cp "${BENTO_DIR}/yazi/init.lua"     "${YAZI_CONFIG_DIR}/init.lua"
cp "${BENTO_DIR}/yazi/plugins/cwd-sync.yazi/main.lua" "${YAZI_CONFIG_DIR}/plugins/cwd-sync.yazi/main.lua"
cp "${BENTO_DIR}/yazi/plugins/sftp-nav.yazi/main.lua"  "${YAZI_CONFIG_DIR}/plugins/sftp-nav.yazi/main.lua"
echo "  ✓ yazi config → ${YAZI_CONFIG_DIR}"

# ── Make everything executable ────────────────────────────────────
chmod +x "${BENTO_DIR}/bento"
chmod +x "${BENTO_DIR}/widgets/"*

# ── PATH check ────────────────────────────────────────────────────
echo ""
if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    echo "Add ~/.local/bin to your PATH if it isn't already:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

echo "Done.  Launch with: bento"
echo ""
echo "Configure remote monitoring in: ${BENTO_DIR}/bento.conf"
echo "  Set BENTO_REMOTE_HOST to your remote machine's hostname."
echo "  The remote needs Glances running: glances -w --disable-webui"
