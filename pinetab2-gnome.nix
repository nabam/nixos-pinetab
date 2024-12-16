{
  config,
  pkgs,
  lib,
  ...
}:
{
  system.stateVersion = "24.11";

  networking.hostName = "pinetab2-gnome";

  users.users.pinetab2 = {
    initialPassword = "changeme";
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  boot.kernelParams = [
    "console=ttyS2,1500000n8"
    "rootwait"
    "root=LABEL=NIXOS_SD"
    "rw"
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "bes2600-firmware"
      "bes2600-firmware-aarch64-unknown-linux-gnu"
    ];

  zramSwap.enable = true;

  networking.networkmanager.enable = true;

  services = {
    xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
      displayManager.gdm.enable = true;
    };

    automatic-timezoned.enable = true;
    geoclue2.enableDemoAgent = lib.mkForce true;

    avahi = {
      enable = true;
      openFirewall = true;
    };

    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
    };
  };

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  security.sudo.enable = true;

  environment.systemPackages = with pkgs; [
    cachix
    gnomeExtensions.arc-menu
    gnomeExtensions.dash-to-dock
    gnomeExtensions.dash-to-panel
    gnomeExtensions.gjs-osk
    gnomeExtensions.one-window-wonderland
  ];

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
