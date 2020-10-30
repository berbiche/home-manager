{ config, lib, pkgs, ... }:

with lib;

let cfg = config.wayland.windowManager.sway;
in {
  config = {
    wayland.windowManager.sway = {
      enable = true;
      package = pkgs.writeScriptBin "sway" "" // { outPath = "@sway"; };
      config = {
        focus.followMouse = "always";
        menu = "${pkgs.dmenu}/bin/dmenu_run";
        bars = [ ];
      };
    };

    nixpkgs.overlays = [
      (self: super: {
        dmenu = super.dmenu // { outPath = "@dmenu@"; };
        rxvt-unicode-unwrapped = super.rxvt-unicode-unwrapped // {
          outPath = "@rxvt-unicode-unwrapped@";
        };
        swaybg = pkgs.writeScriptBin "dummy-swaybg" "";
        xwayland = pkgs.writeScriptBin "xwayland" "";
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/sway/config
      assertFileContent home-files/.config/sway/config \
        ${./sway-followmouse-expected.conf}
    '';
  };
}
