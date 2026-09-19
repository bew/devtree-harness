{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

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
    devShells = eachSystem (system: with (forSys system); {
      default = devsh.mkShell {
        packages = [
          pkgs.hello # example 😉
        ];
      };
    });
  };
}
