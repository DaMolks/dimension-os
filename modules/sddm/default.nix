{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.sddm;
  themeName = "dimension";
  themeConf = pkgs.writeText "dimension-sddm-theme.conf" ''
    [General]
    name=Dimension
    font=Noto Sans
    background=background.png
    backgroundColor=#000F1F
    accentColor=#0078D7
    textColor=#E8F0F8
    mutedTextColor=#93A4B7
    cardColor=#B3000F1F
    cardOverlayColor=#CC071523
    borderColor=#4D0078D7
  '';
  metadataDesktop = pkgs.writeText "dimension-sddm-metadata.desktop" ''
    [SddmGreeterTheme]
    Name=Dimension
    Description=Dimension OS SDDM theme
    Author=Dimension OS
    Copyright=(c) Dimension OS
    License=MIT
    Type=sddm-theme
    Version=1.0
    MainScript=Main.qml
    ConfigFile=theme.conf
    Theme-Id=${themeName}
    Theme-API=2.0
  '';
  mainQml = pkgs.writeText "dimension-sddm-Main.qml" ''
    import QtQuick 2.15
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
        property string cardColor: config.cardColor || "#B3000F1F"
        property string cardOverlayColor: config.cardOverlayColor || "#CC071523"
        property string borderColor: config.borderColor || "#4D0078D7"
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

        Rectangle {
            anchors.fill: parent
            color: "#26000F1F"
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 54
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.textColor
                font.family: config.font || "Noto Sans"
                font.pixelSize: 42
                font.weight: Font.Medium
                text: Qt.formatTime(root.currentDateTime, "HH:mm")
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.mutedTextColor
                font.family: config.font || "Noto Sans"
                font.pixelSize: 18
                text: Qt.formatDate(root.currentDateTime, "dddd d MMMM")
            }
        }

        Rectangle {
            id: loginCard
            anchors.centerIn: parent
            width: 400
            height: 352
            radius: 26
            color: root.cardColor
            border.width: 1
            border.color: root.borderColor
            clip: true

            ShaderEffectSource {
                id: cardBackgroundSource
                anchors.fill: parent
                sourceItem: backgroundImage
                sourceRect: Qt.rect(loginCard.x, loginCard.y, loginCard.width, loginCard.height)
                live: true
                hideSource: false
                visible: false
            }

            FastBlur {
                anchors.fill: parent
                source: cardBackgroundSource
                radius: 42
                transparentBorder: true
            }

            Rectangle {
                anchors.fill: parent
                color: root.cardOverlayColor
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 32
                spacing: 18

                Text {
                    Layout.fillWidth: true
                    color: root.textColor
                    font.family: config.font || "Noto Sans"
                    font.pixelSize: 28
                    font.weight: Font.Medium
                    text: "Welcome back"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        height: 52
                        radius: 14
                        color: "#66071523"
                        border.width: 1
                        border.color: usernameField.activeFocus ? root.accentColor : "#331D3550"

                        TextInput {
                            id: usernameField
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.textColor
                            selectionColor: root.accentColor
                            selectedTextColor: "#FFFFFF"
                            font.family: config.font || "Noto Sans"
                            font.pixelSize: 18
                            clip: true
                            text: userModel.lastUser || ""

                            Keys.onReturnPressed: root.submitLogin()
                            Keys.onEnterPressed: root.submitLogin()
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            visible: usernameField.text.length === 0
                            color: root.mutedTextColor
                            font.family: config.font || "Noto Sans"
                            font.pixelSize: 16
                            text: "Username"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 52
                        radius: 14
                        color: "#66071523"
                        border.width: 1
                        border.color: passwordField.activeFocus ? root.accentColor : "#331D3550"

                        TextInput {
                            id: passwordField
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.textColor
                            selectionColor: root.accentColor
                            selectedTextColor: "#FFFFFF"
                            font.family: config.font || "Noto Sans"
                            font.pixelSize: 18
                            clip: true
                            echoMode: TextInput.Password
                            inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText

                            Keys.onReturnPressed: root.submitLogin()
                            Keys.onEnterPressed: root.submitLogin()
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            visible: passwordField.text.length === 0
                            color: root.mutedTextColor
                            font.family: config.font || "Noto Sans"
                            font.pixelSize: 16
                            text: "Password"
                        }
                    }
                }

                Text {
                    id: statusText
                    Layout.fillWidth: true
                    minimumPixelSize: 14
                    color: "#F0B4C6"
                    font.family: config.font || "Noto Sans"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    visible: text.length > 0
                    text: ""
                }

                Rectangle {
                    id: loginButton
                    Layout.fillWidth: true
                    height: 54
                    radius: 14
                    color: mouseArea.pressed ? "#005EA8" : root.accentColor

                    Text {
                        anchors.centerIn: parent
                        color: "#FFFFFF"
                        font.family: config.font || "Noto Sans"
                        font.pixelSize: 18
                        font.weight: Font.Medium
                        text: "Log In"
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submitLogin()
                    }
                }
            }
        }

        Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 28
            anchors.bottomMargin: 22
            color: root.mutedTextColor
            font.family: config.font || "Noto Sans"
            font.pixelSize: 15
            text: sddm.hostname
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
    version = "1.0.0";
    dontUnpack = true;

    installPhase = ''
      theme_dir="$out/share/sddm/themes/${themeName}"

      mkdir -p "$theme_dir"
      cp ${themeConf} "$theme_dir/theme.conf"
      cp ${metadataDesktop} "$theme_dir/metadata.desktop"
      cp ${mainQml} "$theme_dir/Main.qml"
      cp ${../../assets/wallpapers/dimension-sddm-bg.png} "$theme_dir/background.png"
    '';
  };
  sddmPackage = pkgs.kdePackages.sddm.overrideAttrs (old: {
    buildCommand = old.buildCommand + ''
      rm -f "$out/share"
      mkdir -p "$out/share"
      cp -a ${pkgs.kdePackages.sddm.unwrapped}/share/. "$out/share/"
      mkdir -p "$out/share/sddm/themes"
      ln -s ${themePackage}/share/sddm/themes/${themeName} "$out/share/sddm/themes/${themeName}"
    '';
  });
in
{
  options.dimension.sddm.enable =
    lib.mkEnableOption "Dimension custom SDDM greeter theme";

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm = {
      package = sddmPackage;
      theme = themeName;
      extraPackages = [
        pkgs.kdePackages.qt5compat.out
      ];
    };
  };
}
