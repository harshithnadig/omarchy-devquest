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
  ipcTarget: "harshith.devquest"
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
  property string avatar: "🌱"
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
    if (root.controller && root.controller.show) root.controller.show()
    root.refresh()
  }

  function openFromHotkey() {
    if (root.controller && root.controller.show) root.controller.show()
    root.refresh()
  }

  function close() {
    if (root.controller && root.controller.hide) root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
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
          if (data.avatar) root.avatar = data.avatar
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

  ColumnLayout {
    width: Style.space(360)
    spacing: Style.space(12)

    // Character Banner
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(12)

      Rectangle {
        width: 48
        height: 48
        radius: 24
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)
        border.color: root.accent
        border.width: 1.5

        Text {
          anchors.centerIn: parent
          text: root.avatar
          font.pixelSize: 24
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        RowLayout {
          Text {
            text: "Lv." + root.level
            font.family: root.fontFam
            font.pixelSize: 16
            font.bold: true
            color: root.accent
          }
          Text {
            text: root.title
            font.family: root.fontFam
            font.pixelSize: 15
            font.bold: true
            color: root.fg
          }
        }

        Text {
          text: "🔥 " + root.streak + "d Streak  •  🏆 " + root.questsCompleted + " Quests Done"
          font.family: root.fontFam
          font.pixelSize: 11
          color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.7)
        }
      }
    }

    // XP Bar
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 4

      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "EXPERIENCE"
          font.family: root.fontFam
          font.pixelSize: 10
          font.bold: true
          color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.6)
        }
        Item { Layout.fillWidth: true }
        Text {
          text: root.currentXp + " / " + root.maxXp + " XP"
          font.family: root.fontFam
          font.pixelSize: 11
          font.bold: true
          color: root.accent
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 6
        radius: 3
        color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1)

        Rectangle {
          height: parent.height
          width: Math.min(parent.width, Math.max(0, parent.width * (root.currentXp / Math.max(1, root.maxXp))))
          radius: 3
          color: root.accent
        }
      }
    }

    // HP / Mana
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Rectangle {
        Layout.fillWidth: true
        height: 28
        radius: 6
        color: Qt.rgba(0.2, 0.8, 0.4, 0.12)
        border.color: Qt.rgba(0.2, 0.8, 0.4, 0.3)
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          Text { text: "💚"; font.pixelSize: 11 }
          Text {
            text: "Streak HP: " + root.streak + "d"
            font.family: root.fontFam
            font.pixelSize: 11
            font.bold: true
            color: "#38ef7d"
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 28
        radius: 6
        color: Qt.rgba(0.2, 0.6, 1.0, 0.12)
        border.color: Qt.rgba(0.2, 0.6, 1.0, 0.3)
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          Text { text: "⚡"; font.pixelSize: 11 }
          Text {
            text: "Focus Mana: " + root.mana + "%"
            font.family: root.fontFam
            font.pixelSize: 11
            font.bold: true
            color: "#11998e"
          }
        }
      }
    }

    PanelSeparator { Layout.fillWidth: true }

    PanelSectionHeader { text: "Daily Quests" }

    // Quests Column
    Column {
      Layout.fillWidth: true
      spacing: 6

      Repeater {
        model: root.quests
        delegate: Rectangle {
          required property var modelData
          width: parent.width
          height: 44
          radius: 6
          color: modelData.claimed ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.04) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
          border.color: (modelData.progress >= modelData.goal && !modelData.claimed) ? root.accent : "transparent"
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            Text {
              text: modelData.claimed ? "✅" : (modelData.progress >= modelData.goal ? "⭐" : "⚔️")
              font.pixelSize: 14
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1

              Text {
                text: modelData.title
                font.family: root.fontFam
                font.pixelSize: 11
                font.bold: true
                color: modelData.claimed ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.5) : root.fg
              }

              Text {
                text: modelData.desc + " (" + modelData.progress + "/" + modelData.goal + ")"
                font.family: root.fontFam
                font.pixelSize: 9
                color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.6)
              }
            }

            Rectangle {
              visible: modelData.progress >= modelData.goal && !modelData.claimed
              width: 58
              height: 24
              radius: 4
              color: root.accent

              Text {
                anchors.centerIn: parent
                text: "Claim!"
                font.family: root.fontFam
                font.pixelSize: 10
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
              visible: !(modelData.progress >= modelData.goal && !modelData.claimed)
              text: "+" + modelData.xp + " XP"
              font.family: root.fontFam
              font.pixelSize: 10
              font.bold: true
              color: modelData.claimed ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.4) : root.accent
            }
          }
        }
      }
    }

    PanelSeparator { Layout.fillWidth: true }

    // Action Row
    RowLayout {
      Layout.fillWidth: true
      spacing: 6

      Rectangle {
        Layout.fillWidth: true
        height: 32
        radius: 6
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)
        border.color: root.accent
        border.width: 1

        RowLayout {
          anchors.centerIn: parent
          spacing: 6
          Text { text: "⚡"; font.pixelSize: 12 }
          Text {
            text: "Focus Sprint (+35 XP)"
            font.family: root.fontFam
            font.pixelSize: 11
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
        width: 32
        height: 32
        radius: 6
        color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1)

        Text {
          anchors.centerIn: parent
          text: "🔄"
          font.pixelSize: 12
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
