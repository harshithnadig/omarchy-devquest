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

  function refresh() {
    stateProc.command = ["bash", scriptPath, "get"]
    stateProc.running = true
  }

  Process {
    id: stateProc
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(value)
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
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  Binding {
    target: panelLoader.item
    property: "settings"
    value: root.settings
    when: panelLoader.item !== null
    restoreMode: Binding.RestoreNone
  }

  Binding {
    target: panelLoader.item
    property: "bar"
    value: root.bar
    when: panelLoader.item !== null
    restoreMode: Binding.RestoreNone
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.openFromHotkey) panelLoader.item.openFromHotkey()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

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

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: (root.settings && root.settings.showLevelInBar === false) ? root.avatar : (root.avatar + " Lv." + root.level)
    tooltipText: "DevQuest: Lv." + root.level + " " + root.title + " (" + root.currentXp + "/" + root.maxXp + " XP) • 🔥 " + root.streak + "d Streak"
    onPressed: root.togglePanel()
  }
}
