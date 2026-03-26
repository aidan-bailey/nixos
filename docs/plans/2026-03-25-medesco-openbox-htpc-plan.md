# Medesco Openbox HTPC Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an Openbox X11 graphical session to medesco, the TV-connected HTPC media server.

**Architecture:** New `htpcModules` profile extends `serverModules` with Openbox, audio, gaming, and nix-ld. System module handles X11/Openbox/fonts/plumbing. Home-manager host file handles Openbox config, autostart, theming, and user packages.

**Tech Stack:** NixOS, Openbox, X11, picom, tint2, rofi, PipeWire, home-manager

---

### Task 1: Create `modules/openbox.nix`

**Files:**
- Create: `modules/openbox.nix`

**Step 1: Write the system module**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # X11 server with Openbox
  services.xserver = {
    enable = true;
    windowManager.openbox.enable = true;
    xkb = {
      layout = "za";
      variant = "";
      options = "caps:swapescape";
    };
  };
  console.useXkbConfig = true;

  # No graphical login — startx from tty1 (mirrors Sway loginShellInit in sway.nix)
  services.displayManager.startx.enable = true;
  environment.loginShellInit = ''
    [[ "$(tty)" == /dev/tty1 ]] && startx
  '';

  # Desktop plumbing
  security.polkit.enable = true;
  services.dbus.enable = true;
  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.noto
    noto-fonts
    noto-fonts-color-emoji
  ];

  # Font rendering — adapts to display panel technology
  fonts.fontconfig = {
    antialias = true;
    hinting = {
      enable = true;
      style = "slight";
    };
    subpixel =
      if config.custom.display.type == "lcd" then
        {
          rgba = "rgb";
          lcdfilter = "default";
        }
      else
        {
          rgba = "none";
          lcdfilter = "none";
        };
  };

  environment.systemPackages = with pkgs; [
    libsecret
  ];
}
```

**Step 2: Verify syntax**

Run: `nix-instantiate --parse modules/openbox.nix`
Expected: Parses without error (outputs the AST)

---

### Task 2: Update `flake.nix`

**Files:**
- Modify: `flake.nix:78-101` (profile definitions) and `flake.nix:123-126` (medesco host)

**Step 1: Add htpcModules profile**

After the `desktopModules` block (line 101), add:

```nix
      htpcModules = serverModules ++ [
        ./modules/openbox.nix
        ./modules/audio.nix
        ./modules/gaming.nix
        ./modules/nix-ld.nix
      ];
```

**Step 2: Update the profile comment**

Change line 79:
```nix
      # serverModules: minimal headless base (medesco)
```
to:
```nix
      # serverModules: minimal headless base
      # htpcModules: HTPC with Openbox, audio, gaming (medesco)
```

**Step 3: Switch medesco to htpcModules**

Change:
```nix
        medesco = mkHost {
          hostConfig = ./hosts/medesco/configuration.nix;
          profile = serverModules;
        };
```
to:
```nix
        medesco = mkHost {
          hostConfig = ./hosts/medesco/configuration.nix;
          profile = htpcModules;
        };
```

---

### Task 3: Update `hosts/medesco/configuration.nix`

**Files:**
- Modify: `hosts/medesco/configuration.nix`

**Step 1: Replace the full file**

```nix
{
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  custom.hostType = "server";
  custom.display.type = "lcd";

  networking.hostName = "medesco";

  home-manager.users.aidanb.imports = [
    ../../home/hosts/medesco.nix
  ];
}
```

---

### Task 4: Create Openbox config files

**Files:**
- Create: `config/openbox/rc.xml`
- Create: `config/openbox/menu.xml`
- Create: `config/openbox/autostart`

**Step 1: Create `config/openbox/rc.xml`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc"
                xmlns:xi="http://www.w3.org/2001/XInclude">

  <resistance>
    <strength>10</strength>
    <screen_edge_strength>20</screen_edge_strength>
  </resistance>

  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
    <focusLast>yes</focusLast>
    <underMouse>no</underMouse>
    <focusDelay>200</focusDelay>
    <raiseOnFocus>no</raiseOnFocus>
  </focus>

  <placement>
    <policy>Smart</policy>
    <center>yes</center>
    <monitor>Primary</monitor>
  </placement>

  <theme>
    <name>Clearlooks</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>yes</keepBorder>
    <animateIconify>yes</animateIconify>
    <font place="ActiveWindow">
      <name>NotoSans Nerd Font</name>
      <size>11</size>
      <weight>Bold</weight>
      <slant>Normal</slant>
    </font>
    <font place="InactiveWindow">
      <name>NotoSans Nerd Font</name>
      <size>11</size>
      <weight>Bold</weight>
      <slant>Normal</slant>
    </font>
    <font place="MenuHeader">
      <name>NotoSans Nerd Font</name>
      <size>11</size>
      <weight>Normal</weight>
      <slant>Normal</slant>
    </font>
    <font place="MenuItem">
      <name>NotoSans Nerd Font</name>
      <size>11</size>
      <weight>Normal</weight>
      <slant>Normal</slant>
    </font>
    <font place="ActiveOnScreenDisplay">
      <name>NotoSans Nerd Font</name>
      <size>11</size>
      <weight>Bold</weight>
      <slant>Normal</slant>
    </font>
    <font place="InactiveOnScreenDisplay">
      <name>NotoSans Nerd Font</name>
      <size>11</size>
      <weight>Bold</weight>
      <slant>Normal</slant>
    </font>
  </theme>

  <desktops>
    <number>4</number>
    <firstdesk>1</firstdesk>
    <names>
      <name>1</name>
      <name>2</name>
      <name>3</name>
      <name>4</name>
    </names>
    <popupTime>875</popupTime>
  </desktops>

  <resize>
    <drawContents>yes</drawContents>
    <popupShow>Nonpixel</popupShow>
    <popupPosition>Center</popupPosition>
  </resize>

  <keyboard>
    <chainQuitKey>C-g</chainQuitKey>

    <!-- Application launchers -->
    <keybind key="W-Return">
      <action name="Execute"><command>alacritty</command></action>
    </keybind>
    <keybind key="W-d">
      <action name="Execute"><command>rofi -show drun</command></action>
    </keybind>
    <keybind key="W-j">
      <action name="Execute"><command>jellyfinmediaplayer</command></action>
    </keybind>
    <keybind key="W-b">
      <action name="Execute"><command>firefox</command></action>
    </keybind>

    <!-- Window management -->
    <keybind key="W-q">
      <action name="Close"/>
    </keybind>
    <keybind key="W-f">
      <action name="ToggleFullscreen"/>
    </keybind>
    <keybind key="W-m">
      <action name="ToggleMaximize"/>
    </keybind>
    <keybind key="W-n">
      <action name="Iconify"/>
    </keybind>

    <!-- Alt-Tab window cycling -->
    <keybind key="A-Tab">
      <action name="NextWindow">
        <finalactions>
          <action name="Focus"/>
          <action name="Raise"/>
          <action name="Unshade"/>
        </finalactions>
      </action>
    </keybind>
    <keybind key="A-S-Tab">
      <action name="PreviousWindow">
        <finalactions>
          <action name="Focus"/>
          <action name="Raise"/>
          <action name="Unshade"/>
        </finalactions>
      </action>
    </keybind>

    <!-- Desktop switching -->
    <keybind key="W-1">
      <action name="GoToDesktop"><to>1</to></action>
    </keybind>
    <keybind key="W-2">
      <action name="GoToDesktop"><to>2</to></action>
    </keybind>
    <keybind key="W-3">
      <action name="GoToDesktop"><to>3</to></action>
    </keybind>
    <keybind key="W-4">
      <action name="GoToDesktop"><to>4</to></action>
    </keybind>

    <!-- Move window to desktop -->
    <keybind key="W-S-1">
      <action name="SendToDesktop"><to>1</to><follow>no</follow></action>
    </keybind>
    <keybind key="W-S-2">
      <action name="SendToDesktop"><to>2</to><follow>no</follow></action>
    </keybind>
    <keybind key="W-S-3">
      <action name="SendToDesktop"><to>3</to><follow>no</follow></action>
    </keybind>
    <keybind key="W-S-4">
      <action name="SendToDesktop"><to>4</to><follow>no</follow></action>
    </keybind>
  </keyboard>

  <mouse>
    <dragThreshold>1</dragThreshold>
    <doubleClickTime>500</doubleClickTime>
    <screenEdgeWarpTime>400</screenEdgeWarpTime>
    <screenEdgeWarpMouse>false</screenEdgeWarpMouse>

    <context name="Frame">
      <mousebind button="A-Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
      <mousebind button="A-Left" action="Drag">
        <action name="Move"/>
      </mousebind>
      <mousebind button="A-Right" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
      <mousebind button="A-Right" action="Drag">
        <action name="Resize"/>
      </mousebind>
    </context>

    <context name="Titlebar Top Right Bottom Left TLCorner TRCorner BRCorner BLCorner">
      <mousebind button="Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
        <action name="Unshade"/>
      </mousebind>
    </context>

    <context name="Titlebar">
      <mousebind button="Left" action="Drag">
        <action name="Move"/>
      </mousebind>
      <mousebind button="Left" action="DoubleClick">
        <action name="ToggleMaximize"/>
      </mousebind>
    </context>

    <context name="Top Bottom Left Right TLCorner TRCorner BRCorner BLCorner">
      <mousebind button="Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
      <mousebind button="Left" action="Drag">
        <action name="Resize"/>
      </mousebind>
    </context>

    <context name="Client">
      <mousebind button="Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
      <mousebind button="Middle" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
      <mousebind button="Right" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
    </context>

    <context name="Desktop">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu"><menu>root-menu</menu></action>
      </mousebind>
    </context>

    <context name="Root">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu"><menu>root-menu</menu></action>
      </mousebind>
    </context>

    <context name="Close">
      <mousebind button="Left" action="Click">
        <action name="Close"/>
      </mousebind>
    </context>

    <context name="Maximize">
      <mousebind button="Left" action="Click">
        <action name="ToggleMaximize"/>
      </mousebind>
    </context>

    <context name="Iconify">
      <mousebind button="Left" action="Click">
        <action name="Iconify"/>
      </mousebind>
    </context>
  </mouse>

  <applications>
    <!-- Jellyfin Media Player starts fullscreen on desktop 1 -->
    <application class="jellyfinmediaplayer">
      <fullscreen>yes</fullscreen>
      <desktop>1</desktop>
    </application>
  </applications>

</openbox_config>
```

**Step 2: Create `config/openbox/menu.xml`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://openbox.org/3.4/menu">

  <menu id="root-menu" label="medesco">
    <item label="Jellyfin Media Player">
      <action name="Execute"><command>jellyfinmediaplayer</command></action>
    </item>
    <item label="Firefox">
      <action name="Execute"><command>firefox</command></action>
    </item>
    <item label="Terminal">
      <action name="Execute"><command>alacritty</command></action>
    </item>
    <item label="Transmission">
      <action name="Execute"><command>transmission-qt</command></action>
    </item>
    <item label="File Manager">
      <action name="Execute"><command>thunar</command></action>
    </item>
    <item label="Steam">
      <action name="Execute"><command>steam</command></action>
    </item>
    <separator/>
    <item label="Reconfigure">
      <action name="Reconfigure"/>
    </item>
    <item label="Exit">
      <action name="Exit"/>
    </item>
  </menu>

</openbox_menu>
```

**Step 3: Create `config/openbox/autostart`**

```bash
#!/bin/sh

# Compositor for tear-free video playback on TV
picom --backend glx &

# Wallpaper
feh --bg-fill ~/.config/openbox/wallpaper.jpg 2>/dev/null &

# Lightweight panel
tint2 &

# Primary kiosk app
jellyfinmediaplayer --fullscreen &
```

---

### Task 5: Create `home/hosts/medesco.nix`

**Files:**
- Create: `home/hosts/medesco.nix`

**Step 1: Write the home-manager host file**

```nix
{ config, pkgs, ... }:

{
  imports = [
    ../modules/apps.nix
    ../modules/gaming.nix
  ];

  # .xinitrc — startx launches openbox-session
  home.file.".xinitrc".text = ''
    exec openbox-session
  '';

  # Openbox configuration
  xdg.configFile."openbox/rc.xml".source = ../../config/openbox/rc.xml;
  xdg.configFile."openbox/menu.xml".source = ../../config/openbox/menu.xml;
  xdg.configFile."openbox/autostart" = {
    source = ../../config/openbox/autostart;
    executable = true;
  };

  # Reuse the shared wallpaper
  xdg.configFile."openbox/wallpaper.jpg".source = ../../config/sway/wallpaper.jpg;

  # HTPC packages
  home.packages = with pkgs; [
    tint2
    feh
    rofi
    xclip
    xdotool
    picom
    gruvbox-dark-gtk
    gruvbox-dark-icons-gtk
  ];

  # Gruvbox theming (consistent with nesco/fresco)
  home.pointerCursor = {
    name = "Capitaine Cursors (Gruvbox)";
    package = pkgs.capitaine-cursors-themed;
    size = 36;
    gtk.enable = true;
    x11.enable = true;
  };

  home.sessionVariables = {
    GTK_THEME = "Gruvbox-Dark";
  };
}
```

---

### Task 6: Build verification

**Step 1: Format all nix files**

Run: `nixfmt .`
Expected: Formats without errors

**Step 2: Build the medesco configuration**

Run: `nixos-rebuild build --flake .#medesco 2>&1`
Expected: Build completes successfully. Note: hardware-configuration.nix is a placeholder, so some hardware-specific options may warn — this is expected until medesco is deployed on real hardware.

**Step 3: Verify other hosts are unaffected**

Run: `nixos-rebuild build --flake .#nesco 2>&1`
Expected: Build succeeds (htpcModules addition doesn't affect nesco)

Run: `nixos-rebuild build --flake .#fresco 2>&1`
Expected: Build succeeds (htpcModules addition doesn't affect fresco)

---

### Task 7: Commit

**Step 1: Stage and commit**

```bash
git add modules/openbox.nix config/openbox/ home/hosts/medesco.nix
git add flake.nix hosts/medesco/configuration.nix
git commit -m "feat(medesco): add Openbox HTPC graphical session

Add htpcModules profile (serverModules + openbox, audio, gaming, nix-ld)
and switch medesco to use it. Includes X11 with startx auto-login,
Openbox config with HTPC keybindings, picom compositor, tint2 panel,
and Jellyfin Media Player fullscreen autostart."
```

---

## Out of scope (separate tasks)

- Regenerate `hosts/medesco/hardware-configuration.nix` on target hardware
- Add medesco age key to `.sops.yaml` for secrets decryption
- Create `modules/devices/medesco.nix` for hardware-specific tuning
- tint2 configuration file (uses tint2 defaults initially — can be customized later)
