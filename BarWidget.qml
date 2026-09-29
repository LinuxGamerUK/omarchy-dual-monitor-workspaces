import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

// Numbered per-monitor workspace banks for the Omarchy bar.
//
// Each bar surface shows its own screen's bank: the machine's monitors are
// ordered left-to-right (x, then name) and bank N owns workspaces
// (N-1)*perBank+1 .. N*perBank. The bars themselves follow whatever the
// compositor reports, so nothing is hardcoded to a display name:
//   two monitors -> bank 1 shows 1..5, bank 2 shows 6..10
//   one monitor  -> a single bar shows 1..10
//
// The persistent banks themselves are wired up by scripts/install.sh
// (Hyprland workspace rules); this widget only reflects and activates
// workspaces - it runs no shell commands and makes no network requests.
BarWidget {
  id: root
  moduleName: "io.github.linuxgameruk.dual-monitor-workspaces"

  readonly property int perBank: Math.max(1, Number(root.setting("perBank", 5)))
  readonly property string screenName: root.QsWindow.window && root.QsWindow.window.screen
    ? root.QsWindow.window.screen.name : ""

  // Index of this screen in the left-to-right monitor order (1-based).
  // 0 when the screen is not (yet) reported by Hyprland.
  readonly property int bankIndex: {
    var monitors = Hyprland.monitors.values
    for (var i = 0; i < monitors.length; i++) {
      if (monitors[i].name === root.screenName) return i + 1
    }
    return 0
  }

  function workspacesForBank() {
    var out = []
    if (root.bankIndex <= 0) return out

    var from = (root.bankIndex - 1) * root.perBank + 1
    var to = from + root.perBank - 1
    var values = Hyprland.workspaces.values

    for (var id = from; id <= to; id++) {
      var workspace = null
      for (var i = 0; i < values.length; i++) {
        if (values[i].id === id) { workspace = values[i]; break }
      }
      out.push({
        id: id,
        workspace: workspace,
        occupied: workspace !== null && workspace.toplevels.values.length > 0,
        active: workspace !== null && workspace.active
      })
    }
    return out
  }

  function focusWorkspace(id) {
    // Same path the built-in omarchy.workspaces widget uses.
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote('hl.dsp.focus({ workspace = "' + id + '" })'))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspacesForBank().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspacesForBank()

      WidgetButton {
        required property var modelData

        readonly property int wsId: modelData.id
        readonly property bool active: modelData.active
        // Persistent workspaces stay visible even when empty; on setups
        // without the rules installed, empty ids fade instead.
        readonly property bool visible_empty: modelData.occupied || modelData.workspace !== null

        bar: root.bar
        text: active ? "\uDB85\uDCFB" : (wsId === 10 ? "0" : String(wsId))
        opacity: active || modelData.occupied ? 1 : (visible_empty ? 0.5 : 0.25)
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(wsId) }
      }
    }
  }
}