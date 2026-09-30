-- Persistent dual-monitor workspace banks (Hyprland Lua config).
-- Installed and managed by omarchy-dual-monitor-workspaces
-- (https://github.com/LinuxGamerUK/omarchy-dual-monitor-workspaces).
-- Remove with the plugin's scripts/uninstall.sh.
--
-- Monitors are ordered left-to-right (x position, then name), so no monitor
-- names are hardcoded here:
--   monitor 1 -> workspaces 1..5
--   monitor 2 -> workspaces 6..10
--   one monitor -> all 10 on that screen
--   three+ monitors -> only the first two get banks
--
-- Rules only land when the compositor knows its outputs. At a cold boot the
-- config parses before monitors are enumerated, so the banks are also
-- (re)applied on "hyprland.start" and "monitor.layout_changed" (hotplug,
-- dock, re-arrangement). hl.workspace_rule replaces its rule in place, so
-- re-applying is idempotent. Requires Hyprland 0.55+.

local BANK_SIZE = 5
local BANK_COUNT = 2

local function apply_banks()
  local monitors = hl.get_monitors()
  if monitors == nil then return end

  table.sort(monitors, function(a, b)
    if a.x == b.x then return a.name < b.name end
    return a.x < b.x
  end)

  for bank = 1, BANK_COUNT do
    local monitor = monitors[bank]
    if monitor ~= nil and monitor.name ~= nil then
      local first = (bank - 1) * BANK_SIZE + 1
      for workspace = first, first + BANK_SIZE - 1 do
        hl.workspace_rule({
          workspace = tostring(workspace),
          monitor = monitor.name,
          persistent = true,
          default = workspace == first,
        })
      end
    end
  end

  -- Single monitor: stack the second bank on the same output so moving to
  -- workspaces 6..10 still lands on the only screen instead of floating.
  if #monitors == 1 and monitors[1].name ~= nil then
    for workspace = BANK_SIZE + 1, BANK_SIZE * BANK_COUNT do
      hl.workspace_rule({
        workspace = tostring(workspace),
        monitor = monitors[1].name,
        persistent = true,
      })
    end
  end
end

-- Parse time: covers hyprctl reload and config re-parses after hotplug.
apply_banks()

-- Cold boot: the parse above saw zero monitors; re-apply once the session
-- (and its outputs) are up.
hl.on("hyprland.start", apply_banks)

-- Output arrival/removal/geometry changes that did not re-run the parse.
hl.on("monitor.layout_changed", apply_banks)