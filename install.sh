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

# ── Detect package manager ───────────────────────────────────────
PKG_MGR=""
PKG_INSTALL=""
if command -v pacman &>/dev/null; then
    PKG_MGR="pacman"
    PKG_INSTALL="sudo pacman -S --needed"
elif command -v apt &>/dev/null; then
    PKG_MGR="apt"
    PKG_INSTALL="sudo apt install -y"
elif command -v dnf &>/dev/null; then
    PKG_MGR="dnf"
    PKG_INSTALL="sudo dnf install -y"
elif command -v zypper &>/dev/null; then
    PKG_MGR="zypper"
    PKG_INSTALL="sudo zypper install -y"
fi

# Package name mapping per distro (some differ from the command name)
pkg_name() {
    local cmd="$1"
    case "$PKG_MGR" in
        apt)
            case "$cmd" in
                python3) echo "python3" ;;
                yazi)    echo "" ;;  # not in apt — needs manual install
                zellij)  echo "" ;;  # not in apt — needs cargo or binary
                *)       echo "$cmd" ;;
            esac
            ;;
        dnf)
            case "$cmd" in
                python3) echo "python3" ;;
                yazi)    echo "" ;;
                zellij)  echo "" ;;
                *)       echo "$cmd" ;;
            esac
            ;;
        *)  # pacman, zypper — names usually match
            case "$cmd" in
                python3) echo "python" ;;
                *)       echo "$cmd" ;;
            esac
            ;;
    esac
}

# ── Check dependencies ────────────────────────────────────────────
REQUIRED=(zellij yazi micro python3 git)
OPTIONAL=(cava openssh)
MISSING_REQ=()
MISSING_OPT=()
FOUND=()

echo "Checking dependencies..."
echo ""

for cmd in "${REQUIRED[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        ver=$("$cmd" --version 2>&1 | head -1 || true)
        FOUND+=("$cmd")
        echo "  ✓ $cmd  ($ver)"
    else
        MISSING_REQ+=("$cmd")
        echo "  ✗ $cmd  (required)"
    fi
done

for cmd in "${OPTIONAL[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        FOUND+=("$cmd")
        echo "  ✓ $cmd"
    else
        MISSING_OPT+=("$cmd")
        echo "  · $cmd  (optional)"
    fi
done
echo ""

# ── Install missing dependencies ─────────────────────────────────
if [ ${#MISSING_REQ[@]} -gt 0 ] || [ ${#MISSING_OPT[@]} -gt 0 ]; then
    if [ -n "$PKG_MGR" ]; then
        # Build install command from packages available in the repo
        INSTALLABLE=()
        MANUAL=()

        for cmd in "${MISSING_REQ[@]}" "${MISSING_OPT[@]}"; do
            pkg=$(pkg_name "$cmd")
            if [ -n "$pkg" ]; then
                INSTALLABLE+=("$pkg")
            else
                MANUAL+=("$cmd")
            fi
        done

        if [ ${#INSTALLABLE[@]} -gt 0 ]; then
            echo "The following can be installed via $PKG_MGR:"
            echo "  $PKG_INSTALL ${INSTALLABLE[*]}"
            echo ""
            read -rp "Install now? [Y/n] " yn
            case "$yn" in
                [nN]*) ;;
                *)
                    echo ""
                    $PKG_INSTALL "${INSTALLABLE[@]}"
                    echo ""
                    ;;
            esac
        fi

        if [ ${#MANUAL[@]} -gt 0 ]; then
            echo "These need manual installation (not in $PKG_MGR repos):"
            for cmd in "${MANUAL[@]}"; do
                case "$cmd" in
                    zellij) echo "  zellij — cargo install --locked zellij  OR  https://zellij.dev" ;;
                    yazi)   echo "  yazi   — cargo install --locked yazi-fm yazi-cli  OR  https://yazi-rs.github.io" ;;
                    *)      echo "  $cmd" ;;
                esac
            done
            echo ""
        fi
    else
        echo "Missing: ${MISSING_REQ[*]} ${MISSING_OPT[*]}"
        echo "Could not detect package manager. Install manually."
        echo ""
    fi

    # Hard stop if required deps are still missing
    STILL_MISSING=()
    for cmd in "${MISSING_REQ[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            STILL_MISSING+=("$cmd")
        fi
    done

    if [ ${#STILL_MISSING[@]} -gt 0 ]; then
        echo "Still missing required: ${STILL_MISSING[*]}"
        read -rp "Continue anyway? [y/N] " yn
        case "$yn" in [yY]*) ;; *) exit 1 ;; esac
        echo ""
    fi
fi

if ! command -v cava &>/dev/null; then
    echo "Note: cava not found — bcava pane will show a placeholder."
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
