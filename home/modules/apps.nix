{
  config,
  lib,
  pkgs,
  ...
}:

let
  firefoxWrapped = (
    pkgs.wrapFirefox (pkgs.firefox-unwrapped.override {
      pipewireSupport = true;
    }) { }
  );
in
{
  # User applications
  home.packages = with pkgs; [
    thunderbird
    protonmail-bridge
    discord
    firefoxWrapped
    spotify
    vlc
    mupdf
    qbittorrent-enhanced
    pomodoro-gtk
    proton-vpn
    bitwarden-cli
    bitwarden-menu
    element-desktop
    zoom-us
    thunar
    thunar-volman
    thunar-archive-plugin
    thunar-media-tags-plugin
    xfconf
    tumbler
    gimp
    libreoffice-fresh
    teamviewer
    clockify
    remmina
    slack
    vscode
    code-cursor
    opencode
    google-cloud-sdk
    gemini-cli
    chromium
    poppler-utils
  ];

  # Session variables
  home.sessionVariables = {
    DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
  };

  # Default applications for MIME types
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Web
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];

      # File manager
      "inode/directory" = [ "thunar.desktop" ];

      # Images
      "image/png" = [ "gimp.desktop" ];
      "image/jpeg" = [ "gimp.desktop" ];
      "image/gif" = [ "gimp.desktop" ];
      "image/webp" = [ "gimp.desktop" ];
      "image/svg+xml" = [ "gimp.desktop" ];
      "image/bmp" = [ "gimp.desktop" ];
      "image/tiff" = [ "gimp.desktop" ];

      # Video
      "video/mp4" = [ "vlc.desktop" ];
      "video/x-matroska" = [ "vlc.desktop" ];
      "video/webm" = [ "vlc.desktop" ];
      "video/x-msvideo" = [ "vlc.desktop" ];
      "video/quicktime" = [ "vlc.desktop" ];
      "video/x-flv" = [ "vlc.desktop" ];

      # Audio
      "audio/mpeg" = [ "vlc.desktop" ];
      "audio/flac" = [ "vlc.desktop" ];
      "audio/ogg" = [ "vlc.desktop" ];
      "audio/x-wav" = [ "vlc.desktop" ];
      "audio/aac" = [ "vlc.desktop" ];
      "audio/opus" = [ "vlc.desktop" ];
      "audio/webm" = [ "vlc.desktop" ];

      # PDF
      "application/pdf" = [ "mupdf.desktop" ];

      # Text
      "text/plain" = [ "dev.zed.Zed.desktop" ];
      "application/json" = [ "dev.zed.Zed.desktop" ];
      "application/xml" = [ "dev.zed.Zed.desktop" ];
      "text/x-python" = [ "dev.zed.Zed.desktop" ];
      "text/x-shellscript" = [ "dev.zed.Zed.desktop" ];
      "text/x-csrc" = [ "dev.zed.Zed.desktop" ];
      "text/x-c++src" = [ "dev.zed.Zed.desktop" ];
      "text/x-rust" = [ "dev.zed.Zed.desktop" ];
      "text/markdown" = [ "dev.zed.Zed.desktop" ];
    };
  };

}
