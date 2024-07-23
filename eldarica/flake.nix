{
  inputs = {
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*.tar.gz";

    nixpkgs.url = "github:NixOS/nixpkgs";

    sbt.url = "github:zaninime/sbt-derivation";
    sbt.inputs.nixpkgs.follows = "nixpkgs";
    eldarica = {
      url = "github:uuverifiers/eldarica";
      flake = false;
    };
  };

  outputs = { self, flake-schemas, nixpkgs, sbt, eldarica }:
    let supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];
        forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in {
      schemas = flake-schemas.schemas;
      packages = forEachSupportedSystem ({ pkgs }:
        let eldarica-package  = sbt.mkSbtDerivation.${pkgs.system} {
              pname = "eld";
              version = "0.0.1";
              src = eldarica;
              # WARNING: I'm not sure if we can use the same hash for aarc
              # Quote from README of sbt-derivation
              # > The dependencies derivation is a fixed-output derivation,
              # > it has a hash that needs to be changed each time the dependencies
              # > are updated or changed in any way.
              # > It's also far from trivial to calculate this hash programmatically,
              # > strictly from the project files. The proposed solution is trust on first use
              # > (aka let a build fail the first time and use the hash that Nix prints).
              depsSha256 = "sha256-LxoZZ+3oKA2/UinASJtHH5INLGeT9SkbwUI7+CEa+Z4=";
              buildPhase = ''
              sbt assembly
              '';

              # WARNING:I'm not entirely sure what needs to be copied for eldarica to work
              installPhase = ''
              mkdir -p $out/bin/target
              cp -r target/scala-2.* $out/bin/target
              cp eld eld-client eldEnv $out/bin
              '';
            };
        in
          {
            eldarica = eldarica-package;
            default = eldarica-package;
          });
    };
}
