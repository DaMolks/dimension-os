{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.sddm;
  themeName = "dimension";
  sddmUnwrapped = pkgs.kdePackages.sddm-unwrapped;
  themeConf = pkgs.writeText "dimension-sddm-theme.conf" ''
    [General]
    name=Dimension
    font=Inter
    background=background.png
    backgroundColor=#000F1F
    accentColor=#0078D7
    textColor=#E8F0F8
    mutedTextColor=#93A4B7
    cardColor=#A6000F1F
    cardOverlayColor=#C4071523
    borderColor=#660078D7
  '';
  metadataDesktop = pkgs.writeText "dimension-sddm-metadata.desktop" ''
    [SddmGreeterTheme]
    Name=Dimension
    Description=Dimension OS SDDM theme
    Author=Dimension OS
    Copyright=(c) Dimension OS
    License=MIT
    Type=sddm-theme
    Version=2.0
    MainScript=Main.qml
    ConfigFile=theme.conf
    Theme-Id=${themeName}
    Theme-API=2.0
  '';
  userIcon = pkgs.writeText "dimension-sddm-user.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#E8F0F8" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
      <path d="M20 21a8 8 0 0 0-16 0"/>
      <circle cx="12" cy="8" r="4"/>
    </svg>
  '';
  passwordIcon = pkgs.writeText "dimension-sddm-password.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#E8F0F8" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
      <rect x="4" y="10" width="16" height="10" rx="2"/>
      <path d="M8 10V7a4 4 0 0 1 8 0v3"/>
      <path d="M12 14v2"/>
    </svg>
  '';
  mainQml = pkgs.writeText "dimension-sddm-Main.qml" ''
    import QtQuick 2.15
    import QtQuick.Controls 2.15 as Controls
    import QtQuick.Layouts 1.15
    import QtQuick.Window 2.15
    import Qt5Compat.GraphicalEffects

    Rectangle {
        id: root
        width: 1920
        height: 1080
        color: config.backgroundColor || "#000F1F"

        property string accentColor: config.accentColor || "#0078D7"
        property string textColor: config.textColor || "#E8F0F8"
        property string mutedTextColor: config.mutedTextColor || "#93A4B7"
        property string cardColor: config.cardColor || "#A6000F1F"
        property string cardOverlayColor: config.cardOverlayColor || "#C4071523"
        property string borderColor: config.borderColor || "#660078D7"
        property string uiFont: config.font || "Inter"
        property int activeSessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
        property date currentDateTime: new Date()

        function submitLogin() {
            var user = usernameField.text.trim()
            if (user.length === 0) {
                statusText.text = "Enter a username to continue"
                usernameField.forceActiveFocus()
                return
            }

            statusText.text = ""
            loginCardHost.state = "connecting"
            sddm.login(user, passwordField.text, activeSessionIndex)
        }

        Timer {
            interval: 1000
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: root.currentDateTime = new Date()
        }

        Connections {
            target: sddm

            function onLoginFailed() {
                loginCardHost.state = ""
                statusText.text = "Authentication failed"
                passwordField.text = ""
                passwordField.forceActiveFocus()
            }
        }

        Image {
            id: backgroundImage
            anchors.fill: parent
            source: Qt.resolvedUrl(config.background || "background.png")
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }

        ShaderEffectSource {
            id: fullBackgroundSource
            anchors.fill: parent
            sourceItem: backgroundImage
            live: false
            hideSource: false
            visible: false
        }

        GaussianBlur {
            anchors.fill: parent
            source: fullBackgroundSource
            radius: 10
            samples: 24
            opacity: 0.18
            transparentBorder: false
        }

        Rectangle {
            anchors.fill: parent
            color: "#33000F1F"
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 0.72; color: "#12000000" }
                GradientStop { position: 1.0; color: "#8C00070F" }
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 54
            spacing: 6
            opacity: 0.92

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.textColor
                font.family: root.uiFont
                font.pixelSize: 42
                font.weight: Font.Medium
                text: Qt.formatTime(root.currentDateTime, "HH:mm")
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.mutedTextColor
                font.family: root.uiFont
                font.pixelSize: 18
                text: Qt.formatDate(root.currentDateTime, "dddd d MMMM")
            }
        }

        Item {
            id: loginCardHost
            anchors.centerIn: parent
            width: 424
            height: 388
            opacity: 0
            scale: 0.96
            state: ""
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 18
                radius: 30
                samples: 48
                color: "#99000000"
                transparentBorder: true
            }

            states: [
                State {
                    name: "connecting"
                    PropertyChanges { target: loginCardHost; scale: 0.985; opacity: 0.86 }
                }
            ]

            transitions: Transition {
                NumberAnimation {
                    properties: "scale,opacity"
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                id: loginCard
                anchors.fill: parent
                radius: 28
                color: root.cardColor
                border.width: 0
                clip: true

                ShaderEffectSource {
                    id: cardBackgroundSource
                    anchors.fill: parent
                    sourceItem: backgroundImage
                    sourceRect: Qt.rect(loginCard.mapToItem(root, 0, 0).x, loginCard.mapToItem(root, 0, 0).y, loginCard.width, loginCard.height)
                    live: true
                    hideSource: false
                    visible: false
                }

                GaussianBlur {
                    anchors.fill: parent
                    source: cardBackgroundSource
                    radius: 38
                    samples: 32
                    transparentBorder: true
                }

                Rectangle {
                    anchors.fill: parent
                    color: root.cardOverlayColor
                }

                Rectangle {
                    anchors.fill: parent
                    radius: loginCard.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#2E54B8FF" }
                        GradientStop { position: 0.36; color: "#120078D7" }
                        GradientStop { position: 1.0; color: "#08E8F0F8" }
                    }
                    opacity: 0.46
                }

                Canvas {
                    id: cardBorder
                    anchors.fill: parent
                    opacity: 0.96

                    function roundedPath(ctx, x, y, w, h, r) {
                        ctx.beginPath()
                        ctx.moveTo(x + r, y)
                        ctx.lineTo(x + w - r, y)
                        ctx.quadraticCurveTo(x + w, y, x + w, y + r)
                        ctx.lineTo(x + w, y + h - r)
                        ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
                        ctx.lineTo(x + r, y + h)
                        ctx.quadraticCurveTo(x, y + h, x, y + h - r)
                        ctx.lineTo(x, y + r)
                        ctx.quadraticCurveTo(x, y, x + r, y)
                    }

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var g = ctx.createLinearGradient(0, 0, width, height)
                        g.addColorStop(0, root.accentColor)
                        g.addColorStop(0.48, "rgba(0,120,215,0.22)")
                        g.addColorStop(1, "rgba(232,240,248,0.10)")
                        roundedPath(ctx, 1.0, 1.0, width - 2.0, height - 2.0, 28)
                        ctx.lineWidth = 1.4
                        ctx.strokeStyle = g
                        ctx.stroke()
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 32
                    spacing: 16

                    Text {
                        Layout.fillWidth: true
                        color: root.textColor
                        font.family: root.uiFont
                        font.pixelSize: 27
                        font.weight: Font.Medium
                        text: "Welcome"
                    }

                    Text {
                        Layout.fillWidth: true
                        color: root.mutedTextColor
                        font.family: root.uiFont
                        font.pixelSize: 14
                        text: sddm.hostname
                        elide: Text.ElideRight
                    }

                    Item { Layout.fillHeight: true; height: 4 }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        radius: 15
                        scale: usernameField.activeFocus ? 1.02 : 1.0
                        color: usernameField.activeFocus ? "#7A071D32" : "#5E071523"
                        border.width: 1
                        border.color: usernameField.activeFocus ? root.accentColor : "#3D1D3550"

                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 140 } }

                        Image {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20
                            source: Qt.resolvedUrl("user.svg")
                            opacity: usernameField.activeFocus ? 0.96 : 0.62
                        }

                        TextInput {
                            id: usernameField
                            anchors.fill: parent
                            anchors.leftMargin: 50
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.textColor
                            selectionColor: root.accentColor
                            selectedTextColor: "#FFFFFF"
                            font.family: root.uiFont
                            font.pixelSize: 17
                            clip: true
                            text: userModel.lastUser || ""

                            Keys.onReturnPressed: root.submitLogin()
                            Keys.onEnterPressed: root.submitLogin()
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 50
                            anchors.verticalCenter: parent.verticalCenter
                            visible: usernameField.text.length === 0
                            color: root.mutedTextColor
                            font.family: root.uiFont
                            font.pixelSize: 15
                            text: "Username"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        radius: 15
                        scale: passwordField.activeFocus ? 1.02 : 1.0
                        color: passwordField.activeFocus ? "#7A071D32" : "#5E071523"
                        border.width: 1
                        border.color: passwordField.activeFocus ? root.accentColor : "#3D1D3550"

                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 140 } }

                        Image {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20
                            source: Qt.resolvedUrl("password.svg")
                            opacity: passwordField.activeFocus ? 0.96 : 0.62
                        }

                        TextInput {
                            id: passwordField
                            anchors.fill: parent
                            anchors.leftMargin: 50
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.textColor
                            selectionColor: root.accentColor
                            selectedTextColor: "#FFFFFF"
                            font.family: root.uiFont
                            font.pixelSize: 17
                            clip: true
                            echoMode: TextInput.Password
                            inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText

                            Keys.onReturnPressed: root.submitLogin()
                            Keys.onEnterPressed: root.submitLogin()
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 50
                            anchors.verticalCenter: parent.verticalCenter
                            visible: passwordField.text.length === 0
                            color: root.mutedTextColor
                            font.family: root.uiFont
                            font.pixelSize: 15
                            text: "Password"
                        }
                    }

                    Text {
                        id: statusText
                        Layout.fillWidth: true
                        minimumPixelSize: 13
                        color: "#F0B4C6"
                        font.family: root.uiFont
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        visible: text.length > 0
                        text: ""
                    }

                    Rectangle {
                        id: loginButton
                        Layout.fillWidth: true
                        height: 54
                        radius: 15
                        scale: loginButtonArea.containsMouse ? 1.018 : 1.0
                        color: loginButtonArea.pressed ? "#005EA8" : root.accentColor
                        clip: true

                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 130 } }

                        Rectangle {
                            id: pulseOverlay
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                            radius: parent.radius
                            color: "#FFFFFF"
                            opacity: 0
                        }

                        SequentialAnimation {
                            running: loginButtonArea.containsMouse
                            loops: Animation.Infinite
                            NumberAnimation { target: pulseOverlay; property: "opacity"; from: 0.03; to: 0.16; duration: 620; easing.type: Easing.InOutSine }
                            NumberAnimation { target: pulseOverlay; property: "opacity"; from: 0.16; to: 0.03; duration: 620; easing.type: Easing.InOutSine }
                        }

                        Text {
                            anchors.centerIn: parent
                            color: "#FFFFFF"
                            font.family: root.uiFont
                            font.pixelSize: 17
                            font.weight: Font.Medium
                            text: loginCardHost.state === "connecting" ? "Signing in..." : "Log In"
                        }

                        MouseArea {
                            id: loginButtonArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.submitLogin()
                        }
                    }
                }
            }

            Component.onCompleted: {
                fadeIn.start()
            }

            SequentialAnimation {
                id: fadeIn
                PauseAnimation { duration: 60 }
                ParallelAnimation {
                    NumberAnimation { target: loginCardHost; property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }
                    NumberAnimation { target: loginCardHost; property: "scale"; from: 0.96; to: 1; duration: 400; easing.type: Easing.OutCubic }
                }
            }
        }

        Controls.ComboBox {
            id: sessionSelector
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 26
            anchors.bottomMargin: 22
            width: 220
            height: 42
            model: sessionModel
            textRole: "name"
            currentIndex: root.activeSessionIndex
            onActivated: root.activeSessionIndex = index
            font.family: root.uiFont
            font.pixelSize: 13

            background: Rectangle {
                radius: 13
                color: "#78071523"
                border.width: 1
                border.color: sessionSelector.hovered ? root.accentColor : "#331D3550"
            }

            contentItem: Text {
                leftPadding: 14
                rightPadding: 34
                verticalAlignment: Text.AlignVCenter
                color: root.textColor
                font: sessionSelector.font
                text: sessionSelector.displayText
                elide: Text.ElideRight
            }

            indicator: Text {
                anchors.right: parent.right
                anchors.rightMargin: 13
                anchors.verticalCenter: parent.verticalCenter
                color: root.mutedTextColor
                font.family: root.uiFont
                font.pixelSize: 13
                text: "v"
            }

            popup: Controls.Popup {
                y: -implicitHeight - 8
                width: sessionSelector.width
                implicitHeight: Math.min(contentItem.implicitHeight, 220)
                padding: 6
                background: Rectangle {
                    radius: 14
                    color: "#E6071523"
                    border.width: 1
                    border.color: root.borderColor
                }
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: sessionSelector.popup.visible ? sessionSelector.delegateModel : null
                    currentIndex: sessionSelector.highlightedIndex
                }
            }

            delegate: Controls.ItemDelegate {
                width: sessionSelector.width - 12
                height: 36
                highlighted: sessionSelector.highlightedIndex === index
                contentItem: Text {
                    text: model.name
                    color: highlighted ? "#FFFFFF" : root.textColor
                    font.family: root.uiFont
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 10
                    color: highlighted ? root.accentColor : "transparent"
                    opacity: highlighted ? 0.86 : 1
                }
            }
        }

        Component.onCompleted: {
            if (usernameField.text.length > 0) {
                passwordField.forceActiveFocus()
            } else {
                usernameField.forceActiveFocus()
            }
        }
    }
  '';
  themePackage = pkgs.stdenvNoCC.mkDerivation {
    pname = "dimension-sddm-theme";
    version = "2.0.0";
    dontUnpack = true;

    installPhase = ''
      theme_dir="$out/share/sddm/themes/${themeName}"

      mkdir -p "$theme_dir"
      cp ${themeConf} "$theme_dir/theme.conf"
      cp ${metadataDesktop} "$theme_dir/metadata.desktop"
      cp ${mainQml} "$theme_dir/Main.qml"
      cp ${userIcon} "$theme_dir/user.svg"
      cp ${passwordIcon} "$theme_dir/password.svg"
      cp ${../../assets/wallpapers/dimension-sddm-glass.png} "$theme_dir/background.png"
    '';
  };
  sddmPackage = pkgs.kdePackages.sddm.overrideAttrs (old: {
    buildCommand =
      builtins.replaceStrings
        [ ''if [ "$i" == "bin" ]; then'' ]
        [ ''if [ "$i" == "bin" ] || [ "$i" == "share" ]; then'' ]
        old.buildCommand
      + ''
      mkdir -p "$out/share"
      for item in ${sddmUnwrapped}/share/*; do
        name="$(basename "$item")"
        if [ "$name" = "sddm" ]; then
          continue
        fi
        ln -s "$item" "$out/share/$name"
      done

      mkdir -p "$out/share/sddm"
      for item in ${sddmUnwrapped}/share/sddm/*; do
        name="$(basename "$item")"
        if [ "$name" = "themes" ]; then
          continue
        fi
        ln -s "$item" "$out/share/sddm/$name"
      done

      mkdir -p "$out/share/sddm/themes"
      for item in ${sddmUnwrapped}/share/sddm/themes/*; do
        name="$(basename "$item")"
        if [ "$name" = "${themeName}" ]; then
          continue
        fi
        ln -s "$item" "$out/share/sddm/themes/$name"
      done

      ln -sfn ${themePackage}/share/sddm/themes/${themeName} \
        "$out/share/sddm/themes/${themeName}"
    '';
  });
in
{
  options.dimension.sddm.enable =
    lib.mkEnableOption "Dimension custom SDDM greeter theme";

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm = {
      package = lib.mkForce sddmPackage;
      theme = lib.mkForce themeName;
      extraPackages = [
        pkgs.kdePackages.qt5compat.out
        pkgs.kdePackages.qtsvg
      ];
    };
  };
}
