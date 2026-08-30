import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "harshith.devquest"

  readonly property string scriptPath:
    Qt.resolvedUrl("devquest-engine.sh").toString().replace(/^file:\/\//, "")

  property int level: 1
  property int currentXp: 0
  property int maxXp: 100
  property int streak: 1
  property string title: "Novice Coder"
  property string avatar: "🌱"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function refresh() {
    stateProc.command = ["bash", scriptPath, "get"]
    stateProc.running = true
  }

  Process {
    id: stateProc
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          root.level = data.level || 1
          root.currentXp = data.current_xp || 0
          root.maxXp = data.max_xp || 100
          root.streak = data.streak || 1
          root.title = data.title || "Novice Coder"
          root.avatar = data.avatar || "🌱"
        } catch(e) {}
      }
    }
  }

  Timer {
    interval: 15000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: root.moduleName
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: (root.settings && root.settings.showLevelInBar === false) ? root.avatar : (root.avatar + " Lv." + root.level)
    tooltipText: "DevQuest: Lv." + root.level + " " + root.title + " (" + root.currentXp + "/" + root.maxXp + " XP) • 🔥 " + root.streak + "d Streak"
    active: root.opened
    useActiveColor: true
    activeColor: Color.accent
    onPressed: function(b) { root.togglePanel() }
  }
}
