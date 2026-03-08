{
  config,
  lib,
  pkgs,
  ...
}:

{

  imports = [
    ./cpu.nix
  ];

  nixpkgs.hostPlatform = {
    system = "x86_64-linux";
    #gcc.arch = "znver5";
    #gcc.tune = "znver5";
  };

  environment.sessionVariables = {
    RUSTFLAGS = "-C target-cpu=znver5 -C link-arg=-flto";
    GOAMD64 = "v4";
  };

}
