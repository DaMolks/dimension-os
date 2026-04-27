{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.theme;
  dimensionColorScheme = pkgs.writeTextDir "share/color-schemes/Dimension.colors" ''
    [ColorEffects:Disabled]
    Color=56,56,56
    ColorAmount=0
    ColorEffect=0
    ContrastAmount=0.65
    ContrastEffect=1
    IntensityAmount=0.1
    IntensityEffect=2

    [ColorEffects:Inactive]
    Color=112,111,110
    ColorAmount=0.025
    ColorEffect=2
    ContrastAmount=0.1
    ContrastEffect=2
    IntensityAmount=0
    IntensityEffect=0

    [Colors:Button]
    BackgroundAlternate=32,40,52
    BackgroundNormal=37,49,64
    DecorationFocus=0,120,215
    DecorationHover=84,184,255
    ForegroundActive=84,184,255
    ForegroundInactive=124,145,168
    ForegroundLink=84,184,255
    ForegroundNegative=255,98,111
    ForegroundNeutral=255,194,82
    ForegroundNormal=232,240,248
    ForegroundPositive=115,210,147
    ForegroundVisited=150,120,220

    [Colors:Complementary]
    BackgroundAlternate=10,20,35
    BackgroundNormal=7,17,31
    DecorationFocus=0,120,215
    DecorationHover=84,184,255
    ForegroundActive=84,184,255
    ForegroundInactive=109,128,150
    ForegroundLink=84,184,255
    ForegroundNegative=255,98,111
    ForegroundNeutral=255,194,82
    ForegroundNormal=232,240,248
    ForegroundPositive=115,210,147
    ForegroundVisited=150,120,220

    [Colors:Selection]
    BackgroundAlternate=0,98,176
    BackgroundNormal=0,120,215
    DecorationFocus=0,120,215
    DecorationHover=84,184,255
    ForegroundActive=255,255,255
    ForegroundInactive=224,236,246
    ForegroundLink=255,255,255
    ForegroundNegative=255,235,238
    ForegroundNeutral=255,247,216
    ForegroundNormal=255,255,255
    ForegroundPositive=235,255,241
    ForegroundVisited=245,236,255

    [Colors:Tooltip]
    BackgroundAlternate=24,35,48
    BackgroundNormal=18,27,40
    DecorationFocus=0,120,215
    DecorationHover=84,184,255
    ForegroundActive=84,184,255
    ForegroundInactive=124,145,168
    ForegroundLink=84,184,255
    ForegroundNegative=255,98,111
    ForegroundNeutral=255,194,82
    ForegroundNormal=232,240,248
    ForegroundPositive=115,210,147
    ForegroundVisited=150,120,220

    [Colors:View]
    BackgroundAlternate=21,31,44
    BackgroundNormal=14,24,37
    DecorationFocus=0,120,215
    DecorationHover=84,184,255
    ForegroundActive=84,184,255
    ForegroundInactive=124,145,168
    ForegroundLink=84,184,255
    ForegroundNegative=255,98,111
    ForegroundNeutral=255,194,82
    ForegroundNormal=232,240,248
    ForegroundPositive=115,210,147
    ForegroundVisited=150,120,220

    [Colors:Window]
    BackgroundAlternate=28,38,52
    BackgroundNormal=19,29,43
    DecorationFocus=0,120,215
    DecorationHover=84,184,255
    ForegroundActive=84,184,255
    ForegroundInactive=124,145,168
    ForegroundLink=84,184,255
    ForegroundNegative=255,98,111
    ForegroundNeutral=255,194,82
    ForegroundNormal=232,240,248
    ForegroundPositive=115,210,147
    ForegroundVisited=150,120,220

    [General]
    ColorScheme=Dimension
    Name=Dimension
    shadeSortColumn=true

    [KDE]
    contrast=4

    [WM]
    activeBackground=0,120,215
    activeBlend=20,31,46
    activeForeground=255,255,255
    inactiveBackground=28,38,52
    inactiveBlend=18,27,40
    inactiveForeground=196,207,219
  '';
in
{
  options.dimension.theme.enable =
    lib.mkEnableOption "Dimension visual theme foundations";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      papirus-icon-theme
      layan-cursors
      kdePackages.qtstyleplugin-kvantum
      dimensionColorScheme
    ];
  };
}
