{
  # TODO: maybe add PCSat
  inputs = {
    opam-nix.url = "github:tweag/opam-nix";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "opam-nix/nixpkgs";
    hoice.url = "github:/KenSakayori/flakes/?dir=hoice";
    eldarica.url = "github:/KenSakayori/flakes/?dir=eldarica";
    ppx-cmdliner = {
      url = "github:hammerlab/ppx_deriving_cmdliner";
      flake = false;
    };
    rethfl= {
      url = "github:hopv/rethfl";
      flake = false;
    };

  };

  outputs =
    {
      self,
      flake-utils,
      opam-nix,
      nixpkgs,
      hoice,
      eldarica,
      ppx-cmdliner,
      rethfl
    }@inputs:
    # Don't forget to put the package name instead of `throw':
    let package = "rethfl";
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        on = opam-nix.lib.${system};

        # Since pin-depends without a specific commit hash cannot be build in a
        # pure mode, we make a repo ourselves and use pinDepens=false
        # Note that we are exploiting the behaviour of makeOpamRepo:
        # packages for which the version can not be inferred get dev as their version.
        ppx-cmdliner-repo = on.makeOpamRepo ppx-cmdliner;
        scope =
          on.buildOpamProject
            {
              pinDepends =false;
              repos = [ ppx-cmdliner-repo opam-nix.inputs.opam-repository ];
            }
            package rethfl { ocaml-base-compiler = "*"; };
        overlay = final: prev:
          {
            rethfl = prev.rethfl.overrideAttrs (_: {
            buildInputs = [ pkgs.makeWrapper ];
            postFixup = ''
                      wrapProgram $out/bin/rethfl \
                      --set PATH ${pkgs.lib.makeBinPath
                        [
                          pkgs.z3_4_8
                          hoice.packages.${system}.default
                          eldarica.packages.${system}.default
                        ]}
                      '';
            });
          };
      in {
        legacyPackages = scope.overrideScope' overlay;
        packages.default = self.legacyPackages.${system}.${package};
      });
}
