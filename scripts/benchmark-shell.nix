{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "benchmarking";

  # Build toolchain — PTS tests compile from source
  nativeBuildInputs = with pkgs; [
    gcc
    cmake
    gnumake
    autoconf
    automake
    libtool
    pkg-config
    bc
    bison
    flex
    yasm
    nasm
    p7zip
  ];

  # Libraries — mkShell exposes these via NIX_CFLAGS_COMPILE / NIX_LDFLAGS
  # so gcc/cmake find headers and .so files automatically
  buildInputs = with pkgs; [
    # MPI
    openmpi

    # OpenCL
    ocl-icd
    opencl-headers

    # Crypto
    openssl

    # Math (gmp + mpfr + libmpc needed for GCC plugin compilation in allmodconfig)
    gmp
    mpfr
    libmpc

    # Linux AIO
    libaio

    # C++ libraries
    boost

    # Image libraries
    libjpeg
    libtiff
    libpng
    zlib

    # Kernel build
    elfutils
  ];

  # PTS dependency checker doesn't understand Nix — skip it
  shellHook = ''
    export FORCE_TIMES_TO_RUN=1
    export SKIP_EXTERNAL_DEPENDENCIES=1

    # The kernel build's host tools (fixdep, objtool, etc.) are compiled with
    # HOSTCC.  NixOS's gcc wrapper injects NIX_CFLAGS_COMPILE and NIX_LDFLAGS
    # into every invocation — flags like -frandom-seed and -rpath get forwarded
    # to ld where they are misinterpreted as file arguments.  Unset them and
    # re-export the include / library search paths through the standard env vars
    # that gcc and ld honour without wrapper magic.

    # Collect -isystem paths → C_INCLUDE_PATH  (colon-separated)
    _inc=""
    for p in $NIX_CFLAGS_COMPILE; do
      if [ "$_prev" = "-isystem" ]; then
        _inc="''${_inc:+$_inc:}$p"
      fi
      _prev="$p"
    done
    export C_INCLUDE_PATH="''${_inc}''${C_INCLUDE_PATH:+:$C_INCLUDE_PATH}"
    export CPLUS_INCLUDE_PATH="''${_inc}''${CPLUS_INCLUDE_PATH:+:$CPLUS_INCLUDE_PATH}"

    # Collect -L paths → LIBRARY_PATH  (colon-separated)
    _lib=""
    for p in $NIX_LDFLAGS; do
      case "$p" in
        -L*) _lib="''${_lib:+$_lib:}''${p#-L}" ;;
      esac
    done
    export LIBRARY_PATH="''${_lib}''${LIBRARY_PATH:+:$LIBRARY_PATH}"

    unset NIX_CFLAGS_COMPILE NIX_LDFLAGS NIX_LDFLAGS_BEFORE
    unset _inc _lib _prev
  '';

  hardeningDisable = [ "all" ];
}
