{
  config,
  lib,
  pkgs,
  ...
}:

let
  basePackages = with pkgs; [
    pass
    htop
    git
    unzip
    wget
    vim
    neovim
    curl
    btop
    maim
    nix-index
    zstd
    smartmontools
    geeqie
    parted
    pciutils
    usbutils
    nix-output-monitor
  ];

in
{

  # Package overrides for -march=znver4/znver5 builds:
  # - scipy: AVX-512/FMA changes FFT rounding beyond test tolerances
  # - rapidjson: valgrind doesn't support AVX-512 instructions (SIGILL)
  # - firefox: Clang can't honor #pragma GCC unroll in libstdc++ with znver cost model
  # - libtpms: passes Clang-only -Wno-self-assign to GCC, fatal with -Werror
  # - gsl: cholesky_invert precision exceeds tolerances with AVX-512/FMA
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (python-final: python-prev: {
          scipy = python-prev.scipy.overridePythonAttrs (old: {
            disabledTests = (old.disabledTests or [ ]) ++ [
              "test_roundtrip_scaling"
            ];
          });
        })
      ];
      rapidjson = prev.rapidjson.overrideAttrs (old: {
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [
          "-DVALGRIND_TESTS=OFF"
        ];
      });
      firefox-unwrapped = prev.firefox-unwrapped.overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [
          "--disable-warnings-as-errors"
        ];
      });
      libtpms = prev.libtpms.overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [
          "--disable-werror"
        ];
      });
      gsl = prev.gsl.overrideAttrs (_: {
        doCheck = false;
      });
    })
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.05";

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # Compress initrd with zstd for faster boot
  boot.initrd.compressor = "zstd";
  boot.initrd.compressorArgs = [
    "-19"
    "-T0"
  ];

  environment.systemPackages = basePackages;

  # Compressed swap in RAM (reduces disk swap, improves responsiveness)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Use tmpfs for /tmp (faster, avoids disk writes)
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "50%";
  };

  # External HDD as local binary cache
  fileSystems."/mnt/nixos-cache" = {
    device = "/dev/disk/by-uuid/3e8a24a2-b357-4d2b-9ec4-d05d02c91a2e";
    fsType = "ext4";
    options = [
      "nosuid"
      "nodev"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "user"
    ];
  };

  nix.settings.substituters = [ "file:///mnt/nixos-cache" ];

  # Automatic Nix store garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  services.printing.enable = true; # CUPS
  services.gvfs.enable = true; # Mount, trash, etc
  services.tumbler.enable = true; # Thumbnails

}
