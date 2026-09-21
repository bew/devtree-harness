{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    systems.url = "github:nix-systems/default";
    devshell.url = "github:numtide/devshell";
  };

  outputs = { self, nixpkgs, systems, devshell, ... }@flakeInputs:

  let
    lib = nixpkgs.lib;
    eachSystem = lib.genAttrs (import systems);

    forSys = system: {
      pkgs = nixpkgs.legacyPackages.${system};
      devsh = devshell.legacyPackages.${system};
    };
  in
  {
    packages = eachSystem (system: with (forSys system); {
      devtree = pkgs.callPackage ./pkgs/devtree/package.nix { };
    });

    devShells = eachSystem (system: with (forSys system); {
      default = devsh.mkShell {
        packages = [
          # bd <https://beads.gascity.com/> 🤯
          (pkgs.beads.overrideAttrs {
            # On nixos-unstable, beads gets built and the checkPhase takes FOREVER to run.. @2026-09
            doCheck = false;
          })
        ];
      };
    });
  };
}
