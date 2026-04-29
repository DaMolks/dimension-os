{ config, lib, ... }:

let
  cfg = config.dimension.installer.disk;

  swapPartition = lib.optionalAttrs (cfg.swapSize != "0") {
    swap = {
      size = cfg.swapSize;
      priority = 2;
      content = {
        type = "swap";
      };
    };
  };
in
{
  options.dimension.installer.disk = {
    device = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "/dev/sda";
      description = "Target disk used by the Dimension installer. Empty disables disko configuration.";
    };

    swapSize = lib.mkOption {
      type = lib.types.str;
      default = "0";
      example = "8G";
      description = "Swap partition size. Set to 0 to skip swap.";
    };

    encrypt = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Reserved for a future encrypted install layout.";
    };
  };

  config = lib.mkIf (cfg.device != "") (lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.encrypt;
          message = "dimension.installer.disk.encrypt is reserved for later and is not supported yet.";
        }
      ];
    }

    (lib.mkIf (!cfg.encrypt) {
      disko.devices.disk.main = {
        type = "disk";
        device = cfg.device;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "512M";
              priority = 1;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          } // swapPartition;
        };
      };

      boot.loader = {
        systemd-boot.enable = lib.mkDefault true;
        efi.canTouchEfiVariables = lib.mkDefault true;
      };

      fileSystems."/" = {
        device = lib.mkDefault "/dev/disk/by-partlabel/disk-main-root";
        fsType = lib.mkDefault "ext4";
      };

      fileSystems."/boot" = {
        device = lib.mkDefault "/dev/disk/by-partlabel/disk-main-ESP";
        fsType = lib.mkDefault "vfat";
        options = lib.mkDefault [ "umask=0077" ];
      };
    })
  ]);
}
