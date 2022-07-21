{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nmattia/naersk";
    mozillapkgs = {
      url = "github:mozilla/nixpkgs-mozilla";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, naersk, mozillapkgs }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages."${system}";

      # Get a specific rust version
      mozilla = pkgs.callPackage (mozillapkgs + "/package-set.nix") {};
      rust = (mozilla.rustChannelOf {
        date = "2021-11-02"; # get the current date with `date -I`
        channel = "nightly"; sha256 = "bwQaklG7v5gSKLTQwqAxUkvRaSTcqIc71COox7z3Ct4=";
      }).rust.override {
        targets = [ "x86_64-unknown-linux-gnu" "aarch64-unknown-none" ];
        extensions = [ "rust-src" ];
      };

      # Override the version used in naersk
      naersk-lib = naersk.lib."${system}".override {
        cargo = rust;
        rustc = rust;
      };
    in rec {
      # `nix build`
      packages.my-project = naersk-lib.buildPackage {
        pname = "immutable-arena";
        root = ./.;
      };
      defaultPackage = packages.my-project;

      # `nix develop`
      devShell = pkgs.mkShell {
        # supply the specific rust version
        nativeBuildInputs = [ rust ];
      };
    });
}
