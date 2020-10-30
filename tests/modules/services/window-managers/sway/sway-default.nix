{ config, lib, pkgs, ... }:

with lib;

let cfg = config.wayland.windowManager.sway;
in {
  config = {
    wayland.windowManager.sway = {
      enable = true;
      package = pkgs.writeScriptBin "sway" "" // { outPath = "@sway"; };
      # overriding findutils causes issues
      config.menu = "${pkgs.dmenu}/bin/dmenu_run";

      config.keybindings = lib.mkOptionDefault {
        # bindsym --release --input-device=t Mod1+space
        "${cfg.config.modifier}+space" = {
          flags = [ "--release" "--input-device=t" ];
          # value = "focus mode_toggle";
        };
        "dummy-2".value = "exec echo";
        # These commands will result in an empty line
        "${cfg.config.modifier}+v".flags = [ "--release" ];
        "dummy" = null;
        "dummy-1".value = null;
      };
    };

    nixpkgs.overlays = [
      (self: super: {
        dummy-package = super.runCommandLocal "dummy-package" { } "mkdir $out";
        dmenu = self.dummy-package // { outPath = "@dmenu@"; };
        rxvt-unicode-unwrapped = self.dummy-package // {
          outPath = "@rxvt-unicode-unwrapped@";
        };
        i3status = self.dummy-package // { outPath = "@i3status@"; };
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/sway/config
      assertFileContent home-files/.config/sway/config \
        ${./sway-default.conf}
    '';
  };
}
