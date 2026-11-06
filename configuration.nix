{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    (import (builtins.fetchTarball "https://github.com/ezKEa/aagl-gtk-on-nix/archive/main.tar.gz")).module
  ];

  # --- Nix & Binary Cache Settings ---
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [ "https://ezkea.cachix.org" ];
    trusted-public-keys = [ "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI=" ];
  };
  nixpkgs.config.allowUnfree = true;

  # --- Boot & Kernel ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # --- Networking & Locale ---
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # --- Display, Desktop & Window Managers ---
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # --- Audio & Printing ---
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # --- Portals, Default Apps & Environment Variables ---
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [ "hyprland" "gtk" ];
  };

  services.udev.extraRules = ''
    # Allow Plover to output keystrokes via uinput (essential for Wayland)
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
    
    # Allow access to HID-based steno keyboards (Plover HID protocol)
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="dialout"
  '';

  xdg.mime = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "app.zen_browser.zen.desktop" "zen.desktop" ];
      "x-scheme-handler/http" = [ "app.zen_browser.zen.desktop" "zen.desktop" ];
      "x-scheme-handler/https" = [ "app.zen_browser.zen.desktop" "zen.desktop" ];
      "x-scheme-handler/about" = [ "app.zen_browser.zen.desktop" "zen.desktop" ];
      "x-scheme-handler/unknown" = [ "app.zen_browser.zen.desktop" "zen.desktop" ];
      "inode/directory" = [ "thunar.desktop" ];
      "x-scheme-handler/terminal" = [ "kitty.desktop" ];
    };
  };

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "kitty";
  };

  # --- File Manager (Thunar) & Storage Services ---
  programs.thunar.enable = true;
  services.gvfs.enable = true;    # Mount, trash, and network support for Thunar
  services.tumbler.enable = true; # Image/video thumbnails for Thunar

  # --- Gaming, Flatpak, AppImage & Binary Compatibility ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # --- Bluetooth ---
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true; # Shows battery percentage for connected devices
        FastConnectable = true;
      };
    };
  };
  services.blueman.enable = true; # Provides blueman-manager GUI

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.anime-game-launcher.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      gtk4
      gtk4-layer-shell
      wayland
      libGL
      glib
    ];
  };

  services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
  };

  # --- Programs & Shell ---
  programs.fish.enable = true;
  programs.firefox.enable = true;
  programs.obs-studio.enable = true;

  # --- User Account ---
  users.users."gregory" = {
    isNormalUser = true;
    description = "gregory";
    extraGroups = [ 
      "networkmanager" 
      "wheel"
      "dialout"
      "input"
      "uinput"
    ];
    shell = pkgs.fish;
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # --- System Packages ---
  environment.systemPackages = with pkgs; [
    # Hyprland & Wayland Utilities
    hyprlock
    hyprshot
    hyprsunset
    wayle
    walker
    elephant
    wofi
    awww
    pywal
    bibata-cursors

    # Terminals, Editors & CLI Tools
    kitty
    neovim
    vim
    git
    wget
    starship
    fastfetch
    htop
    cava
    pipes
    yt-dlp
    ripgrep

    # Media, Graphics & Desktop Apps
    (mpv.override { scripts = [ mpvScripts.mpris ]; })
    playerctl
    ffmpeg
    kdePackages.kdenlive
    vesktop
    bitwarden-desktop
    gearlever
    nautilus
    gtk3
    blender
    virtualbox
    ((import (
      fetchTarball "https://github.com/edolstra/flake-compat/archive/master.tar.gz"
    ) {
      src = fetchTarball "https://github.com/openstenoproject/plover-flake/archive/master.tar.gz";
    }).defaultNix.packages.${pkgs.system}.plover.withPlugins (ps: with ps; [
      plover-lapwing-aio
      plover-dict-commands
    ]))

    # Gaming & Development
    prismlauncher
    wine
    python314
    jdk25
    gcc
  ];

  # --- Activation Scripts ---
  system.activationScripts.refreshUserEnv = {
    deps = [ "etc" ];
    text = ''
      if [ -S /run/user/1000/bus ]; then
        ${pkgs.sudo}/bin/sudo -u gregory \
          XDG_RUNTIME_DIR=/run/user/1000 \
          DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
          ${pkgs.bash}/bin/bash -c '
            source /etc/set-environment
            ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd PATH XDG_DATA_DIRS TERMINAL EDITOR VISUAL
            ${pkgs.systemd}/bin/systemctl --user import-environment PATH XDG_DATA_DIRS TERMINAL EDITOR VISUAL
            rm -rf /home/gregory/.cache/wofi* /home/gregory/.cache/walker /home/gregory/.cache/elephant
          '
      fi
    '';
  };

  system.stateVersion = "26.05";
}
