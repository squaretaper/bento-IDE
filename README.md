# bento IDE

A terminal IDE layout built on [zellij](https://zellij.dev).  Three
columns — file browser, editor + shell, and a stack of live widgets —
in a single session you can drop into from any terminal emulator.

Designed for Linux desktops and laptops running tiling window managers
(Hyprland, Sway, i3, etc.) with a modern terminal (Ghostty, Kitty,
Alacritty, Foot, WezTerm).


## Layout

```
┌─────────────┬──────────────────────────┬──────────────────┐
│             │                          │ bmon       (44%) │
│ yazi        │ micro editor       (36%) │ system monitor   │
│ file        │──────────────────────────│──────────────────│
│ browser     │                          │ smon       (24%) │
│             │ zsh shell          (63%) │ remote monitor   │
│ (28 cols)   │                          │──────────────────│
│             │        (fluid)           │ bgit       (20%) │
│             │                          │ git status       │
│             │                          │──────────────────│
│             │                          │ bcava      (12%) │
│             │                          │ audio viz        │
│             │                          │ (34 cols)        │
├─────────────┴──────────────────────────┴──────────────────┤
│ compact-bar                                               │
└───────────────────────────────────────────────────────────┘
```

**Left column (yazi)** — Fixed 28 characters wide.  File browser with
SFTP support.  Navigate to any local or remote directory; opening a
file sends it to the micro editor pane automatically.  The cwd-sync
plugin writes the current path to `/tmp/bento-cwd` so bgit always
tracks the right repo.

**Center column (editor + shell)** — Fluid width, takes all remaining
space.  Top pane runs micro (36% height), bottom pane is a zsh shell
(63%).  At 120 columns this gives you ~54 chars of editor width; at
160 columns, ~94 chars.

**Right column (widgets)** — Fixed 34 characters wide.  Four stacked
monitoring panes, all rendering with braille-dot sparkline graphs:

| Widget | What it shows |
|--------|---------------|
| **bmon** | Local CPU, memory, disk I/O, temperatures, network |
| **smon** | Remote machine CPU, memory, disk I/O (via Glances API) |
| **bgit** | Git branch, status, ahead/behind, recent commits |
| **bcava** | Audio visualizer (cava braille dot-matrix) |

The fixed-width side columns ensure widgets always render correctly
regardless of terminal size.  The center column absorbs all the
variation.

**Minimum terminal width:** 100 columns.  Designed for 120–200+.


## Dependencies

| Package   | Required | Notes |
|-----------|----------|-------|
| zellij    | yes      | Terminal multiplexer — the foundation |
| yazi      | yes      | v0.4+ with SFTP/VFS support |
| micro     | yes      | Terminal text editor |
| python3   | yes      | Widgets are Python scripts |
| git       | yes      | For bgit |
| cava      | optional | Audio visualizer — bcava shows placeholder if missing |
| openssh   | optional | For SFTP browsing and remote git in bgit |
| glances   | optional | On the remote machine for smon |

### Arch Linux / Hyprland

```sh
sudo pacman -S zellij yazi micro python git cava openssh
```

### Ubuntu / Debian

```sh
# zellij — install from GitHub releases or cargo
cargo install --locked zellij

# yazi — install from GitHub releases (needs v0.4+)
# see https://yazi-rs.github.io/docs/installation/

sudo apt install micro python3 git cava openssh-client
```


## Install

```sh
git clone https://github.com/squaretaper/bento-IDE.git
cd bento-IDE
./install.sh
```

The installer symlinks scripts into `~/.local/bin` and copies a
dedicated yazi config to `~/.config/yazi-bento/` (does not touch
your existing yazi setup).


## Usage

```sh
bento
```

That's it.  Bento creates (or reattaches to) a zellij session named
`bento` with the full layout.

Detach with `Ctrl-O d` (zellij session mode → detach).  Reattach
with `bento` again.


## Configuration

Edit `bento.conf` in the repo root (or create an override at
`~/.config/bento/bento.conf`).  The user override is sourced after
the repo default, so you only need to set the values you want to
change.

### Layout

```sh
# Column widths in character cells.
# Center column (editor + shell) takes all remaining space.
BENTO_YAZI_WIDTH=28
BENTO_WIDGET_WIDTH=34

# Vertical splits inside center (editor : shell)
BENTO_EDITOR_PCT=36
BENTO_SHELL_PCT=63

# Widget column splits (bmon : smon : bgit : cava)
BENTO_BMON_PCT=44
BENTO_SMON_PCT=24
BENTO_BGIT_PCT=20
BENTO_CAVA_PCT=12
```

To change column widths, edit the values and also update
`layouts/bento.kdl` to match (the `size=28` and `size=34` values).
The vertical percentages inside each column are read by zellij
directly from the layout file.

### Remote monitoring (smon + SFTP)

```sh
# Hostname or IP — leave empty to disable smon
BENTO_REMOTE_HOST=myserver.local
BENTO_REMOTE_PORT=61208

# Display name (defaults to hostname)
BENTO_REMOTE_LABEL=studio

# The remote machine needs Glances running:
#   glances -w --disable-webui
```

Once `BENTO_REMOTE_HOST` is set, smon will poll the Glances API and
yazi can browse the machine via `sftp://myserver.local/`.  Add SFTP
bookmarks in `yazi/keymap.toml`:

```toml
[mgr]
prepend_keymap = [
  { on = ["g", "s"], run = "cd sftp://myserver.local//home/me", desc = "Server" },
  { on = ["g", "h"], run = "cd ~", desc = "Go home" },
]
```

### Intervals

```sh
BENTO_BMON_INTERVAL=2    # local monitor poll (seconds)
BENTO_SMON_INTERVAL=3    # remote monitor poll
BENTO_BGIT_INTERVAL=3    # git status poll
```

### Other

```sh
BENTO_EDITOR=micro       # editor command
BENTO_CAVA_BIN=cava      # path to cava binary
BENTO_SESSION=bento      # zellij session name
# BENTO_THEME=            # zellij theme (empty = zellij default)
BENTO_MIN_COLS=100       # minimum terminal width before warning
```


## How it works

1. `bento` launcher sources `bento.conf`, exports config as env vars,
   adds `widgets/` to PATH, and runs
   `zellij attach bento --create-layout layouts/bento.kdl`.

2. Zellij creates the 3-column layout.  Each pane runs its command:
   - Left: `yazi-pick` (yazi with `EDITOR=yazi-open` and bento yazi config)
   - Center top: `micro`
   - Center bottom: `zsh`
   - Right: `bmon`, `smon`, `bgit`, `bcava`

3. When you open a file in yazi, `yazi-open` sends keystrokes to the
   micro pane via `zellij action` to open it as a new tab.

4. yazi's `cwd-sync` plugin writes the current directory to
   `/tmp/bento-cwd`.  bgit reads this file to know which repo to
   display status for.

5. For SFTP files, `yazi-open` detects the yazi cache path, downloads
   via `scp`, opens in micro, and spawns a background watcher that
   syncs saves back to the remote.


## Keybinds

Full vim-style zellij keybinds (clear-defaults).  Key modes:

| Shortcut | Mode |
|----------|------|
| `Ctrl-P` | Pane — navigate, split, close, fullscreen |
| `Ctrl-T` | Tab — create, rename, switch, close |
| `Ctrl-N` | Resize — grow/shrink panes |
| `Ctrl-H` | Move — reorder panes |
| `Ctrl-S` | Scroll — vim-style scrollback |
| `Ctrl-O` | Session — detach, plugins, layout manager |
| `Ctrl-B` | Tmux mode — familiar tmux shortcuts |
| `Ctrl-G` | Lock — disable all keybinds (passthrough) |
| `Alt-H/J/K/L` | Quick focus — move between panes (always active) |


## Theming

Bento doesn't ship a theme.  The widget scripts use standard ANSI
16-color escapes, so they automatically match whatever terminal
palette you're using.  Set your preferred zellij theme by
uncommenting `theme "..."` in `config/zellij.kdl` or setting
`BENTO_THEME` in `bento.conf`.


## License

MIT
