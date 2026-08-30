import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "harshith.devquest"

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

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

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
    text: "󰊴"
    active: root.opened
    useActiveColor: true
    activeColor: Color.accent
    tooltipText: panelLoader.item ? ("DevQuest: Lv." + panelLoader.item.level + " " + panelLoader.item.title + " (" + panelLoader.item.currentXp + "/" + panelLoader.item.maxXp + " XP)") : "DevQuest RPG"

    onPressed: function(b) {
      if (b === Qt.MiddleButton) {
        if (panelLoader.item) panelLoader.item.refresh()
      } else {
        root.togglePanel()
      }
    }
  }
}
