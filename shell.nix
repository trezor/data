# the last successful build of nixos-22.05 (stable) as of 2022-10-26
with import
  (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/6107f97012a0c134c5848125b5aa1b149b76d2c9.tar.gz";
    sha256 = "1n3r4s53q2clynvd6v2css054kf0icyfhxgs79brqvmrsxa7d0db";
  })
{ };

stdenv.mkDerivation {
  name = "trezor-data";
  buildInputs = [
    bash
    awscli
    git-lfs
    git
    python39
  ];
}
