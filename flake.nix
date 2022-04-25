{
  description = "NixOS + Openstack tooling";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs
    , self
    , ...
    }@inputs:
    let
      nameValuePair = name: value: { inherit name value; };
      genAttrs = names: f: builtins.listToAttrs (map (n: nameValuePair n (f n)) names);

      pkgsFor = pkgs: system:
        import pkgs { inherit system; };

      allSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" ];
      forAllSystems = f: genAttrs allSystems
        (system: f {
          inherit system;
          pkgs = pkgsFor nixpkgs system;
        });

      mkSystem =
        { system
        , extraModules ? [ ]
        }:
        let
          pkgs = pkgsFor nixpkgs system;

          modules = extraModules;
        in
        nixpkgs.lib.nixosSystem {
          inherit system modules pkgs;
        };
    in
    {
      images = {
        zfs.x86_64-linux = (mkSystem
          {
            system = "x86_64-linux";
            extraModules = [ "${nixpkgs}/nixos/maintainers/scripts/openstack/openstack-image-zfs.nix" ];
          }).config.system.build.openstackImage;
      };

      devShell = forAllSystems
        ({ pkgs, ... }:
          pkgs.mkShell {
            buildInputs = with pkgs; [
              codespell
              findutils
              git
              jq
              nixpkgs-fmt
              nixUnstable

              (terraform_1.withPlugins (p: [
                p.openstack
              ]))
            ];
          }
        );
    };
}
