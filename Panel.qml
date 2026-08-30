import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "harshith.devquest"
  ipcTarget: "harshith.devquest.panel"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property string scriptPath:
    Qt.resolvedUrl("devquest-engine.sh").toString().replace(/^file:\/\//, "")

  property int level: 2
  property int currentXp: 100
  property int maxXp: 200
  property int streak: 1
  property int mana: 100
  property int totalCommits: 0
  property int questsCompleted: 1
  property string title: "Novice Coder"
  property string avatarGlyph: "󰊴"
  property var quests: [
    { id: "commit_quest", title: "Daily Forge", desc: "Make 3 commits today", progress: 0, goal: 3, xp: 100, claimed: false },
    { id: "sprint_quest", title: "Deep Work Sprint", desc: "Complete a 25m focus sprint", progress: 0, goal: 1, xp: 75, claimed: false },
    { id: "pr_quest", title: "Open Source Hero", desc: "Submit or review a PR", progress: 1, goal: 1, xp: 200, claimed: true }
  ]

  readonly property color fg: bar ? bar.foreground : Color.popups.text
  readonly property color bg: Color.popups.background
  readonly property color accent: Color.accent
  readonly property string fontFam: bar ? bar.fontFamily : Style.font.family

  function open() {
    root.controller.show()
    root.refresh()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  function refresh() {
    stateProc.command = ["bash", scriptPath, "get"]
    stateProc.running = true
  }

  function addSprint() {
    actionProc.command = ["bash", scriptPath, "sprint"]
    actionProc.running = true
  }

  function claimQuest(id) {
    actionProc.command = ["bash", scriptPath, "claim-quest", id]
    actionProc.running = true
  }

  Process {
    id: stateProc
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          if (data.level) root.level = data.level
          if (data.current_xp !== undefined) root.currentXp = data.current_xp
          if (data.max_xp) root.maxXp = data.max_xp
          if (data.streak) root.streak = data.streak
          if (data.mana !== undefined) root.mana = data.mana
          if (data.title) root.title = data.title
          if (data.quests) root.quests = data.quests
          if (data.quests_completed !== undefined) root.questsCompleted = data.quests_completed
        } catch(e) {}
      }
    }
  }

  Process {
    id: actionProc
    running: false
    onExited: root.refresh()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight, Style.space(500))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
    }

    ScrollView {
      id: scrollArea
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.bottomMargin: -panel.padding
      clip: true
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
      ScrollBar.vertical.policy: panelColumn.implicitHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

      Column {
        id: panelColumn
        width: scrollArea.availableWidth
        spacing: Style.space(12)

        // Hero Row
        Item {
          width: parent.width
          implicitHeight: heroIcon.implicitHeight

          Text {
            id: heroIcon
            textFormat: Text.PlainText
            text: "󰊴"
            color: root.accent
            font.family: root.fontFam
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Row {
              spacing: Style.space(6)
              Text {
                textFormat: Text.PlainText
                text: "Lv." + root.level
                color: root.accent
                font.family: root.fontFam
                font.pixelSize: Style.font.title
                font.bold: true
              }
              Text {
                textFormat: Text.PlainText
                text: root.title
                color: root.fg
                font.family: root.fontFam
                font.pixelSize: Style.font.title
                font.bold: true
              }
            }

            Text {
              textFormat: Text.PlainText
              text: "🔥 " + root.streak + "d Streak  •  🏆 " + root.questsCompleted + " Quests Done"
              color: Qt.darker(root.fg, 1.4)
              font.family: root.fontFam
              font.pixelSize: Style.font.caption
            }
          }
        }

        // XP Progress Bar
        Column {
          width: parent.width
          spacing: Style.space(4)

          Item {
            width: parent.width
            implicitHeight: xpLabel.implicitHeight

            Text {
              id: xpLabel
              textFormat: Text.PlainText
              text: "EXPERIENCE"
              color: Qt.darker(root.fg, 1.5)
              font.family: root.fontFam
              font.pixelSize: Style.font.caption
              font.bold: true
              anchors.left: parent.left
            }

            Text {
              textFormat: Text.PlainText
              text: root.currentXp + " / " + root.maxXp + " XP"
              color: root.accent
              font.family: root.fontFam
              font.pixelSize: Style.font.caption
              font.bold: true
              anchors.right: parent.right
            }
          }

          Rectangle {
            width: parent.width
            height: Style.space(6)
            radius: Style.space(3)
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1)

            Rectangle {
              height: parent.height
              width: Math.min(parent.width, Math.max(0, parent.width * (root.currentXp / Math.max(1, root.maxXp))))
              radius: Style.space(3)
              color: root.accent
            }
          }
        }

        // Vitals: HP & Mana
        Row {
          width: parent.width
          spacing: Style.space(8)

          Rectangle {
            width: (parent.width - Style.space(8)) / 2
            height: Style.space(30)
            radius: Style.space(6)
            color: Qt.rgba(0.2, 0.8, 0.4, 0.12)
            border.color: Qt.rgba(0.2, 0.8, 0.4, 0.3)
            border.width: 1

            Row {
              anchors.centerIn: parent
              spacing: Style.space(6)
              Text { textFormat: Text.PlainText; text: "💚"; font.pixelSize: Style.font.caption }
              Text {
                textFormat: Text.PlainText
                text: "Streak: " + root.streak + "d"
                font.family: root.fontFam
                font.pixelSize: Style.font.caption
                font.bold: true
                color: "#38ef7d"
              }
            }
          }

          Rectangle {
            width: (parent.width - Style.space(8)) / 2
            height: Style.space(30)
            radius: Style.space(6)
            color: Qt.rgba(0.2, 0.6, 1.0, 0.12)
            border.color: Qt.rgba(0.2, 0.6, 1.0, 0.3)
            border.width: 1

            Row {
              anchors.centerIn: parent
              spacing: Style.space(6)
              Text { textFormat: Text.PlainText; text: "⚡"; font.pixelSize: Style.font.caption }
              Text {
                textFormat: Text.PlainText
                text: "Mana: " + root.mana + "%"
                font.family: root.fontFam
                font.pixelSize: Style.font.caption
                font.bold: true
                color: "#11998e"
              }
            }
          }
        }

        PanelSeparator { width: parent.width }

        PanelSectionHeader { text: "Daily Quests" }

        // Quests List
        Column {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.quests
            delegate: Rectangle {
              required property var modelData
              width: panelColumn.width
              height: Style.space(48)
              radius: Style.space(6)
              color: modelData.claimed ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.04) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
              border.color: (modelData.progress >= modelData.goal && !modelData.claimed) ? root.accent : "transparent"
              border.width: 1

              Item {
                anchors.fill: parent
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)

                Text {
                  id: questIcon
                  textFormat: Text.PlainText
                  text: modelData.claimed ? "✅" : (modelData.progress >= modelData.goal ? "⭐" : "⚔️")
                  font.pixelSize: Style.font.body
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                  anchors.left: questIcon.right
                  anchors.leftMargin: Style.space(10)
                  anchors.right: rewardArea.left
                  anchors.rightMargin: Style.space(8)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(2)

                  Text {
                    textFormat: Text.PlainText
                    text: modelData.title
                    font.family: root.fontFam
                    font.pixelSize: Style.font.body
                    font.bold: true
                    color: modelData.claimed ? Qt.darker(root.fg, 1.5) : root.fg
                  }

                  Text {
                    textFormat: Text.PlainText
                    text: modelData.desc + " (" + modelData.progress + "/" + modelData.goal + ")"
                    font.family: root.fontFam
                    font.pixelSize: Style.font.caption
                    color: Qt.darker(root.fg, 1.4)
                  }
                }

                Item {
                  id: rewardArea
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  width: claimBtn.visible ? claimBtn.width : xpTxt.implicitWidth
                  height: Style.space(26)

                  Rectangle {
                    id: claimBtn
                    visible: modelData.progress >= modelData.goal && !modelData.claimed
                    width: Style.space(64)
                    height: parent.height
                    radius: Style.space(4)
                    color: root.accent

                    Text {
                      anchors.centerIn: parent
                      textFormat: Text.PlainText
                      text: "Claim!"
                      font.family: root.fontFam
                      font.pixelSize: Style.font.caption
                      font.bold: true
                      color: "#ffffff"
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.claimQuest(modelData.id)
                    }
                  }

                  Text {
                    id: xpTxt
                    visible: !(modelData.progress >= modelData.goal && !modelData.claimed)
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: "+" + modelData.xp + " XP"
                    font.family: root.fontFam
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    color: modelData.claimed ? Qt.darker(root.fg, 1.5) : root.accent
                  }
                }
              }
            }
          }
        }

        PanelSeparator { width: parent.width }

        // Action Buttons
        Row {
          width: parent.width
          spacing: Style.space(8)

          Rectangle {
            width: parent.width - Style.space(44)
            height: Style.space(34)
            radius: Style.space(6)
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)
            border.color: root.accent
            border.width: 1

            Row {
              anchors.centerIn: parent
              spacing: Style.space(6)
              Text { textFormat: Text.PlainText; text: "⚡"; font.pixelSize: Style.font.body }
              Text {
                textFormat: Text.PlainText
                text: "Focus Sprint (+35 XP)"
                font.family: root.fontFam
                font.pixelSize: Style.font.body
                font.bold: true
                color: root.accent
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.addSprint()
            }
          }

          Rectangle {
            width: Style.space(36)
            height: Style.space(34)
            radius: Style.space(6)
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1)

            Text {
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: "🔄"
              font.pixelSize: Style.font.body
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.refresh()
            }
          }
        }
      }
    }
  }
}
