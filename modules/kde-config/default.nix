{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.kde;
  edition = config.dimension.edition or "desktop";
  isGaming = edition == "gaming";
  xpropPackage =
    if pkgs ? xprop
    then pkgs.xprop
    else pkgs.xorg.xprop;
  mangoHudToggle = pkgs.symlinkJoin {
    name = "dimension-mangohud-toggle";
    paths = [
      (pkgs.writeShellScriptBin "dimension-mangohud-toggle" ''
        set -eu

        config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/MangoHud"
        config_file="$config_dir/MangoHud.conf"
        tmp_file="$(${pkgs.coreutils}/bin/mktemp)"

        cleanup() {
          ${pkgs.coreutils}/bin/rm -f "$tmp_file"
        }

        trap cleanup EXIT

        ${pkgs.coreutils}/bin/mkdir -p "$config_dir"

        if [ -f "$config_file" ] && ${pkgs.gnugrep}/bin/grep -Eq '^[[:space:]]*no_display([[:space:]]*=.*)?$' "$config_file"; then
          ${pkgs.gnused}/bin/sed '/^[[:space:]]*no_display([[:space:]]*=.*)?$/d' "$config_file" > "$tmp_file"
        else
          if [ -f "$config_file" ]; then
            ${pkgs.coreutils}/bin/cp "$config_file" "$tmp_file"
          fi
          printf '%s\n' 'no_display' >> "$tmp_file"
        fi

        ${pkgs.coreutils}/bin/mv "$tmp_file" "$config_file"
      '')
      (pkgs.writeTextDir "share/applications/dimension-mangohud-toggle.desktop" ''
        [Desktop Entry]
        Type=Application
        Version=1.0
        Name=MangoHud Toggle
        Comment=Toggle MangoHud default visibility for future launches
        Exec=dimension-mangohud-toggle
        Icon=applications-games
        Categories=Game;Utility;
        Terminal=false
      '')
    ];
  };
  dimensionForceBlur = pkgs.stdenvNoCC.mkDerivation {
    pname = "dimension-kwin-forceblur";
    version = "1.0.0";
    dontUnpack = true;

    installPhase = ''
      script_dir="$out/share/kwin/scripts/dimension-forceblur"
      install -d "$script_dir/contents/ui" "$script_dir/contents/config" "$out/share/kservices5" "$out/share/kservices6"

      cat > "$script_dir/metadata.desktop" <<'EOF'
[Desktop Entry]
Name=Dimension Force Blur
Comment=Force KWin blur hints for Dimension glass windows
Icon=preferences-system-windows-script-test
Type=Service
X-Plasma-API=declarativescript
X-Plasma-MainScript=ui/main.qml
X-KDE-ServiceTypes=KWin/Script
X-KDE-PluginInfo-Author=Dimension OS
X-KDE-PluginInfo-Name=dimension-forceblur
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-License=MIT
EOF

      cat > "$script_dir/metadata.json" <<'EOF'
{
  "KPackageStructure": "KWin/Script",
  "KPlugin": {
    "Authors": [
      {
        "Name": "Dimension OS"
      }
    ],
    "Description": "Force KWin blur hints for Dimension glass windows",
    "Icon": "preferences-system-windows-script-test",
    "Id": "dimension-forceblur",
    "License": "MIT",
    "Name": "Dimension Force Blur",
    "Version": "1.0"
  },
  "X-Plasma-API": "declarativescript",
  "X-Plasma-MainScript": "ui/main.qml"
}
EOF

      cat > "$script_dir/contents/config/main.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.kde.org/standards/kcfg/1.0 http://www.kde.org/standards/kcfg/1.0/kcfg.xsd">
  <kcfgfile name=""/>
  <group name="General">
    <entry name="patterns" type="String">
      <label>Window classes, one per line.</label>
      <default>plasmashell
krunner
ksmserver</default>
    </entry>
    <entry name="blurMatching" type="Bool">
      <label>Blur matching classes instead of treating them as a blacklist.</label>
      <default>false</default>
    </entry>
    <entry name="blurContent" type="Bool">
      <label>Blur only the window content region.</label>
      <default>true</default>
    </entry>
  </group>
</kcfg>
EOF

      cat > "$script_dir/contents/ui/main.qml" <<'EOF'
import QtQuick 2.15
import org.kde.kwin 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: root

    readonly property var patterns: KWin.readConfig("patterns", "plasmashell\nkrunner\nksmserver")
        .split("\n")
        .map(function(pattern) { return pattern.trim().toLowerCase(); })
        .filter(function(pattern) { return pattern.length > 0; })
    readonly property bool blurMatching: KWin.readConfig("blurMatching", false)
    readonly property bool blurContent: KWin.readConfig("blurContent", true)

    PlasmaCore.DataSource {
        id: shell
        engine: "executable"
        connectedSources: []

        function run(command) {
            shell.connectSource(command)
        }

        onNewData: shell.disconnectSource(sourceName)
    }

    function geometryOf(window) {
        if (window.frameGeometry) {
            return window.frameGeometry
        }
        return window.geometry
    }

    function classOf(window) {
        var names = []
        try { names.push(window.resourceClass.toString().toLowerCase()) } catch (e) {}
        try { names.push(window.resourceName.toString().toLowerCase()) } catch (e) {}
        return names
    }

    function idOf(window) {
        try {
            if (window.windowId) {
                return "0x" + window.windowId.toString(16)
            }
        } catch (e) {}
        return ""
    }

    function shouldBlur(window) {
        var names = classOf(window)
        var matched = false
        for (var i = 0; i < names.length; i++) {
            if (patterns.indexOf(names[i]) >= 0) {
                matched = true
            }
        }
        return matched === blurMatching
    }

    function applyBlur(window) {
        if (!window || !shouldBlur(window)) {
            return
        }

        var id = idOf(window)
        if (id.length === 0) {
            return
        }

        if (!blurContent) {
            shell.run("${xpropPackage}/bin/xprop -f _KDE_NET_WM_BLUR_BEHIND_REGION 32c -set _KDE_NET_WM_BLUR_BEHIND_REGION 0 -id " + id)
            return
        }

        var geometry = geometryOf(window)
        if (!geometry) {
            return
        }

        var region = "0,0," + geometry.width + "," + geometry.height
        shell.run("${xpropPackage}/bin/xprop -id " + id + " -f _KDE_NET_WM_BLUR_BEHIND_REGION 32c -set _KDE_NET_WM_BLUR_BEHIND_REGION " + region)
    }

    function registerWindow(window) {
        applyBlur(window)
        if (window && window.geometryChanged) {
            window.geometryChanged.connect(function() { applyBlur(window) })
        }
        if (window && window.frameGeometryChanged) {
            window.frameGeometryChanged.connect(function() { applyBlur(window) })
        }
    }

    Component.onCompleted: {
        var windows = workspace.windowList ? workspace.windowList() : workspace.clientList()
        for (var i = 0; i < windows.length; i++) {
            registerWindow(windows[i])
        }

        if (workspace.windowAdded) {
            workspace.windowAdded.connect(registerWindow)
        } else if (workspace.clientAdded) {
            workspace.clientAdded.connect(registerWindow)
        }
    }
}
EOF

      install -m 0644 "$script_dir/metadata.desktop" "$out/share/kservices5/dimension-forceblur.desktop"
      install -m 0644 "$script_dir/metadata.desktop" "$out/share/kservices6/dimension-forceblur.desktop"
    '';
  };
in
{
  imports = [
    ./plasma-home.nix
  ];

  options.dimension.kde = {
    enable =
      lib.mkEnableOption "Dimension minimal KDE visual configuration";

    panel.enable =
      lib.mkEnableOption "Dimension default Plasma 6 panel managed by plasma-manager";
  };

  config = lib.mkIf cfg.enable {
    dimension.kde.panel.enable = lib.mkDefault true;

    # Ensure these packages are present even if the theme module is disabled.
    environment.systemPackages =
      (with pkgs; [
        papirus-icon-theme
        layan-cursors
        xpropPackage
        dimensionForceBlur
      ])
      ++ lib.optionals (cfg.panel.enable && isGaming) [
        pkgs.kdePackages.kdeplasma-addons
        pkgs.mangohud
        mangoHudToggle
      ];

    # System-wide KDE defaults written to /etc/xdg/.
    # KDE reads these as defaults; per-user settings in ~/.config/ take
    # precedence once changed in KDE System Settings.
    environment.etc = {
      "xdg/kdeglobals".text = ''
        [Icons]
        Theme=Papirus-Dark

        [General]
        ColorScheme=Dimension
        font=Inter,11,-1,5,50,0,0,0,0,0
        fixed=JetBrains Mono,10,-1,5,50,0,0,0,0,0
        smallestReadableFont=Inter,8,-1,5,50,0,0,0,0,0
        toolBarFont=Inter,10,-1,5,50,0,0,0,0,0
        menuFont=Inter,10,-1,5,50,0,0,0,0,0

        [KDE]
        LookAndFeelPackage=org.kde.breezedark.desktop
        SingleClick=false
        widgetStyle=kvantum
        splashScreen=none

        [Mouse]
        cursorTheme=layan-cursors
      '';

      "xdg/kwinrc".text = ''
        [org.kde.kdecoration2]
        library=com.github.paulmcauley.klassy
        theme=Klassy
        ButtonsOnLeft=
        ButtonsOnRight=IAX

        [Compositing]
        OpenGLIsUnsafe=false

        [Effect-blur]
        BlurStrength=8
        NoiseStrength=2

        [Effect-Blur]
        BlurStrength=8
        NoiseStrength=2

        [Effect-overview]
        BorderActivate=9

        [Effect-Login]
        Enabled=false
        LoginEffect=none

        [Plugins]
        blurEnabled=true
        contrastEnabled=true
        translucencyEnabled=true
        dimension-forceblurEnabled=true

        [Script-dimension-forceblur]
        patterns=plasmashell\nkrunner\nksmserver
        blurMatching=false
        blurContent=true
      '';

      "xdg/ksplashrc".text = ''
        [KSplash]
        Engine=none
        Theme=none
      '';

      # kcminputrc is the authoritative source for cursor settings in KDE.
      "xdg/kcminputrc".text = ''
        [Mouse]
        cursorTheme=layan-cursors
        cursorSize=24
      '';

      "xdg/baloofilerc".text = ''
        [Basic Settings]
        Indexing-Enabled=true

        [General]
        folders[$e]=$HOME,/mnt/dimension
        exclude folders[$e]=/proc,/sys,/dev,/nix,/run,/boot,/tmp
      '';

      "xdg/konsolerc".text = ''
        [Desktop Entry]
        DefaultProfile=Dimension.profile

        [Favorite Profiles]
        Favorites=Dimension.profile
      '';

      "xdg/konsole/Dimension.profile".text = ''
        [Appearance]
        ColorScheme=Dimension

        [General]
        Name=Dimension
        Parent=FALLBACK/
        TerminalColumns=120
        TerminalRows=32

        [Interaction Options]
        AutoCopySelectedText=false
        OpenLinksByDirectClickEnabled=true

        [Scrolling]
        HistoryMode=2
        HistorySize=10000

        [Terminal Features]
        BlinkingCursorEnabled=true
        FlowControlEnabled=true

        [Text Appearance]
        Font=JetBrains Mono,11,-1,5,50,0,0,0,0,0
      '';

      "xdg/konsole/Dimension.colorscheme".text = ''
        [Background]
        Color=0,15,31
        Transparency=15

        [BackgroundIntense]
        Color=7,21,35
        Transparency=10

        [Color0]
        Color=0,15,31

        [Color1]
        Color=255,98,111

        [Color2]
        Color=115,210,147

        [Color3]
        Color=255,194,82

        [Color4]
        Color=0,120,215

        [Color5]
        Color=150,120,220

        [Color6]
        Color=84,184,255

        [Color7]
        Color=232,240,248

        [Foreground]
        Color=232,240,248

        [General]
        Description=Dimension
        Opacity=0.85
        Wallpaper=
      '';
    };
  };
}
