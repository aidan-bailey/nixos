{
  config,
  lib,
  ...
}:

{

  options.custom = {
    hostType = lib.mkOption {
      type = lib.types.enum [
        "laptop"
        "desktop"
        "server"
      ];
      description = "Host form factor — controls power management, sleep, and TLP behavior.";
    };

    display.type = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "oled"
          "lcd"
        ]
      );
      default = null;
      description = "Display panel technology — controls font rendering (subpixel vs grayscale).";
    };
  };

}
