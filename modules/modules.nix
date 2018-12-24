{ pkgs
, lib

  # Whether to enable module type checking.
, check ? true

  # Whether these modules are inside a NixOS submodule.
, nixosSubmodule ? false
}:

with lib;

let

  hostPlatform = pkgs.stdenv.hostPlatform;

  checkPlatform = any (meta.platformMatch pkgs.stdenv.hostPlatform);

  loadModule = file: { condition ? true }: {
    inherit file condition;
  };

  allModules = [
    (loadModule ./accounts/email.nix { })
    (loadModule ./files.nix { })
    (loadModule ./home-environment.nix { })
    (loadModule ./manual.nix { })
    (loadModule ./misc/dconf.nix { })
    (loadModule ./misc/fontconfig.nix { })
    (loadModule ./misc/gtk.nix { })
    (loadModule ./misc/lib.nix { })
    (loadModule ./misc/news.nix { })
    (loadModule ./misc/nixpkgs.nix { })
    (loadModule ./misc/pam.nix { })
    (loadModule ./misc/qt.nix { })
    (loadModule ./misc/version.nix { })
    (loadModule ./misc/xdg.nix { })
    (loadModule ./programs/afew.nix { })
    (loadModule ./programs/alot.nix { })
    (loadModule ./programs/astroid.nix { })
    (loadModule ./programs/autorandr.nix { })
    (loadModule ./programs/bash.nix { })
    (loadModule ./programs/beets.nix { })
    (loadModule ./programs/browserpass.nix { })
    (loadModule ./programs/chromium.nix { condition = hostPlatform.isLinux; })
    (loadModule ./programs/command-not-found/command-not-found.nix { })
    (loadModule ./programs/direnv.nix { })
    (loadModule ./programs/eclipse.nix { })
    (loadModule ./programs/emacs.nix { })
    (loadModule ./programs/feh.nix { })
    (loadModule ./programs/firefox.nix { })
    (loadModule ./programs/fish.nix { })
    (loadModule ./programs/fzf.nix { })
    (loadModule ./programs/git.nix { })
    (loadModule ./programs/gnome-terminal.nix { })
    (loadModule ./programs/go.nix { })
    (loadModule ./programs/home-manager.nix { })
    (loadModule ./programs/htop.nix { })
    (loadModule ./programs/info.nix { })
    (loadModule ./programs/jq.nix { })
    (loadModule ./programs/lesspipe.nix { })
    (loadModule ./programs/man.nix { })
    (loadModule ./programs/mbsync.nix { })
    (loadModule ./programs/mercurial.nix { })
    (loadModule ./programs/msmtp.nix { })
    (loadModule ./programs/neovim.nix { })
    (loadModule ./programs/newsboat.nix { })
    (loadModule ./programs/noti.nix { })
    (loadModule ./programs/notmuch.nix { })
    (loadModule ./programs/obs-studio.nix { })
    (loadModule ./programs/offlineimap.nix { })
    (loadModule ./programs/pidgin.nix { })
    (loadModule ./programs/rofi.nix { })
    (loadModule ./programs/ssh.nix { })
    (loadModule ./programs/taskwarrior.nix { })
    (loadModule ./programs/termite.nix { })
    (loadModule ./programs/texlive.nix { })
    (loadModule ./programs/tmux.nix { })
    (loadModule ./programs/urxvt.nix { })
    (loadModule ./programs/vim.nix { })
    (loadModule ./programs/vscode.nix { })
    (loadModule ./programs/zathura.nix { })
    (loadModule ./programs/zsh.nix { })
    (loadModule ./services/blueman-applet.nix { })
    (loadModule ./services/compton.nix { })
    (loadModule ./services/dunst.nix { })
    (loadModule ./services/flameshot.nix { })
    (loadModule ./services/gnome-keyring.nix { })
    (loadModule ./services/gpg-agent.nix { })
    (loadModule ./services/kbfs.nix { })
    (loadModule ./services/kdeconnect.nix { })
    (loadModule ./services/keepassx.nix { })
    (loadModule ./services/keybase.nix { })
    (loadModule ./services/mbsync.nix { })
    (loadModule ./services/mpd.nix { })
    (loadModule ./services/network-manager-applet.nix { })
    (loadModule ./services/nextcloud-client.nix { })
    (loadModule ./services/owncloud-client.nix { })
    (loadModule ./services/parcellite.nix { })
    (loadModule ./services/pasystray.nix { })
    (loadModule ./services/polybar.nix { })
    (loadModule ./services/random-background.nix { })
    (loadModule ./services/redshift.nix { })
    (loadModule ./services/screen-locker.nix { })
    (loadModule ./services/stalonetray.nix { })
    (loadModule ./services/status-notifier-watcher.nix { })
    (loadModule ./services/syncthing.nix { })
    (loadModule ./services/taffybar.nix { })
    (loadModule ./services/tahoe-lafs.nix { })
    (loadModule ./services/udiskie.nix { })
    (loadModule ./services/unclutter.nix { })
    (loadModule ./services/window-managers/awesome.nix { })
    (loadModule ./services/window-managers/i3.nix { })
    (loadModule ./services/window-managers/xmonad.nix { })
    (loadModule ./services/xscreensaver.nix { })
    (loadModule ./systemd.nix { })
    (loadModule ./xcursor.nix { })
    (loadModule ./xresources.nix { })
    (loadModule ./xsession.nix { })
    (loadModule <nixpkgs/nixos/modules/misc/assertions.nix> { })
    (loadModule <nixpkgs/nixos/modules/misc/meta.nix> { })
  ];

  modules = map (getAttr "file") (filter (getAttr "condition") allModules);

  pkgsModule = {
    options.nixosSubmodule = mkOption {
      type = types.bool;
      internal = true;
      readOnly = true;
    };

    config._module.args.baseModules = modules;
    config._module.args.pkgs = lib.mkDefault pkgs;
    config._module.check = check;
    config.lib = import ./lib { inherit lib; };
    config.nixosSubmodule = nixosSubmodule;
    config.nixpkgs.system = mkDefault pkgs.system;
  };

in

  modules ++ [ pkgsModule ]
