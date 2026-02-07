Tmux Configuration
=====================
Tmux configuration, that supercharges your [tmux](https://tmux.github.io/) and builds cozy and cool terminal environment. Forked from [samoshkin/tmux-config](https://github.com/samoshkin/tmux-config) with additions for 3-level nesting and ultrawide monitor support.

![intro](https://user-images.githubusercontent.com/768858/33152741-ec5f1270-cfe6-11e7-9570-6d17330a83aa.gif)

Table of contents
-----------------

1. [Features](#features)
1. [Installation](#installation)
1. [General settings](#general-settings)
1. [Key bindings](#key-bindings)
1. [Status line](#status-line)
1. [Nested tmux sessions](#nested-tmux-sessions)
1. [Session persistence](#session-persistence)
1. [Ultrawide layout system](#ultrawide-layout-system)
1. [Agent team layout](#agent-team-layout)
1. [Copy mode](#copy-mode)
1. [Clipboard integration](#clipboard-integration)
1. [Themes and customization](#themes-and-customization)

Features
---------

- 3-level tmux nesting: laptop (L1) → dev node (L2) → compute node (L3)
- independent toggle keys: `C-f` for L1 ↔ inner, `C-g` for L2 ↔ L3
- ultrawide monitor layout system with auto-tripling new windows
- agent team layout for Claude Code (or similar multi-agent tools) with auto-focus resizing
- local vs remote vs compute node specific session configuration
- scroll and copy mode improvements
- integration with system clipboard (works for local, remote, and nested session scenarios)
- supercharged status line with level indicator and ultrawide mode indicator
- renew tmux and shell environment (SSH_AUTH_SOCK, DISPLAY, SSH_TTY) when reattaching back to old session
- newly created windows and panes retain current working directory
- monitor windows for activity/silence
- highlight focused pane
- merge current session with existing one (move all windows)
- configurable visual theme/colors, with some elements borrowed from [Powerline](https://github.com/powerline/powerline)
- session persistence via [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) and [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) with per-level save directories and auto-save/restore on L2 and L3
- per-pane bash history files that survive session restores
- integration with 3rd party plugins: [tmux-sidebar](https://github.com/tmux-plugins/tmux-sidebar), [tmux-copycat](https://github.com/tmux-plugins/tmux-copycat), [tmux-open](https://github.com/tmux-plugins/tmux-open), [tmux-plugin-sysstat](https://github.com/samoshkin/tmux-plugin-sysstat), [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect), [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum)

**Status line widgets**:

- level indicator (L1/L2/L3) and ultrawide mode indicator (UW)
- CPU, memory usage, system load average metrics
- username and hostname, current date time
- battery information in status line
- color-coded SLURM remaining time on compute nodes (L3): green > 3.5 days, yellow 1--3.5 days, red < 1 day
- visual indicator when you press `prefix`
- visual indicator when you're in `Copy` mode
- visual indicator when pane is zoomed
- visual indicator when key bindings are off (`OFF`)
- online/offline visual indicator
- toggle visibility of status bar


Installation
-------------
Prerequisites:
- tmux >= "3.4"

To install:
```
$ git clone https://github.com/AlexHarn/tmux-config.git
$ ./tmux-config/install.sh
```

`install.sh` script does following:
- copies files to `~/.tmux` directory
- symlink tmux config file at `~/.tmux.conf`, existing `~/.tmux.conf` will be backed up
- [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) will be installed at default location `~/.tmux/plugins/tpm`, unless already present
- required tmux plugins will be installed

Finally, you can jump into a new tmux session:

```
$ tmux new
```


General settings
----------------
Windows and pane indexing starts from `1` rather than `0`. Scrollback history limit is set to `20000`. Automatic window renaming is turned off. Aggressive resizing is on. Message line display timeout is `1.5s`. Mouse support is `on`.

256 color palette support is turned on, make sure that your parent terminal is configured properly. See [here](https://unix.stackexchange.com/questions/1045/getting-256-colors-to-work-in-tmux) and [there](https://github.com/tmux/tmux/wiki/FAQ)

```
# parent terminal
$ echo $TERM
xterm-256color

# jump into a tmux session
$ tmux new
$ echo $TERM
screen-256color
```

Key bindings
-----------
So `~/.tmux.conf` overrides default key bindings for many actions, to make them more reasonable, easy to recall and comfortable to type.

| tmux key | Description |
|----------|-------------|
| `C-f` | Toggle L1 on/off (pass keys to inner sessions). See [Nested sessions](#nested-tmux-sessions). |
| `C-g` | Toggle L2 on/off (switch between L2 and L3). Only active on L2. |
| `C-t` | New window (auto-triples in ultrawide mode) |
| `C-h/j/k/l` | Vim-style pane selection |
| `C-n` / `C-p` | Next/previous window |
| `<prefix> C-e` | Open ~/.tmux.conf file in your $EDITOR |
| `<prefix> C-r` | Reload tmux configuration from ~/.tmux.conf file |
| `<prefix> r` | Rename current window |
| `<prefix> R` | Rename current session |
| `<prefix> _` | Split new pane horizontally |
| `<prefix> \|` | Split new pane vertically |
| `<prefix> [` / `]` | Select previous/next pane |
| `<prefix> H/J/K/L` | Resize pane (5 cells) |
| `<prefix> Tab` | Switch to most recently used window |
| `<prefix> \\` | Swap current pane with first pane |
| `<prefix> C-o` | Swap current active pane with next one |
| `<prefix> +` | Toggle zoom for current pane |
| `<prefix> x` | Kill current window |
| `<prefix> C-x` | Kill other windows (with confirmation) |
| `<prefix> Q` | Kill current session (with confirmation) |
| `<prefix> 3` | Triple column layout (see [Ultrawide](#ultrawide-layout-system)) |
| `<prefix> u` | Toggle ultrawide mode on/off |
| `<prefix> t` | Rearrange into agent team layout (see [Agent team layout](#agent-team-layout)) |
| `<prefix> y` | Restore standard triple layout, kill agent panes |
| `<prefix> =` | Rebalance all panes (tiled fallback) |
| `<prefix> C-u` | Merge current session with another |
| `<prefix> d` | Detach from session |
| `<prefix> D` | Detach other clients from session |
| `<prefix> C-s` | Toggle status bar visibility |
| `<prefix> F5` | Save tmux session (resurrect) |
| `<prefix> F6` | Restore tmux session (resurrect) |
| `<prefix> m` | Monitor current window for activity |
| `<prefix> M` | Monitor current window for silence |


Status line
-----------

The status line is kept dense and informative.

**Left part**: Level indicator (L1/L2/L3).

**Right part** (left to right):
- prefix highlight indicator `[^B]`
- keys off indicator `OFF` (when nesting toggle is active)
- zoom indicator `[Z]`
- ultrawide mode indicator `UW`
- CPU, memory usage, system load average (via [tmux-plugin-sysstat](https://github.com/samoshkin/tmux-plugin-sysstat))
- username and hostname
- date and time, battery (L1 only)
- online/offline indicator

On L3 (compute node), a color-coded remaining SLURM job time widget replaces date/time and battery. The color indicates urgency: green (> 3.5 days), yellow (1--3.5 days), red (< 1 day).

Window tabs use Powerline arrow glyphs, so you need to install a Powerline-enabled font. See [Powerline docs](https://powerline.readthedocs.io/en/latest/installation.html#fonts-installation) for instructions and here is the [collection of patched fonts for powerline users](https://github.com/powerline/fonts).

You might want to hide status bar using `<prefix> C-s` keybinding.


Nested tmux sessions
--------------------

This config supports **3-level nesting** for workflows like:

```
laptop (L1)  →  dev node (L2)  →  compute node (L3)
   SSH              SSH
```

### How it works

Two independent toggle keys control which level is active:

- **`C-f`**: Toggle L1 on/off. When L1 is off, keys pass through to L2 (and L3 if L2 is also off).
- **`C-g`**: Toggle L2 on/off. When L2 is off, keys pass through to L3. Only active on L2 (bound in `tmux.remote.conf`).

### Navigation

| From | To L1 | To L2 | To L3 |
|------|-------|-------|-------|
| L1 | --- | `C-f` | `C-f`, `C-g` |
| L2 | `C-f` | --- | `C-g` |
| L3 | `C-g`, `C-f` | `C-g` | --- |

### Visual differentiation

Each level has distinct visual cues so you always know where you are:

| Level | Status position | Accent color | Level indicator |
|-------|----------------|--------------|-----------------|
| L1 (laptop) | top | orange | L1 |
| L2 (dev node) | bottom | orange | L2 |
| L3 (compute) | bottom | blue | L3 |

When a level is in "off" mode, its status bar turns grey and shows an `OFF` indicator.

### Level detection

Levels are detected automatically:

- **L1** (default): No `$SSH_CLIENT` variable set.
- **L2**: Detected via `$SSH_CLIENT` environment variable. Sources `tmux.remote.conf`.
- **L3**: Detected via `TMUX_NEST_LEVEL` environment variable. Use an alias like `alias ctmux='TMUX_NEST_LEVEL=3 tmux'` to start L3 sessions. Sources `tmux.compute.conf`.

### Configuration files

| File | Purpose |
|------|---------|
| `tmux.conf` | Base config (L1). C-f toggle, all shared settings. |
| `tmux.remote.conf` | L2 overrides. Status bar at bottom, C-g toggle. |
| `tmux.compute.conf` | L3 overrides. Blue accent, SLURM widget, unbinds all nesting keys. |
| `slurm_info.sh` | Helper script displaying color-coded remaining SLURM job time in L3 status bar. |


Session persistence
--------------------

Sessions on L2 and L3 are ephemeral --- SLURM walltime limits and dev node CPU limits kill them unpredictably. [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) and [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) automatically save and restore session state (windows, panes, working directories, and simple programs like `htop` and `watch`) across these resets.

### Per-level behavior

| Level | Auto-save | Auto-restore | Save directory |
|-------|-----------|--------------|----------------|
| L1 (laptop) | off | off | `~/.tmux/resurrect-L1` |
| L2 (dev node) | every 15 min | on tmux start | `~/.tmux/resurrect-L2` |
| L3 (compute) | every 5 min | on tmux start | `~/.tmux/resurrect-L3` |

Separate save directories on NFS home prevent cross-level restore accidents. Manual save/restore is available on all levels via `<prefix> F5` / `<prefix> F6`.

### Per-pane bash history

Each tmux pane gets its own `HISTFILE` based on `session:window_index:pane_index`, stored in `~/.tmux/history-L{1,2,3}/`. Since resurrect preserves window and pane indices, history files map back to the correct pane after restore. Commands are flushed after every prompt (`history -a`), so no history is lost to ungraceful kills.

### What restores and what doesn't

**Automatic**: windows, panes, working directories, `htop`, `watch` (with original arguments), pane contents, bash history.

**Manual restart needed**: SSH connections, running scripts (Python, Snakemake), conda activations.


Ultrawide layout system
------------------------

For large/ultrawide monitors where a single full-width pane is uncomfortably wide.

### Triple column layout

Press `<prefix> 3` or open a new window (`C-t`) in ultrawide mode to get a three-column layout:

```
┌──────────┬────────────────┬──────────┐
│          │                │          │
│   side   │     center     │   side   │
│   pane   │   (120 cols)   │   pane   │
│          │                │          │
└──────────┴────────────────┴──────────┘
```

- The **center pane** has a fixed width (default: 120 columns, configurable via `@center_width`).
- **Side panes** share the remaining width equally and start with a blank (black) screen until activated by pressing any key --- friendly for OLED displays.
- The center pane is automatically focused.

### Ultrawide mode toggle

`<prefix> u` toggles ultrawide mode on/off. When the `UW` indicator is visible in the status bar, ultrawide mode is active:

- **On** (default): New windows auto-triple. `<prefix> 3` creates a triple layout.
- **Off** (laptop mode): New windows open full-width. `<prefix> 3` does a standard 50/50 horizontal split.

### Smart fallback

If the terminal is narrower than the configured center width, triple layout gracefully falls back to equal splits or stays single-pane.


Agent team layout
------------------

For multi-agent workflows (e.g., Claude Code agentic teams) where multiple agent panes need to coexist with your main working pane on an ultrawide monitor.

### The problem

Tools like Claude Code spawn agent teammates as vertical splits to the right of the lead pane. On ultrawide monitors this wastes space and makes agent output unreadable. You also lose your side panes (spacers) in the process.

### Team layout

Press `<prefix> t` after all agents have spawned to rearrange into a 3-column layout:

```
┌─────────┬──────┬──────┬─────────┐
│         │ term │ term │         │
│ agent 1 ├──────┴──────┤ agent 3 │
│         │             │         │
├─────────┤    lead     ├─────────┤
│         │  (120 cols) │         │
│ agent 2 │             │ agent 4 │
└─────────┴─────────────┴─────────┘
```

- **Lead** (center pane) gets 75% of the center column height.
- **Term** panes (your original side terminals) are tucked above the lead, taking 25%.
- **Agents** are distributed evenly across left and right columns.
- Accent colors are restored (Claude Code overrides them).

### Auto-focus

When navigating between panes with `C-h/j/k/l`:

- **Agent pane focused**: expands vertically to 60% of its column, siblings shrink.
- **Term pane focused**: expands horizontally (other term pane shrinks to ~4 cols), row grows to 50%.
- **Lead focused**: all panes reset to default sizes (agents equalize, term row shrinks to 25%).

This is triggered from `select_pane.sh` (not a tmux hook) to avoid conflicts with Claude Code's own pane management.

### Restoring

Press `<prefix> y` to kill all agent panes, move spacers back to their original side positions, and restore the standard triple layout with correct accent colors.

### Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `@team_spacer_split` | `h` | Spacer arrangement: `h` = side by side, `v` = stacked |
| `@center_width` | `120` | Center column width (shared with triple layout) |

### Important notes

- **No tmux hooks**: `after-split-window` and `pane-focus-in` hooks conflict with Claude Code's tmux management. The team layout is invoked manually.
- The workflow is: let agents spawn → wait for them to settle → `<prefix> t` to rearrange → work → `<prefix> y` to restore.


Copy mode
----------------------
There are some tweaks to copy mode and scrolling behavior, you should be aware of.

There is a root keybinding to enter Copy mode: `C-u`. Once in copy mode, you have several scroll controls:

- scroll by line: `M-Up`, `M-down`
- scroll by half screen: `M-PageUp`, `M-PageDown`
- scroll by whole screen: `PageUp`, `PageDown`
- scroll by mouse wheel, scroll step is changed from `5` lines to `2`

`Space` starts selection, `Enter` copies selection and exits copy mode. List all items in copy buffer using `prefix C-p`, and paste most recent item from buffer using `prefix p`.

`y` just copies selected text and is equivalent to `Enter`,  `Y` copies whole line, and `D` copies by the end of line.

Also, note, that when text is copied any trailing new lines are stripped. So, when you paste buffer in a command prompt, it will not be immediately executed.

You can also select text using mouse. Default behavior is to copy text and immediately cancel copy mode on `MouseDragEnd` event. This is annoying, because sometimes I select text just to highlight it, but tmux drops me out of copy mode and reset scroll by the end. I've changed this behavior, so `MouseDragEnd` does not execute `copy-selection-and-cancel` action. Text is copied, but copy mode is not cancelled and selection is not cleared. You can then reset selection by mouse click.

![copy and scroll](https://user-images.githubusercontent.com/768858/33231146-e390afc8-d1f8-11e7-80ad-6977fc3a5df7.gif)

Clipboard integration
----------------------

When you copy text inside tmux, it's stored in private tmux buffer, and not shared with system clipboard. Same is true when you SSH onto remote machine, and attach to tmux session there. Copied text will be stored in remote's session buffer, and not shared/transported to your local system clipboard. And sure, if you start local tmux session, then jump into nested remote session, copied text will not land in your system clipboard either.

This is one of the major limitations of tmux, that you might just decide to give up using it. Let's explore possible solutions:

- share text with OSX clipboard using **"pbcopy"**
- share text with OSX clipboard using [reattach-to-user-namespace](https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard) wrapper to access "pbcopy" from tmux environment (seems on OSX 10.11.5 ElCapitan this is not needed, since I can still access pbcopy without this wrapper).
- share text with X selection using **"xclip"** or **"xsel"** (store text in primary and clipboard selections). Works on Linux when DISPLAY variable is set.

All solutions above are suitable for sharing tmux buffer with system clipboard for local machine scenario. They still do not address remote session scenarios. What we need is some way to transport buffer from remote machine to the clipboard on the local machine, bypassing remote system clipboard.

There are 2 workarounds to address remote scenarios.

Use **[ANSI OSC 52](https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences)** escape [sequence](https://blog.vucica.net/2017/07/what-are-osc-terminal-control-sequences-escape-codes.html) to talk to controlling/parent terminal and pass buffer on local machine. Terminal should properly understand and handle OSC 52. Currently, only iTerm2 and XTerm support it. OSX Terminal, Gnome Terminal, Terminator do not.

Second workaround is really involved and consists of [local network listener and SSH remote tunneling](https://apple.stackexchange.com/a/258168):

- SSH onto target machine with remote tunneling on
    ```
    ssh -R 2222:localhost:3333  user@192.168.33.100
    ```
- When text is copied inside tmux (by mouse, by keyboard by whatever configured shortcut), pipe text to network socket on remote machine
    ```
    echo "buffer" | nc localhost 2222
    ```
- Buffer will be sent thru SSH remote tunnel from port `2222` on remote machine to port `3333` on local machine.
- Setup a service on local machine (systemd service unit with socket activation), which listens on network socket on port `3333`, and pipes any input to `pbcopy` command (or `xsel`, `xclip`).

This tmux-config does its best to integrate with system clipboard, trying all solutions above in order, and falling back to OSC 52 ANSI escape sequences in case of failure.

On OSX you might need to install `reattach-to-user-namespace` wrapper: `brew install reattach-to-user-namespace`, and make sure OSC 52 sequence handling is turned on in iTerm. (Preferences -> General -> Applications in Terminal may access clipboard).

On Linux, make sure `xclip` or `xsel` is installed. For remote scenarios, you would still need to setup network listener and use SSH remote tunneling, unless your terminal emulator supports OSC 52 sequences.


Themes and customization
------------------------

All colors related to theme are declared as variables. You can change them in `~/.tmux.conf`.

```
# This is a theme CONTRACT, you are required to define variables below
# Change values, but not remove/rename variables itself
color_dark="$color_black"
color_light="$color_white"
color_session_text="$color_blue"
color_status_text="colour245"
color_main="$color_orange"
color_secondary="$color_purple"
color_level_ok="$color_green"
color_level_warn="$color_yellow"
color_level_stress="$color_red"
color_window_off_indicator="colour088"
color_window_off_status_bg="colour238"
color_window_off_status_current_bg="colour254"
```

Note, that variables are not extracted to dedicated file, as it should be, because for some reasons, tmux does not see variable values after sourcing `theme.conf` file. Don't know why.
