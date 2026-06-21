import QtQuick

QtObject {
  readonly property color bgBase: "#111111"
  readonly property color bgSurface: "#191919"
  readonly property color bgOverlay: "#88000000"
  readonly property color bgHover: "#151515"
  readonly property color bgSelected: "#323232"
  readonly property color bgBorder: "#1a1a1a"

  readonly property color textPrimary: "#eeeeee"
  readonly property color textSecondary: "#666666"
  readonly property color textMuted: "#303030"

  readonly property color accentPrimary: "#eeeeee"
  readonly property color accentCyan: "#e9f3f0"
  readonly property color accentGreen: "#e9f3ec"
  readonly property color accentOrange: "#f3eee9"
  readonly property color accentRed: "#da3333"

  readonly property color urgencyLow: textMuted
  readonly property color urgencyNormal: accentPrimary
  readonly property color urgencyCritical: accentRed
  readonly property color batteryGood: accentGreen
  readonly property color batteryWarning: accentOrange
  readonly property color batteryCritical: accentRed

  readonly property var themes: []
  readonly property int currentIndex: 0
  readonly property string currentName: "Dark"
  readonly property string currentFamily: "MonkeyType"
  readonly property int count: 0
  function setTheme(index) {}
}
