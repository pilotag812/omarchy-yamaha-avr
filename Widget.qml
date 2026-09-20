import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.bjarkimg.yamaha-avr"

  property bool popupOpen: false
  readonly property bool opened: popupOpen
  property bool online: false
  property bool sessionReady: false
  property bool muted: false
  property string statusText: "READY"
  property string processError: ""
  property string viewMode: "remote"
  property string activeName: deviceName
  property string activeHost: host
  property string power: ""
  property string inputSel: ""
  property string program: ""
  property string volumeLabel: ""
  property real volumeDb: -50.0
  property bool straightOn: false
  property bool sevenOn: false
  property var actionQueue: []
  property string bass: "+0.0"
  property int bassVal: 0
  property string treble: "+0.0"
  property int trebleVal: 0
  property bool adaptDrcOn: false
  property bool enhancerOn: false
  property bool cinema3dOn: false
  property bool serverAvailable: false
  property string serverPlayback: "Stop"
  property string serverRepeat: "Off"
  property string serverShuffle: "Off"
  property string serverArtist: ""
  property string serverAlbum: ""
  property string serverSong: ""
  property string serverMenuName: "Media Server"
  property int serverMenuLayer: 1
  property int serverCurrentLine: 0
  property int serverMaxLine: 0
  property var serverLines: []

  readonly property string deviceName: String(setting("deviceName", "Yamaha AVR"))
  readonly property string host: String(setting("host", ""))
  readonly property string remotePath: decodeURIComponent(
    String(Qt.resolvedUrl("yamaha-avr")).replace(/^file:\/\//, "")
  )
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.58)
  readonly property color accent: bar ? bar.urgent : Color.accent
  readonly property string fontFamily: bar ? bar.fontFamily : "JetBrainsMono Nerd Font"

  function close() {
    popupOpen = false
    viewMode = "remote"
    actionQueue = []
  }

  function applyStatus(message) {
    if (message.name) activeName = String(message.name)
    if (message.host) activeHost = String(message.host)
    power = String(message.power || power)
    muted = String(message.mute || "").toLowerCase() === "on"
    inputSel = String(message.input || inputSel)
    program = String(message.program || program)
    var pureActive = String(message.pureDirect || "").toLowerCase() === "on"
    straightOn = String(message.straight || "").toLowerCase() === "on" && !pureActive
    sevenOn = String(program).indexOf("7ch") >= 0 && !straightOn && !pureActive
    if (message.bass !== undefined && message.bass !== null && message.bass !== "") bass = String(message.bass)
    if (message.bassVal !== undefined && message.bassVal !== null && message.bassVal !== "") bassVal = Number(message.bassVal)
    if (message.treble !== undefined && message.treble !== null && message.treble !== "") treble = String(message.treble)
    if (message.trebleVal !== undefined && message.trebleVal !== null && message.trebleVal !== "") trebleVal = Number(message.trebleVal)
    adaptDrcOn = String(message.adaptiveDrc || "").toLowerCase() === "auto"
    enhancerOn = String(message.enhancer || "").toLowerCase() === "on"
    cinema3dOn = String(message.cinema3d || "").toLowerCase() === "auto" || String(message.cinema3d || "").toLowerCase() === "on"
    serverAvailable = Boolean(message.serverAvailable)
    serverPlayback = String(message.serverPlayback || serverPlayback)
    serverRepeat = String(message.serverRepeat || serverRepeat)
    serverShuffle = String(message.serverShuffle || serverShuffle)
    serverArtist = String(message.serverArtist || "")
    serverAlbum = String(message.serverAlbum || "")
    serverSong = String(message.serverSong || "")
    serverMenuName = String(message.serverMenuName || serverMenuName)
    serverMenuLayer = Number(message.serverMenuLayer || 1)
    serverCurrentLine = Number(message.serverCurrentLine || 0)
    serverMaxLine = Number(message.serverMaxLine || 0)
    serverLines = message.serverLines || []
    if (message.volumeDb !== undefined && message.volumeDb !== null && message.volumeDb !== "") {
      volumeDb = Number(message.volumeDb)
      volumeLabel = Number(message.volumeDb).toFixed(1) + " dB"
    } else if (message.volume !== undefined && message.volume !== null && message.volume !== "" && message.volume !== "--") {
      volumeDb = Number(message.volume)
      volumeLabel = String(message.volume) + " dB"
    }
    online = String(message.power || "").toLowerCase() === "on" || Boolean(message.connected)
    if (String(message.status) === "standby" || String(message.power || "").toLowerCase() === "standby") {
      online = false
      statusText = "STANDBY"
    } else if (String(message.status) === "awake" || String(message.power || "").toLowerCase() === "on") {
      online = true
      statusText = muted ? "MUTED" : (inputSel || "ON")
    } else if (online) {
      statusText = muted ? "MUTED" : (inputSel || "ON")
    } else {
      statusText = "OFFLINE"
    }
  }

  function sendAction(action) {
    if (!action) return
    if (sessionProcess.running && sessionReady) {
      statusText = String(action).toUpperCase().replace(/-/g, " ")
      sessionProcess.write(action + "\n")
      return
    }
    if (actionQueue.length < 32) actionQueue = actionQueue.concat([action])
  }

  function sendRequest(request) {
    if (!sessionProcess.running) return false
    sessionProcess.write(JSON.stringify(request) + "\n")
    return true
  }

  function flushQueuedActions() {
    if (!sessionProcess.running || !sessionReady || actionQueue.length === 0) return
    var pending = actionQueue
    actionQueue = []
    for (var i = 0; i < pending.length; i++) sessionProcess.write(pending[i] + "\n")
  }

  function setHost() {
    var value = String(hostInput.text || "").trim()
    if (!value) {
      processError = "Enter the receiver IP"
      return
    }
    processError = ""
    statusText = "CONNECTING"
    sendRequest({ "op": "set-host", "host": value, "name": String(nameInput.text || "").trim() })
  }

  function handleSessionLine(line) {
    var message
    try { message = JSON.parse(String(line || "")) } catch (error) { return }

    if (message.event === "ready" || message.event === "switched") {
      sessionReady = true
      processError = ""
      applyStatus(message)
      flushQueuedActions()
      if (message.event === "switched") viewMode = "remote"
      return
    }
    if (message.event === "error") {
      online = Boolean(message.connected)
      processError = String(message.message || "")
      if (!online) {
        statusText = "OFFLINE"
      }
      return
    }
    if (message.event !== "result") return
    processError = ""
    applyStatus(message)
  }

  function handleTextKey(text) {
    var key = String(text || "").toLowerCase()
    if (viewMode === "devices" || viewMode === "audio" || viewMode === "server") {
      if (key === "b" || key === "q") { viewMode = "remote"; return }
      if (viewMode === "audio") {
        if (key === "d") sendAction("adaptive-drc-toggle")
        else if (key === "h") sendAction("enhancer-toggle")
        else if (key === "c") sendAction("cinema3d-toggle")
        return
      }
      if (viewMode === "server") {
        if (key === "p") sendAction(serverPlayback.toLowerCase() === "play" ? "server-stop" : "server-play")
        else if (key === "x") sendAction("server-stop")
        else if (key === "n") sendAction("server-next")
        else if (key === "v") sendAction("server-previous")
        else if (key === "w") sendAction("server-up")
        else if (key === "s") sendAction("server-down")
        else if (key === "e") sendAction("server-select")
        else if (key === "h") sendAction("server-back")
        else if (key === "g") sendAction("server-home")
        else if (key === "r") sendAction("server-refresh")
        return
      }
      return
    }
    if (key === "p") sendAction("power")
    else if (key === "o") sendAction("power-on")
    else if (key === "x" || key === "f") sendAction("power-off")
    else if (key === "m") sendAction("mute")
    else if (key === "+" || key === "=") sendAction("volume-up")
    else if (key === "-" || key === "_") sendAction("volume-down")
    else if (key === "1") sendAction("input-av1")
    else if (key === "6") sendAction("input-av6")
    else if (key === "e") { viewMode = "server"; sendAction("input-server") }
    else if (key === "s") sendAction("straight")
    else if (key === "7") sendAction("program-7ch")
    else if (key === "a") viewMode = "audio"
    else if (key === "d") {
      hostInput.text = root.activeHost
      nameInput.text = root.activeName
      viewMode = "devices"
    }
    else if (key === "q") close()
  }

  onPopupOpenChanged: {
    if (!popupOpen) return
    sendAction("status")
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property int restartAttempts: 0
  readonly property int maxRestartAttempts: 5

  function manualReconnect() {
    restartAttempts = 0
    root.processError = ""
    sessionProcess.running = false
    sessionProcess.running = true
  }

  Process {
    id: sessionProcess
    command: [root.remotePath, "--host", root.host, "--name", root.deviceName, "session"]
    environment: ({
      "PATH": "/usr/bin:/bin",
      "HOME": Quickshell.env("HOME") || "",
      "XDG_STATE_HOME": Quickshell.env("XDG_STATE_HOME") || "",
      "LC_ALL": "C.UTF-8"
    })
    stdinEnabled: true
    running: true
    stdout: SplitParser {
      onRead: function(line) {
        if (line && line.length <= 65536) {
          root.restartAttempts = 0
          root.handleSessionLine(line)
        }
      }
    }
    stderr: SplitParser {
      onRead: function(line) {
        if (line) root.processError = String(line).slice(0, 512).trim()
      }
    }
    onExited: function() {
      root.sessionReady = false
      root.online = false
      root.statusText = "OFFLINE"
      if (root.restartAttempts < root.maxRestartAttempts) {
        root.restartAttempts++
        var delay = Math.min(10000, 1000 * Math.pow(2, root.restartAttempts - 1))
        sessionRestart.interval = delay
        sessionRestart.restart()
      } else {
        root.processError = "Backend stopped after multiple failures. Open settings to reconnect."
      }
    }
  }

  Timer {
    id: sessionRestart
    interval: 1500
    repeat: false
    onTriggered: { if (!sessionProcess.running) sessionProcess.running = true }
  }

  component RemoteKey: Button {
    property string action: ""
    property string targetView: ""
    property bool on: false
    property real keyWidth: 92
    property real keyHeight: 38
    width: keyWidth
    height: keyHeight
    selected: on
    foreground: root.foreground
    accent: root.accent
    fontFamily: root.fontFamily
    fontSize: Style.font.bodySmall
    iconSize: Style.font.iconLarge
    bordered: true
    onClicked: {
      root.sendAction(action)
      if (targetView) root.viewMode = targetView
    }
  }

  component ToneRow: Row {
    id: toneRow
    property string title: ""
    property string displayValue: "+0.0 dB"
    property string actionDown: ""
    property string actionUp: ""
    property string setOp: ""
    property string tooltipInfo: ""
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.space(6)

    Item {
      width: 70
      height: 34

      Text {
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        text: toneRow.title
        textFormat: Text.PlainText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
      }

      MouseArea {
        id: titleHover
        anchors.fill: parent
        hoverEnabled: true
      }

      PanelToolTip {
        visible: titleHover.containsMouse && toneRow.tooltipInfo !== ""
        text: toneRow.tooltipInfo
        panelForeground: root.foreground
        fontFamily: root.fontFamily
      }
    }

    Button {
      width: 42
      height: 34
      text: "−"
      tooltipText: "Decrease " + toneRow.title
      foreground: root.foreground
      accent: root.accent
      fontFamily: root.fontFamily
      fontSize: Style.font.bodySmall
      bordered: true
      onClicked: root.sendAction(toneRow.actionDown)
    }

    Text {
      width: 65
      height: 34
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      text: toneRow.displayValue
      textFormat: Text.PlainText
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }

    Button {
      width: 42
      height: 34
      text: "+"
      tooltipText: "Increase " + toneRow.title
      foreground: root.foreground
      accent: root.accent
      fontFamily: root.fontFamily
      fontSize: Style.font.bodySmall
      bordered: true
      onClicked: root.sendAction(toneRow.actionUp)
    }

    Button {
      width: 42
      height: 34
      text: "0"
      tooltipText: "Reset " + toneRow.title + " to 0.0 dB"
      foreground: root.dim
      accent: root.accent
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      bordered: true
      onClicked: root.sendRequest({ "op": toneRow.setOp, "value": 0 })
    }
  }

  Item {
    id: button
    anchors.fill: parent
    implicitWidth: Style.bar.statusSlot
    implicitHeight: Style.bar.sizeHorizontal

    Text {
      anchors.centerIn: parent
      text: "AV"
      textFormat: Text.PlainText
      color: root.online ? root.foreground : root.dim
      font.family: "sans-serif"
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      cursorShape: Qt.PointingHandCursor
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
          root.sendAction("power")
        } else {
          root.popupOpen = !root.popupOpen
        }
      }
      onEntered: if (root.bar) root.bar.showTooltip(root, root.activeName + " · " + (root.online ? "ON" : "STANDBY"))
      onExited: if (root.bar) root.bar.hideTooltip(root)
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.popupOpen
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(332))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: hostInput.activeFocus || nameInput.activeFocus
      onCloseRequested: {
        if (root.viewMode === "remote") root.close()
        else root.viewMode = "remote"
      }
      onTextKey: function(text) { root.handleTextKey(text) }

      Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(10)

        Item {
          width: parent.width
          height: Math.max(titleCol.implicitHeight, statusLabel.implicitHeight)
          Column {
            id: titleCol
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(1)
            Text {
              text: root.activeName.toUpperCase()
              textFormat: Text.PlainText
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.subtitle
              font.bold: true
            }
            Text {
              text: root.viewMode === "remote" ? "YAMAHA AVR"
                : (root.viewMode === "audio" ? "AUDIO CONTROLS"
                : (root.viewMode === "server" ? "MEDIA SERVER" : "RECEIVER HOST"))
              textFormat: Text.PlainText
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
          Text {
            id: statusLabel
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: (root.online ? "● " : "○ ") + root.statusText
            textFormat: Text.PlainText
            color: root.online ? root.foreground : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }

        PanelSeparator { width: parent.width; foreground: root.foreground }

        Column {
          visible: root.viewMode === "remote"
          width: parent.width
          spacing: Style.space(10)

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: (root.muted ? "MUTE  ·  " : "") + (root.volumeLabel || "—")
              + (root.inputSel ? "  ·  " + root.inputSel : "")
              + (root.program ? "  ·  " + root.program : "")
            textFormat: Text.PlainText
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.Wrap
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(7)
            RemoteKey { action: "straight"; text: "STRT"; tooltipText: "Straight: Decodes audio without DSP processing"; on: root.straightOn; keyWidth: 92 }
            RemoteKey { action: "program-7ch"; text: "7CH"; tooltipText: "7ch Stereo: All-channel stereo for wide sound"; on: root.sevenOn; keyWidth: 92 }
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(7)
            RemoteKey { action: "power-on"; iconText: "󰐥"; text: "ON"; tooltipText: "Power on the receiver"; on: root.online; keyWidth: 92 }
            RemoteKey { action: "power-off"; iconText: "󰤄"; text: "OFF"; tooltipText: "Set receiver to standby"; on: !root.online; keyWidth: 92 }
            RemoteKey { action: "mute"; iconText: root.muted ? "󰝟" : "󰕾"; text: "MUTE"; tooltipText: "Toggle mute"; on: root.muted; keyWidth: 92 }
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(7)
            RemoteKey { action: "volume-down"; iconText: "󰕿"; text: "VOL−"; tooltipText: "Volume down 0.5 dB"; keyWidth: 142 }
            RemoteKey { action: "volume-up"; iconText: "󰖀"; text: "VOL+"; tooltipText: "Volume up 0.5 dB"; keyWidth: 142 }
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(7)
            RemoteKey {
              action: "vol-60"
              keyWidth: 67
              keyHeight: 32
              fontSize: Style.font.caption
              text: "-60 dB"
              tooltipText: "Preset -60.0 dB (Night / Minimum)"
              on: Math.abs(root.volumeDb - (-60.0)) <= 0.5
            }
            RemoteKey {
              action: "vol-50"
              keyWidth: 67
              keyHeight: 32
              fontSize: Style.font.caption
              text: "-50 dB"
              tooltipText: "Preset -50.0 dB (Quiet listening)"
              on: Math.abs(root.volumeDb - (-50.0)) <= 0.5
            }
            RemoteKey {
              action: "vol-45"
              keyWidth: 67
              keyHeight: 32
              fontSize: Style.font.caption
              text: "-45 dB"
              tooltipText: "Preset -45.0 dB (Low / Daytime TV)"
              on: Math.abs(root.volumeDb - (-45.0)) <= 0.5
            }
            RemoteKey {
              action: "vol-40"
              keyWidth: 67
              keyHeight: 32
              fontSize: Style.font.caption
              text: "-40 dB"
              tooltipText: "Preset -40.0 dB (Normal / Movies)"
              on: Math.abs(root.volumeDb - (-40.0)) <= 0.5
            }
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(7)
            RemoteKey { action: "input-av1"; text: "AV1"; on: root.inputSel.toUpperCase() === "AV1"; keyWidth: 92 }
            RemoteKey { action: "input-av6"; text: "AV6"; on: root.inputSel.toUpperCase() === "AV6"; keyWidth: 92 }
            RemoteKey { action: "input-server"; targetView: "server"; text: "SERVER"; on: root.inputSel.toUpperCase() === "SERVER"; keyWidth: 92 }
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(7)

            Button {
              width: 142
              height: 38
              text: "AUDIO"
              iconText: "󰓃"
              tooltipText: "Tone and DSP audio settings"
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              bordered: true
              onClicked: root.viewMode = "audio"
            }

            Button {
              width: 142
              height: 38
              text: "HOST"
              iconText: "󰒋"
              tooltipText: "Configure receiver IP address and name"
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              bordered: true
              onClicked: {
                hostInput.text = root.activeHost
                nameInput.text = root.activeName
                root.viewMode = "devices"
              }
            }
          }

          Text {
            visible: root.processError !== ""
            width: parent.width
            text: root.processError
            textFormat: Text.PlainText
            color: root.accent
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            text: "[1] AV1  [6] AV6  [E] SERVER  [A] AUDIO  [D] HOST"
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        Column {
          visible: root.viewMode === "server"
          width: parent.width
          spacing: Style.space(8)

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.serverSong || (root.serverAvailable ? "Nothing playing" : "Media server unavailable")
            textFormat: Text.PlainText
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            wrapMode: Text.Wrap
          }

          Text {
            visible: root.serverArtist !== "" || root.serverAlbum !== ""
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: [root.serverArtist, root.serverAlbum].filter(function(value) { return value !== "" }).join("  ·  ")
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.Wrap
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.serverPlayback.toUpperCase() + "  ·  REPEAT " + root.serverRepeat.toUpperCase()
              + "  ·  SHUFFLE " + root.serverShuffle.toUpperCase()
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.Wrap
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(7)
            RemoteKey { action: "server-previous"; text: "PREV"; tooltipText: "Previous track"; keyWidth: 92 }
            RemoteKey {
              action: root.serverPlayback.toLowerCase() === "play" ? "server-stop" : "server-play"
              text: root.serverPlayback.toLowerCase() === "play" ? "STOP" : "PLAY"
              on: root.serverPlayback.toLowerCase() === "play"
              keyWidth: 92
            }
            RemoteKey { action: "server-next"; text: "NEXT"; tooltipText: "Next track"; keyWidth: 92 }
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(7)
            RemoteKey { action: "server-repeat"; text: "RPT " + root.serverRepeat.toUpperCase(); on: root.serverRepeat !== "Off"; keyWidth: 142 }
            RemoteKey { action: "server-shuffle"; text: "SHUF"; on: root.serverShuffle === "On"; keyWidth: 142 }
          }

          PanelSeparator { width: parent.width; foreground: root.foreground }

          Text {
            width: parent.width
            text: root.serverMenuName + "  ·  "
              + (serverSeek.dragging ? Math.round(serverSeek.liveValue) : root.serverCurrentLine)
              + "/" + root.serverMaxLine
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            elide: Text.ElideRight
          }

          Row {
            width: parent.width
            spacing: serverSeekRail.visible ? Style.space(6) : 0

            Column {
              id: serverList
              width: parent.width - serverSeekRail.width - parent.spacing
              spacing: Style.space(8)

              Repeater {
                model: root.serverLines
                Button {
                  required property var modelData
                  readonly property bool currentTrack: modelData.attribute === "Item"
                    && modelData.text === root.serverSong
                  width: serverList.width
                  height: 32
                  text: (modelData.attribute === "Container" ? "▸ "
                    : (currentTrack ? (root.serverPlayback.toLowerCase() === "play" ? "▶ " : "Ⅱ ") : "♪ "))
                    + modelData.text
                  tooltipText: modelData.text
                  selected: currentTrack
                  foreground: root.foreground
                  accent: root.accent
                  fontFamily: root.fontFamily
                  fontSize: Style.font.caption
                  bordered: true
                  onClicked: root.sendAction("server-line-" + modelData.index)
                }
              }
            }

            Item {
              id: serverSeekRail
              visible: root.serverMaxLine > 1
              width: visible ? Style.space(24) : 0
              height: Math.max(32, serverList.implicitHeight)

              PanelSlider {
                id: serverSeek
                anchors.centerIn: parent
                width: serverSeekRail.height
                height: serverSeekRail.width
                rotation: 90
                bar: root.bar
                minimum: 1
                maximum: Math.max(1, root.serverMaxLine)
                step: 8
                integer: true
                value: Math.max(1, root.serverCurrentLine)
                onReleased: function(value) {
                  root.sendAction("server-jump-" + Math.round(value))
                }
              }
            }
          }

          Text {
            visible: root.serverLines.length === 0
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "No items in this folder"
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(5)
            RemoteKey { action: "server-home"; text: "HOME"; keyWidth: 54; keyHeight: 32; fontSize: Style.font.caption }
            RemoteKey { action: "server-back"; text: "BACK"; keyWidth: 54; keyHeight: 32; fontSize: Style.font.caption }
            RemoteKey { action: "server-page-up"; text: "PG↑"; keyWidth: 54; keyHeight: 32; fontSize: Style.font.caption }
            RemoteKey { action: "server-page-down"; text: "PG↓"; keyWidth: 54; keyHeight: 32; fontSize: Style.font.caption }
            RemoteKey { action: "server-refresh"; text: "REF"; keyWidth: 54; keyHeight: 32; fontSize: Style.font.caption }
          }

          Button {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 291
            height: 38
            text: "BACK TO REMOTE"
            iconText: "󰁍"
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            bordered: true
            onClicked: root.viewMode = "remote"
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "[P] PLAY/STOP  [V/N] PREV/NEXT  [B] REMOTE"
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.Wrap
          }
        }

        Column {
          visible: root.viewMode === "audio"
          width: parent.width
          spacing: Style.space(8)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "TONE"
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          ToneRow {
            title: "BASS"
            tooltipInfo: "Bass: 350 Hz shelving EQ (-6.0 dB to +6.0 dB)"
            displayValue: (root.bass || "+0.0") + " dB"
            actionDown: "bass-down"
            actionUp: "bass-up"
            setOp: "set-bass"
          }

          ToneRow {
            title: "TREBLE"
            tooltipInfo: "Treble: 3.5 kHz shelving EQ (-6.0 dB to +6.0 dB)"
            displayValue: (root.treble || "+0.0") + " dB"
            actionDown: "treble-down"
            actionUp: "treble-up"
            setOp: "set-treble"
          }

          PanelSeparator { width: parent.width; foreground: root.foreground }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "DSP & ENHANCEMENT"
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(7)
            RemoteKey { action: "adaptive-drc-toggle"; text: "A-DRC"; tooltipText: "Adaptive DRC: Compresses dynamic range for night listening"; on: root.adaptDrcOn; keyWidth: 92 }
            RemoteKey { action: "enhancer-toggle"; text: "ENHANCER"; tooltipText: "Music Enhancer: Regenerates lost harmonics in compressed audio"; on: root.enhancerOn; keyWidth: 92 }
            RemoteKey { action: "cinema3d-toggle"; text: "CINEMA 3D"; tooltipText: "Cinema DSP 3D: Generates 3D height soundfield"; on: root.cinema3dOn; keyWidth: 92 }
          }

          Button {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 291
            height: 38
            text: "BACK"
            iconText: "󰁍"
            tooltipText: "Return to remote control"
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            bordered: true
            onClicked: root.viewMode = "remote"
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            text: "[B] BACK  [D] DRC  [H] ENH  [C] 3D"
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        Column {
          visible: root.viewMode === "devices"
          width: parent.width
          spacing: Style.space(8)

          TextField {
            id: hostInput
            width: parent.width
            placeholderText: "192.168.1.2"
            foreground: root.foreground
            accent: root.accent
            onAccepted: root.setHost()
            Keys.onEscapePressed: function(event) {
              root.viewMode = "remote"
              keyCatcher.forceActiveFocus()
              event.accepted = true
            }
          }
          TextField {
            id: nameInput
            width: parent.width
            placeholderText: "Optional name"
            foreground: root.foreground
            accent: root.accent
            onAccepted: root.setHost()
            Keys.onEscapePressed: function(event) {
              root.viewMode = "remote"
              keyCatcher.forceActiveFocus()
              event.accepted = true
            }
          }
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(7)

            Button {
              width: 142
              height: 38
              text: "CANCEL"
              iconText: "󰁍"
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              bordered: true
              onClicked: root.viewMode = "remote"
            }

            Button {
              width: 142
              height: 38
              text: "CONNECT"
              iconText: "󰒋"
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              bordered: true
              onClicked: root.setHost()
            }
          }
        }
      }
    }
  }
}
