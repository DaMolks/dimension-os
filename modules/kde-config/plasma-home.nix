# Inspirations retained: nix-community/plasma-manager panel/workspace/KWin
# examples, pjones' original declarative Plasma direction, and macOS-like
# centered floating panel dotfiles.
{ config, inputs, lib, pkgs, ... }:

let
  cfg = config.dimension.kde;
  mainUser = config.dimension.mainUser;
  stateVersion = config.system.stateVersion or "24.05";
  plasmaManagerModule =
    inputs.plasma-manager.homeModules.plasma-manager
      or inputs.plasma-manager.homeManagerModules.plasma-manager;
in
{
  config = lib.mkIf cfg.enable {
    home-manager.users.${mainUser} = { config, pkgs, ... }:
      let
        desktopWallpaper = "${config.xdg.dataHome}/wallpapers/dimension-desktop-dark.png";
        konsoleColorScheme = pkgs.writeText "Dimension.colorscheme" ''
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
      in
      {
      imports = [
        plasmaManagerModule
      ];

      home.stateVersion = stateVersion;

      manual = {
        html.enable = false;
        json.enable = false;
        manpages.enable = false;
      };

      xdg.dataFile."wallpapers/dimension-desktop-dark.png".source =
        ../../assets/wallpapers/dimension-desktop-dark.png;

      programs.konsole = {
        enable = true;
        defaultProfile = "Dimension";
        customColorSchemes.Dimension = konsoleColorScheme;
        profiles.Dimension = {
          colorScheme = "Dimension";
          font = {
            name = "JetBrains Mono";
            size = 11;
          };
          extraConfig = {
            General = {
              TerminalColumns = 120;
              TerminalRows = 32;
            };
            "Interaction Options" = {
              AutoCopySelectedText = false;
              OpenLinksByDirectClickEnabled = true;
            };
            Scrolling = {
              HistoryMode = 2;
              HistorySize = 10000;
            };
            "Terminal Features" = {
              BlinkingCursorEnabled = true;
              FlowControlEnabled = true;
            };
          };
        };
      };

      programs.plasma = {
        enable = true;
        overrideConfig = true;

        panels = lib.optional cfg.panel.enable {
          location = "bottom";
          alignment = "center";
          floating = true;
          height = 48;
          lengthMode = "fit";
          minLength = 560;
          maxLength = 920;
          opacity = "translucent";
          widgets = [
            {
              kickoff = {
                icon = "start-here-kde";
                compactDisplayStyle = true;
                sortAlphabetically = true;
              };
            }
            {
              iconTasks = {
                launchers = [
                  "applications:dimension-search.desktop"
                  "applications:org.kde.dolphin.desktop"
                  "applications:org.kde.konsole.desktop"
                  "applications:firefox.desktop"
                ];
                appearance = {
                  showTooltips = true;
                  highlightWindows = true;
                  iconSpacing = "medium";
                };
              };
            }
            "org.kde.plasma.systemtray"
            {
              digitalClock = {
                date = {
                  enable = true;
                  format = "shortDate";
                };
              };
            }
            "org.kde.plasma.showdesktop"
          ];
        };

        workspace = {
          wallpaper = desktopWallpaper;
          colorScheme = "Dimension";
          iconTheme = "Papirus-Dark";
          widgetStyle = "kvantum";
          splashScreen = {
            engine = "none";
            theme = "None";
          };
          cursor = {
            theme = "layan-cursors";
            size = 24;
          };
        };

        fonts = {
          general = {
            family = "Inter";
            pointSize = 11;
          };
          fixedWidth = {
            family = "JetBrains Mono";
            pointSize = 10;
          };
          small = {
            family = "Inter";
            pointSize = 8;
          };
          toolbar = {
            family = "Inter";
            pointSize = 10;
          };
          menu = {
            family = "Inter";
            pointSize = 10;
          };
          windowTitle = {
            family = "Inter";
            pointSize = 10;
            weight = "medium";
          };
        };

        kwin = {
          effects = {
            blur = {
              enable = true;
              strength = 8;
              noiseStrength = 2;
            };
            translucency.enable = true;
            desktopSwitching.animation = "slide";
            windowOpenClose.animation = "glide";
          };
          titlebarButtons = {
            left = [ ];
            right = [ "minimize" "maximize" "close" ];
          };
        };

        configFile = {
          kwinrc = {
            Plugins = {
              blurEnabled = true;
              contrastEnabled = true;
              translucencyEnabled = true;
              "dimension-forceblurEnabled" = true;
            };
            "org.kde.kdecoration2" = {
              library = "com.github.paulmcauley.klassy";
              theme = "Klassy";
            };
            "Script-dimension-forceblur" = {
              patterns = "plasmashell\nkrunner\nksmserver";
              blurMatching = false;
              blurContent = true;
            };
            "Effect-Login" = {
              Enabled = false;
              LoginEffect = "none";
            };
          };
        };
      };
    };
  };
}
