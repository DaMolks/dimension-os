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
    home-manager.users.${mainUser} = { ... }: {
      imports = [
        plasmaManagerModule
      ];

      home.stateVersion = stateVersion;

      programs.plasma = {
        enable = true;

        panels = lib.optional cfg.panel.enable {
          location = "bottom";
          alignment = "center";
          floating = true;
          height = 48;
          lengthMode = "fit";
          minLength = 720;
          maxLength = 1160;
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
            "org.kde.plasma.panelspacer"
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
          wallpaper = ../../assets/wallpapers/dimension-desktop-dark.png;
          colorScheme = "Dimension";
          lookAndFeel = "org.kde.breezedark.desktop";
          iconTheme = "Papirus-Dark";
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
          kdeglobals = {
            KDE = {
              widgetStyle = "kvantum";
              splashScreen = "none";
            };
          };

          ksplashrc.KSplash = {
            Engine = "none";
            Theme = "None";
          };

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
