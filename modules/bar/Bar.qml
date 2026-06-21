import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

Scope {
  id: root
  property var theme: DefaultTheme {}
  property bool barVisible: true

  // MPRIS active player
  property var activePlayer: {
    const players = Mpris.players.values;
    if (!players || players.length === 0) return null;
    for (const p of players) {
      if (p.playbackState === MprisPlaybackState.Playing) return p;
    }
    return players[0];
  }

  IpcHandler {
    target: "bar"
    function toggle(): void { root.barVisible = !root.barVisible; }
  }

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

  // Brightness state
  property real brightnessValue: 0
  property real brightnessMax: 1

  FileView {
    id: brightnessFile
    path: ""
    watchChanges: true
    onFileChanged: brightnessReadProc.running = true
  }

  Process {
    id: brightnessReadProc
    command: ["brightnessctl", "get"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const val = parseInt(text.trim());
        if (!isNaN(val) && root.brightnessMax > 0)
          root.brightnessValue = val / root.brightnessMax;
      }
    }
  }

  Process {
    id: brightnessSetProc
    running: false
  }

  Process {
    id: backlightDiscovery
    command: ["sh", "-c", "p=$(ls -d /sys/class/backlight/*/brightness 2>/dev/null | head -1); [ -n \"$p\" ] && echo \"$p\" && cat \"${p%brightness}max_brightness\""]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        if (lines.length >= 2) {
          const max = parseInt(lines[1]);
          if (!isNaN(max) && max > 0) root.brightnessMax = max;
          brightnessFile.path = lines[0];
          brightnessReadProc.running = true;
        }
      }
    }
  }

  Variants {
    model: Quickshell.screens
    PanelWindow {
      required property var modelData
      screen: modelData
      visible: root.barVisible
      margins.top: 5
      margins.bottom: -1
      margins.left: 200
      margins.right: 200
      implicitHeight: 28
      color: "transparent"

      anchors {
        top: true
        left: true
        right: true
      }

      Rectangle {
        id: barBackground
        anchors.fill: parent
        color: root.theme.bgBase
		topLeftRadius: 20
        topRightRadius: 20
        bottomLeftRadius: 20
        bottomRightRadius: 20

      }

      property string fontFamily: "CodeNewRoman Nerd Font"
      property string fontMonoFamily: "CaskadiaCove Nerd Font"
      property int fontSize: 14
      property int fontMonoSize: 14

      Item {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        // ==================== LEFT SECTION ====================
        Row {
          id: leftSection
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: 15

          // Launcher
          Rectangle {
            width: 15
            height: 34
            color: launcherMouse.containsMouse ? root.theme.bgBase : root.theme.bgBase
            border.width: 2
            border.color: root.theme.bgBase

            MouseArea {
              id: launcherMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Hyprland.dispatch("exec qs -c reze ipc call launcher toggle")
            }

            Text {
              text: " "
              anchors.centerIn: parent
              color: root.theme.textPrimary
			  font.family: "CaskadiaCove Nerd Font"
			  font.pixelSize: 15
            }
          }

          Text {
            text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
            color: root.theme.textPrimary
            font.pixelSize: 13
            font.family: "Firacode Nerd Font"
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 300)
            anchors.verticalCenter: parent.verticalCenter
          }

          // Random status text
          Rectangle {
            width: 150
            height: 35
            color: root.theme.bgBase
            Text {
              id: statusLabel
              text: getRandomText()
              color: root.theme.accentOrange
              anchors.verticalCenter: parent.verticalCenter
              font.family: "DaddyTimeMono Nerd Font"
              font.pixelSize: 11          
            }

            MouseArea {
              id: statusLabelm
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Hyprland.dispatch("exec qs -c shell ipc call launcher toggle")
            }

            Timer {
              interval: 30000
              running: true
              repeat: true
              onTriggered: statusLabel.text = getRandomText()
            }
          }
        }

        // ==================== CENTER SECTION - Workspaces ====================
        Row {
          anchors.centerIn: parent
          spacing: 4

          Repeater {
            model: Hyprland.workspaces
            Rectangle {
              id: wsPill
              required property var modelData
              property bool urgentBlink: false

              width: modelData.focused ? 32 : 24
              height: 24
              radius: 12
              color: modelData.focused ? root.theme.bgBase :
                     modelData.urgent && urgentBlink ? root.theme.accentRed : root.theme.bgBase

              Text {
                anchors.centerIn: parent
                text: toRoman(modelData.id)
                color: wsPill.modelData.focused ? root.theme.accentPrimary : root.theme.textPrimary
                font.pixelSize: 13
                font.family: "CaskadiaCove Nerd Font"
                font.bold: wsPill.modelData.focused
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: wsPill.modelData.activate()
              }
            }
          }
        }

        // ==================== RIGHT SECTION ====================
        Row {
          id: rightSection
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          // Now Playing (media) - moved to right as requested
          Rectangle {
            height: 24
            radius: 12
            color: root.theme.bgSurface
            visible: root.activePlayer !== null

            Row {
              id: nowPlayingContent
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: 8
              spacing: 6

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.activePlayer && root.activePlayer.isPlaying ? "󰐊" : "󰏤"
                color: root.theme.accentPrimary
                font.pixelSize: 14
                font.family: "Hack Nerd Font"
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                  if (!root.activePlayer) return "";
                  const artist = root.activePlayer.trackArtist || "";
                  const title = root.activePlayer.trackTitle || "";
                  return artist ? artist + " - " + title : title;
                }
                color: root.theme.textPrimary
                font.pixelSize: 11
                font.family: "Hack Nerd Font"
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 200)
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.activePlayer.togglePlaying()
            }
          }

          // Volume
          Rectangle {
            height: 24
            width: volContent.width + 12
            radius: 12
            color: root.theme.bgSurface

            Row {
              id: volContent
              anchors.centerIn: parent
              spacing: 6
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                  const sink = Pipewire.defaultAudioSink;
                  if (!sink || !sink.audio || sink.audio.muted || sink.audio.volume <= 0) return "󰖁";
                  if (sink.audio.volume < 0.33) return "󰕿";
                  if (sink.audio.volume < 0.66) return "󰖀";
                  return "󰕾";
                }
                color: {
                  const sink = Pipewire.defaultAudioSink;
                  if (!sink || !sink.audio || sink.audio.muted) return root.theme.textMuted;
                  return root.theme.accentPrimary;
                }
                font.pixelSize: 14
                font.family: "Hack Nerd Font"
              }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                  const sink = Pipewire.defaultAudioSink;
                  if (!sink || !sink.audio) return "–";
                  if (sink.audio.muted) return "Mute";
                  return Math.round(sink.audio.volume * 100) + "%";
                }
                color: root.theme.textPrimary
                font.pixelSize: 11
                font.family: "Hack Nerd Font"
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton
              onClicked: {
                const sink = Pipewire.defaultAudioSink;
                if (sink && sink.audio) sink.audio.muted = !sink.audio.muted;
              }
              onWheel: (wheel) => {
                const sink = Pipewire.defaultAudioSink;
                if (!sink || !sink.audio) return;
                const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                sink.audio.volume = Math.max(0, Math.min(1.5, sink.audio.volume + delta));
              }
            }
          }

          // Brightness
          Rectangle {
            height: 24
            width: brightContent.width + 12
            radius: 12
            color: root.theme.bgSurface
            visible: brightnessFile.path !== ""

            Row {
              id: brightContent
              anchors.centerIn: parent
              spacing: 6
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰃠"
                color: root.theme.accentOrange
                font.pixelSize: 14
                font.family: "Hack Nerd Font"
              }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(root.brightnessValue * 100) + "%"
                color: root.theme.textPrimary
                font.pixelSize: 11
                font.family: "Hack Nerd Font"
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onWheel: (wheel) => {
                brightnessSetProc.command = wheel.angleDelta.y > 0
                  ? ["brightnessctl", "set", "5%+"]
                  : ["brightnessctl", "set", "5%-"];
                brightnessSetProc.running = true;
              }
            }
          }

          // System Info
          Row {
            id: sysInfo
            spacing: 4

            // CPU
            Rectangle {
              height: 24
              width: cpuContent.width + 12
              radius: 12
              color: root.theme.bgSurface

              Row {
                id: cpuContent
                anchors.centerIn: parent
                spacing: 6
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: " "
                  color: root.theme.accentOrange
                  font.pixelSize: 14
                  font.family: "Hack Nerd Font"
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: SystemInfo.cpuUsage
                  color: root.theme.textPrimary
                  font.pixelSize: 11
                  font.family: "Hack Nerd Font"
                }
              }
            }

            // // Network
            // Rectangle {
            //   height: 24
            //   width: netContent.width + 12
            //   radius: 12
            //   color: root.theme.bgSurface
            //
            //   Row {
            //     id: netContent
            //     anchors.centerIn: parent
            //     spacing: 6
            //     Text {
            //       anchors.verticalCenter: parent.verticalCenter
            //       text: {
            //         if (SystemInfo.networkType === "ethernet") return "󰈀"
            //         if (SystemInfo.networkType === "wifi") return "󰖩"
            //         return "󰖪"
            //       }
            //       color: SystemInfo.networkType === "disconnected" ? root.theme.textMuted : root.theme.accentGreen
            //       font.pixelSize: 14
            //       font.family: "Hack Nerd Font"
            //     }
            //     Text {
            //       anchors.verticalCenter: parent.verticalCenter
            //       text: SystemInfo.networkInfo
            //       color: root.theme.textPrimary
            //       font.pixelSize: 11
            //       font.family: "Hack Nerd Font"
            //     }
            //   }
            // }
          }

          // System Tray
          Rectangle {
            implicitHeight: 24
            implicitWidth: trayIcons.implicitWidth + 4
            radius: 12
            color: root.theme.bgSurface

            RowLayout {
              id: trayIcons
              anchors.centerIn: parent
              spacing: 2

              Repeater {
                model: SystemTray.items
                MouseArea {
                  id: trayDelegate
                  required property SystemTrayItem modelData
                  Layout.preferredWidth: 24
                  Layout.preferredHeight: 24
                  acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                  onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                      modelData.activate()
                    } else if (mouse.button === Qt.RightButton) {
                      if (modelData.hasMenu) {
                        menuAnchor.open()
                      }
                    } else if (mouse.button === Qt.MiddleButton) {
                      modelData.secondaryActivate()
                    }
                  }

                  IconImage {
                    anchors.centerIn: parent
                    source: trayDelegate.modelData.icon
                    implicitSize: 16
                  }

                  QsMenuAnchor {
                    id: menuAnchor
                    menu: trayDelegate.modelData.menu
                    anchor.window: trayDelegate.QsWindow.window
                    anchor.adjustment: PopupAdjustment.Flip
                    anchor.onAnchoring: {
                      const window = trayDelegate.QsWindow.window;
                      const widgetRect = window.contentItem.mapFromItem(
                        trayDelegate, 0, trayDelegate.height,
                        trayDelegate.width, trayDelegate.height);
                      menuAnchor.anchor.rect = widgetRect;
                    }
                  }
                }
              }
            }
          }

          // Time
          Rectangle {
            height: 22
            width: timeDate.width + 16
            radius: 12
            color: root.theme.bgBase

            Row {
              id: timeDate
              anchors.centerIn: parent
              spacing: 8

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Time.dateString
                color: root.theme.textSecondary
                font.pixelSize: 12
                font.family: "Hack Nerd Font"
              }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Time.timeString
                color: root.theme.textPrimary
                font.pixelSize: 12
                font.family: "Hack Nerd Font"
              }
            }
          }
        }      }
    }
  }

  function toRoman(num) {
      const romanMap = [
          { value: 50, numeral: "L" },
          { value: 40, numeral: "XL" },
          { value: 10, numeral: "X" },
          { value: 9, numeral: "IX" },
          { value: 5, numeral: "V" },
          { value: 4, numeral: "IV" },
          { value: 1, numeral: "I" }
      ]
    let roman = ""; let number = num;
    for (let i = 0; i < romanMap.length; i++) {
      while (number >= romanMap[i].value) { roman += romanMap[i].numeral; number -= romanMap[i].value; }
    }
    return roman;
  }

  readonly property var phrases: [
      "It's not working, let me out!",
      "error: 1 dependencyyyy failed",
      "you know what? get out :!q",
      "you don't deserve that",
      "will you fix that?",
  ]
  function getRandomText() {
    return phrases[Math.floor(Math.random() * phrases.length)]
  }
}
