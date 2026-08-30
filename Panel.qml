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

  readonly property string scriptPath:
    Qt.resolvedUrl("devquest-engine.sh").toString().replace(/^file:\/\//, "")

  property int level: 1
  property int currentXp: 0
  property int maxXp: 100
  property int streak: 1
  property int mana: 100
  property int totalCommits: 0
  property int questsCompleted: 0
  property string title: "Novice Coder"
  property string avatar: "🌱"
  property var quests: []

  readonly property color fg: bar ? bar.foreground : Color.popups.text
  readonly property color bg: Color.popups.background
  readonly property color accent: Color.accent
  readonly property string fontFam: bar ? bar.fontFamily : Style.font.family

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
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(value)
          root.level = data.level || 1
          root.currentXp = data.current_xp || 0
          root.maxXp = data.max_xp || 100
          root.streak = data.streak || 1
          root.mana = data.mana || 100
          root.totalCommits = data.total_commits || 0
          root.questsCompleted = data.quests_completed || 0
          root.title = data.title || "Novice Coder"
          root.avatar = data.avatar || "🌱"
          root.quests = data.quests || []
        } catch(e) {}
      }
    }
  }

  Process {
    id: actionProc
    onExited: root.refresh()
  }

  onOpenedChanged: {
    if (opened) root.refresh()
  }

  contentItem: Rectangle {
    implicitWidth: 380
    implicitHeight: 460
    color: root.bg
    radius: 12
    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.3)
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 12

      // Header: Character Avatar & Level Title
      RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
          width: 52
          height: 52
          radius: 26
          color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)
          border.color: root.accent
          border.width: 1.5

          Text {
            anchors.centerIn: parent
            text: root.avatar
            font.pixelSize: 26
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          RowLayout {
            Text {
              text: "Lv." + root.level
              font.family: root.fontFam
              font.pixelSize: 18
              font.bold: true
              color: root.accent
            }
            Text {
              text: root.title
              font.family: root.fontFam
              font.pixelSize: 16
              font.bold: true
              color: root.fg
            }
          }

          Text {
            text: "🔥 " + root.streak + " Day Streak  •  🏆 " + root.questsCompleted + " Quests Done"
            font.family: root.fontFam
            font.pixelSize: 12
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.7)
          }
        }
      }

      // XP Progress Bar
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
          height: 8
          radius: 4
          color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1)

          Rectangle {
            height: parent.height
            width: Math.min(parent.width, Math.max(0, parent.width * (root.currentXp / Math.max(1, root.maxXp))))
            radius: 4
            color: root.accent
          }
        }
      }

      // Vitals (HP / Mana)
      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
          Layout.fillWidth: true
          height: 32
          radius: 6
          color: Qt.rgba(0.2, 0.8, 0.4, 0.12)
          border.color: Qt.rgba(0.2, 0.8, 0.4, 0.3)
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            Text { text: "💚"; font.pixelSize: 12 }
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
          height: 32
          radius: 6
          color: Qt.rgba(0.2, 0.6, 1.0, 0.12)
          border.color: Qt.rgba(0.2, 0.6, 1.0, 0.3)
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            Text { text: "⚡"; font.pixelSize: 12 }
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

      // Section Divider
      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1)
      }

      Text {
        text: "DAILY QUESTS"
        font.family: root.fontFam
        font.pixelSize: 11
        font.bold: true
        color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.6)
      }

      // Quests List
      ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 8
        model: root.quests

        delegate: Rectangle {
          required property var modelData
          width: ListView.view.width
          height: 52
          radius: 8
          color: modelData.claimed ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.04) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
          border.color: (modelData.progress >= modelData.goal && !modelData.claimed) ? root.accent : "transparent"
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Text {
              text: modelData.claimed ? "✅" : (modelData.progress >= modelData.goal ? "⭐" : "⚔️")
              font.pixelSize: 16
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              Text {
                text: modelData.title
                font.family: root.fontFam
                font.pixelSize: 12
                font.bold: true
                color: modelData.claimed ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.5) : root.fg
              }

              Text {
                text: modelData.desc + " (" + modelData.progress + "/" + modelData.goal + ")"
                font.family: root.fontFam
                font.pixelSize: 10
                color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.6)
              }
            }

            // Claim / Reward Pill
            Rectangle {
              visible: modelData.progress >= modelData.goal && !modelData.claimed
              width: 72
              height: 28
              radius: 6
              color: root.accent

              Text {
                anchors.centerIn: parent
                text: "Claim!"
                font.family: root.fontFam
                font.pixelSize: 11
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
              font.pixelSize: 11
              font.bold: true
              color: modelData.claimed ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.4) : root.accent
            }
          }
        }
      }

      // Footer Actions
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
          Layout.fillWidth: true
          height: 36
          radius: 8
          color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)
          border.color: root.accent
          border.width: 1

          RowLayout {
            anchors.centerIn: parent
            spacing: 6
            Text { text: "⚡"; font.pixelSize: 13 }
            Text {
              text: "Focus Sprint (+35 XP)"
              font.family: root.fontFam
              font.pixelSize: 12
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
          width: 36
          height: 36
          radius: 8
          color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1)

          Text {
            anchors.centerIn: parent
            text: "🔄"
            font.pixelSize: 14
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
