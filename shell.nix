# the last successful build of nixpkgs-unstable as of 2025-06-25
with import
  (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/992f916556fcfaa94451ebc7fc6e396134bbf5b1.tar.gz";
    sha256 = "0wbqb6sy58q3mnrmx67ffdx8rq10jg4cvh4jx3rrbr1pqzpzsgxc";
  })
{ };

stdenv.mkDerivation {
  name = "trezor-data";
  buildInputs = [
    bash
    awscli
    git-lfs
    git
    nodePackages.prettier
    (python3.withPackages (p: [ p.click ]))
    shellcheck
  ];
}
