{
  description = "Build NixOS images for PineTab";

  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    rockchip = {
      url = "github:nabam/nixos-rockchip";
    };
  };

  # Use cache with packages from nabam/nixos-rockchip CI.
  nixConfig = {
    extra-substituters = [ "https://nabam-nixos-rockchip.cachix.org" ];
    extra-trusted-public-keys = [
      "nabam-nixos-rockchip.cachix.org-1:BQDltcnV8GS/G86tdvjLwLFz1WeFqSk7O9yl+DR0AVM"
    ];
  };

  outputs =
    { self, ... }@inputs:
    let
      devices = buildPlatform: {
        "pinetab2-gnome" = {
          # Use cross-compilation for uBoot and Kernel.
          uBoot = inputs.rockchip.packages.${buildPlatform}.uBootPineTab2;
          kernel = inputs.rockchip.legacyPackages.${buildPlatform}.kernel_linux_6_12_pinetab;
          firmware = [ inputs.rockchip.packages.${buildPlatform}.bes2600 ];

          extraModules = [
            ./pinetab2-gnome.nix
            inputs.rockchip.nixosModules.dtOverlayPCIeFix
            inputs.rockchip.nixosModules.noZFS
          ];
        };
      };

      osConfigs =
        buildPlatform:
        builtins.mapAttrs (
          name: value:
          inputs.nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              inputs.rockchip.nixosModules.sdImageRockchip
              {
                rockchip.uBoot = value.uBoot;
                boot.kernelPackages = value.kernel;
                hardware.firmware = value.firmware;
              }
            ] ++ value.extraModules;
          }
        ) (devices buildPlatform);

      images =
        buildPlatform:
        builtins.mapAttrs (name: value: value.config.system.build.sdImage) (osConfigs buildPlatform);
    in
    {
      # Set buildPlatform to "x86_64-linux" to benefit from cross-compiled packages in the cache.
      nixosConfigurations = osConfigs "x86_64-linux";
    }
    // inputs.utils.lib.eachDefaultSystem (system: {
      # Set buildPlatform to "x86_64-linux" to benefit from cross-compiled packages in the cache.
      packages = {
        default = self.packages.${system}."pinetab2-gnome";
      } // images "x86_64-linux";

      formatter = (import inputs.nixpkgs { inherit system; }).nixfmt-rfc-style;
    });
}
