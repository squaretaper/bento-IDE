#!/usr/bin/env bash
# ── bento IDE uninstaller ─────────────────────────────────────────
set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
YAZI_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yazi-bento"
ZELLIJ_THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zellij/themes"

echo "bento IDE uninstaller"
echo "====================="
echo ""

# Remove symlinks
for script in bento bmon smon bgit bcava yazi-open yazi-pick; do
    target="${BIN_DIR}/${script}"
    if [ -L "$target" ]; then
        rm "$target"
        echo "  ✓ removed ${target}"
    fi
done

# Remove theme symlink
target="${ZELLIJ_THEME_DIR}/moonfly.kdl"
if [ -L "$target" ]; then
    rm "$target"
    echo "  ✓ removed ${target}"
fi

# Remove yazi-bento config
if [ -d "$YAZI_CONFIG_DIR" ]; then
    echo ""
    read -rp "Remove yazi-bento config at ${YAZI_CONFIG_DIR}? [y/N] " yn
    case "$yn" in
        [yY]*)
            rm -rf "$YAZI_CONFIG_DIR"
            echo "  ✓ removed ${YAZI_CONFIG_DIR}"
            ;;
    esac
fi

# Clean up IPC file
rm -f /tmp/bento-cwd

echo ""
echo "Done.  The repo itself was not removed."
