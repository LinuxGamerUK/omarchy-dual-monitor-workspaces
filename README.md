# Dual Monitor Workspaces for Omarchy

Persistent **numbered** workspace banks for Omarchy Quattro (Hyprland 0.55+):
workspaces **1–5 live on the first monitor**, **6–10 on the second** — and the
bar shows a numbered bank scoped to each screen.

![Per-monitor numbered workspace banks](assets/screenshot.png)

- Super-based navigation: `SUPER+1..5` for the first screen, `SUPER+6..0` for
  the second; add `SHIFT` to move the focused window, `SHIFT+ALT` to move it
  without following (all Omarchy default binds, nothing to remap).
- The bar shows numbers instead of dots — bright when focused, full-strength
  when occupied, dimmed when empty.
- Clicking a number activates that workspace on that screen's bank.
- Monitors are ordered **left-to-right automatically** — no monitor names to
  edit. Single-monitor setups get all ten workspaces stacked on the one screen.

Forked from [derluke/omarchy-dual-monitor-workspaces](https://github.com/derluke/omarchy-dual-monitor-workspaces)
(MIT, © Lukas Innig). This fork replaces the external
`split-monitor-workspaces` plugin with Hyprland's **native persistent
workspace rules** and renders numbered banks instead of dots.

## How it works

Two pieces, both optional and independent:

1. **`scripts/install.sh`** wires a small Lua file into
   `~/.config/hypr/`. It declares Hyprland 0.55+ *workspace rules*
   (`hl.workspace_rule({ persistent = true, monitor = ... })`) that pin
   workspaces 1–5 to the first monitor and 6–10 to the second, left-to-right.
   Native rules, so **no external Hyprland plugin** (nothing to clone, no
   release-branch matching against your Hyprland version).
2. **The bar widget** reflects `Hyprland.workspaces` per screen and activates
   the clicked workspace via the same Hyprland IPC dispatch the built-in
   `omarchy.workspaces` widget uses.

Keybinds come free: Omarchy's defaults already map `SUPER+1..0` (switch),
`SUPER+SHIFT+1..0` (move window), `SUPER+SHIFT+ALT+1..0` (move silently) to
workspaces 1–10. Once those workspaces are persistent and monitor-bound, the
keybinds target the right screens by themselves.

## Install

```sh
omarchy plugin add https://github.com/LinuxGamerUK/omarchy-dual-monitor-workspaces.git --enable
omarchy plugin disable omarchy.workspaces
omarchy bar move io.github.linuxgameruk.dual-monitor-workspaces --section left --after omarchy.menu
```

Then run the shipped installer (it is user-run on purpose — the plugin itself
never touches your Hyprland config):

```sh
bash ~/.config/omarchy/plugins/io.github.linuxgameruk.dual-monitor-workspaces/scripts/install.sh
```

The script is idempotent, backs up `hyprland.lua` before editing it, validates
the result with `hyprctl configerrors`, and prints the resulting persistent
banks.

## Settings

In `omarchy bar edit` (or `~/.config/omarchy/shell.json`), the widget takes:

| Key | Type | Default | Meaning |
|---|---|---|---|
| `perBank` | integer (1–9) | `5` | Workspaces per bank. Bank 1 covers `1..perBank`, bank 2 covers `perBank+1..2*perBank`. Re-run `scripts/install.sh` after changing this. |

## Remove

```sh
bash ~/.config/omarchy/plugins/io.github.linuxgameruk.dual-monitor-workspaces/scripts/uninstall.sh
omarchy plugin remove io.github.linuxgameruk.dual-monitor-workspaces
omarchy plugin enable omarchy.workspaces --section left
```

`uninstall.sh` strips the wiring block and the rules file, then reloads
Hyprland. Existing windows and workspaces are untouched.

## Notes and limitations

- `omarchy refresh hyprland` rewrites `hyprland.lua` — re-run
  `scripts/install.sh` afterwards.
- Rules re-apply themselves on boot (`hyprland.start`) and on monitor
  hotplug/layout changes (`monitor.layout_changed`), because at a cold boot
  the Hyprland config parses before outputs are enumerated.
- Monitors beyond the first two get no banks (they still show their currently
  active workspace via other means; this widget draws nothing on them).
- Requires Hyprland **0.55 or newer** (Lua config + `hl.workspace_rule`
  persistent rules). Omarchy current ships 0.56.x — fine.

## Permissions and dependencies

- The bar widget runs inside `omarchy-shell`, reads Quickshell's Hyprland
  workspace/monitor models, and dispatches workspace activation through the
  same channel as the built-in widget. It executes **no shell commands**,
  makes **no network requests**, needs **no elevated privileges**.
- `scripts/install.sh` / `uninstall.sh` run as **your user only**: they write
  under `~/.config/hypr/` and call `hyprctl reload` / `hyprctl configerrors` /
  `hyprctl -j workspaces`. No sudo, no systemd units, no downloads at runtime.

## Runtime requirements

- Omarchy 4 (Quattro) with the built-in bar
- Hyprland 0.55+
- Quickshell's Hyprland integration (bundled with Omarchy's shell)

## License

MIT — © Lukas Innig (upstream) + Gavin Hayes (fork changes). See `LICENSE`.