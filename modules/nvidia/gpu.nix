{
  config,
  lib,
  pkgs,
  ...
}:

{

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    nvidiaPersistenced = true; # keep driver state loaded — faster app/CUDA launches
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      libva-vdpau-driver
    ];
  };

  hardware.nvidia-container-toolkit.enable = true;

  # Coolbits 24 = fan control (8) + clock offset tuning (16)
  services.xserver.screenSection = ''
    Option "Coolbits" "24"
  '';

  environment.variables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
    LIBVA_DRIVER_NAME = "nvidia";
    __GL_SHADER_DISK_CACHE = "1"; # persistent shader cache
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1"; # don't prune old shaders
    CUDA_CACHE_MAXSIZE = "4294967296"; # 4 GB CUDA kernel cache
  };

  boot.kernelParams = [
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
    "nvidia.NVreg_UsePageAttributeTable=1" # enable PAT — improves memory access patterns
    "nvidia-drm.fbdev=1" # framebuffer device for console — better VT switching
    "nvidia.NVreg_InitializeSystemMemoryAllocations=0" # skip zeroing allocations — faster alloc
    # "nvidia.NVreg_EnableResizableBar=1" # uncomment after enabling ReBAR/Above 4G in BIOS
  ];

  environment.systemPackages = with pkgs; [
    gwe
    nvtopPackages.nvidia
    vulkan-tools
    vulkan-loader
  ];

}
