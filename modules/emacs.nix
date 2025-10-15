{ pkgs, ... }:
let
  emacs-pgtk-native = pkgs.emacs-pgtk.override {
    withNativeCompilation = true;
  };
in
{
  environment.systemPackages = [
    (pkgs.emacsWithPackagesFromUsePackage {
      config = "";

      defaultInitFile = false;

      package = emacs-pgtk-native;
      alwaysEnsure = false;

      extraEmacsPackages = epkgs: [
        epkgs.cask
        pkgs.shellcheck
        pkgs.ripgrep
        pkgs.shfmt
        pkgs.fd
      ];
    })
  ];
}
