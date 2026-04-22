# Add GPU Support

## When to use

When adding driver configuration for a new GPU type or modifying existing GPU settings.

## Files to modify

1. **Create or modify** `modules/<vendor>/gpu.nix` or `modules/amd/graphics.nix`
2. **Modify** `modules/devices/<device>.nix` — import the GPU module

## Steps

### 1. Follow the existing GPU module pattern

**AMD (modules/amd/graphics.nix):**

```nix
{
  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.amdgpu.enable = lib.mkDefault true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ mesa libvdpau-va-gl libva-vdpau-driver ];
  };
  environment.variables.LIBVA_DRIVER_NAME = "radeonsi";
}
```

**NVIDIA (modules/nvidia/gpu.nix):**

```nix
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    nvidiaPersistenced = true;
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver libva-vdpau-driver ];
  };
}
```

### 2. Import from device module

```nix
imports = [
  ../amd/graphics.nix    # or ../nvidia/gpu.nix
];
```

### 3. Set environment variables for VA-API

AMD: `LIBVA_DRIVER_NAME = "radeonsi"`
NVIDIA: `LIBVA_DRIVER_NAME = "nvidia"`, plus GBM/GLX variables

## Verification

```bash
nixos-rebuild build --flake .#<host>
```

After deploying:
```bash
vainfo           # verify VA-API
vulkaninfo       # verify Vulkan
```

## Gotchas

- NVIDIA + Sway requires `programs.sway.extraOptions = [ "--unsupported-gpu" ]` in the device module
- NVIDIA environment variables (`WLR_NO_HARDWARE_CURSORS`, `GBM_BACKEND`, etc.) are critical for Wayland
- GPU modules are orthogonal to CPU modules — a device imports both independently
- The NVIDIA package tracks `nvidiaPackages.beta` — check compatibility with the CachyOS kernel version
