{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession.windowManager.i3;

  commonOptions = import ./lib/options.nix {
    inherit config lib cfg pkgs;
    moduleName = "i3";
    isGaps = cfg.package == pkgs.i3-gaps;
  };

  configModule = types.submodule {
    options = {
      inherit (commonOptions)
        fonts window floating focus assigns modifier workspaceLayout
        workspaceAutoBackAndForth keycodebindings colors bars startup gaps menu
        terminal;

      keybindings = mkOption {
        type = types.attrsOf (types.nullOr
          # (commonOptions.coercedToKeybind commonOptions.keybindType));
          (commonOptions.bindingType types.str commonOptions.keybindType));
        default = commonFunctions.mkDefaultKeybind {
          "${cfg.config.modifier}+Return".value = "exec ${cfg.config.terminal}";
          "${cfg.config.modifier}+Shift+q".value = "kill";
          "${cfg.config.modifier}+d".value = "exec ${cfg.config.menu}";

          "${cfg.config.modifier}+Left".value = "focus left";
          "${cfg.config.modifier}+Down".value = "focus down";
          "${cfg.config.modifier}+Up".value = "focus up";
          "${cfg.config.modifier}+Right".value = "focus right";

          "${cfg.config.modifier}+Shift+Left".value = "move left";
          "${cfg.config.modifier}+Shift+Down".value = "move down";
          "${cfg.config.modifier}+Shift+Up".value = "move up";
          "${cfg.config.modifier}+Shift+Right".value = "move right";

          "${cfg.config.modifier}+h".value = "split h";
          "${cfg.config.modifier}+v".value = "split v";
          "${cfg.config.modifier}+f".value = "fullscreen toggle";

          "${cfg.config.modifier}+s".value = "layout stacking";
          "${cfg.config.modifier}+w".value = "layout tabbed";
          "${cfg.config.modifier}+e".value = "layout toggle split";

          "${cfg.config.modifier}+Shift+space".value = "floating toggle";
          "${cfg.config.modifier}+space".value = "focus mode_toggle";

          "${cfg.config.modifier}+a".value = "focus parent";

          "${cfg.config.modifier}+Shift+minus".value = "move scratchpad";
          "${cfg.config.modifier}+minus".value = "scratchpad show";

          "${cfg.config.modifier}+1".value = "workspace number 1";
          "${cfg.config.modifier}+2".value = "workspace number 2";
          "${cfg.config.modifier}+3".value = "workspace number 3";
          "${cfg.config.modifier}+4".value = "workspace number 4";
          "${cfg.config.modifier}+5".value = "workspace number 5";
          "${cfg.config.modifier}+6".value = "workspace number 6";
          "${cfg.config.modifier}+7".value = "workspace number 7";
          "${cfg.config.modifier}+8".value = "workspace number 8";
          "${cfg.config.modifier}+9".value = "workspace number 9";
          "${cfg.config.modifier}+0".value = "workspace number 10";

          "${cfg.config.modifier}+Shift+1".value =
            "move container to workspace number 1";
          "${cfg.config.modifier}+Shift+2".value =
            "move container to workspace number 2";
          "${cfg.config.modifier}+Shift+3".value =
            "move container to workspace number 3";
          "${cfg.config.modifier}+Shift+4".value =
            "move container to workspace number 4";
          "${cfg.config.modifier}+Shift+5".value =
            "move container to workspace number 5";
          "${cfg.config.modifier}+Shift+6".value =
            "move container to workspace number 6";
          "${cfg.config.modifier}+Shift+7".value =
            "move container to workspace number 7";
          "${cfg.config.modifier}+Shift+8".value =
            "move container to workspace number 8";
          "${cfg.config.modifier}+Shift+9".value =
            "move container to workspace number 9";
          "${cfg.config.modifier}+Shift+0".value =
            "move container to workspace number 10";

          "${cfg.config.modifier}+Shift+c".value = "reload";
          "${cfg.config.modifier}+Shift+r".value = "restart";
          "${cfg.config.modifier}+Shift+e".value =
            "exec i3-nagbar -t warning -m 'Do you want to exit i3?' -b 'Yes' 'i3-msg exit'";

          "${cfg.config.modifier}+r".value = "mode resize";
        };
        defaultText = "Default i3 keybindings.";
        description = ''
          An attribute set that assigns a key press to an action using a key symbol.
          See <link xlink:href="https://i3wm.org/docs/userguide.html#keybindings"/>.
          </para><para>
          Consider to use <code>lib.mkOptionDefault</code> function to extend or override
          default keybindings instead of specifying all of them from scratch.
        '';
        example = literalExample ''
          let
            modifier = config.xsession.windowManager.i3.config.modifier;
          in lib.mkOptionDefault {
            "''${modifier}+Return" = "exec i3-sensible-terminal";
            "''${modifier}+Shift+q" = "kill";
            "''${modifier}+d" = "exec \${pkgs.dmenu}/bin/dmenu_run";
          }
        '';
      };

      modes = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = {
          resize = {
            "Left" = "resize shrink width 10 px or 10 ppt";
            "Down" = "resize grow height 10 px or 10 ppt";
            "Up" = "resize shrink height 10 px or 10 ppt";
            "Right" = "resize grow width 10 px or 10 ppt";
            "Escape" = "mode default";
            "Return" = "mode default";
          };
        };
        description = ''
          An attribute set that defines binding modes and keybindings
          inside them

          Only basic keybinding is supported (bindsym keycomb action),
          for more advanced setup use 'i3.extraConfig'.
        '';
      };
    };
  };

  commonFunctions = import ./lib/functions.nix {
    inherit cfg lib;
    moduleName = "i3";
  };

  inherit (commonFunctions)
    keybindingsStr keycodebindingsStr modeStr assignStr barStr gapsStr
    floatingCriteriaStr windowCommandsStr colorSetStr;

  startupEntryStr = { command, always, notification, workspace, ... }: ''
    ${if always then "exec_always" else "exec"} ${
      if (notification && workspace == null) then "" else "--no-startup-id"
    } ${
      if (workspace == null) then
        command
      else
        "i3-msg 'workspace ${workspace}; exec ${command}'"
    }
  '';

  configFile = pkgs.writeText "i3.conf" ((if cfg.config != null then
    with cfg.config; ''
      font pango:${concatStringsSep ", " fonts}
      floating_modifier ${floating.modifier}
      new_window ${if window.titlebar then "normal" else "pixel"} ${
        toString window.border
      }
      new_float ${if floating.titlebar then "normal" else "pixel"} ${
        toString floating.border
      }
      hide_edge_borders ${window.hideEdgeBorders}
      force_focus_wrapping ${if focus.forceWrapping then "yes" else "no"}
      focus_follows_mouse ${if focus.followMouse then "yes" else "no"}
      focus_on_window_activation ${focus.newWindow}
      mouse_warping ${if focus.mouseWarping then "output" else "none"}
      workspace_layout ${workspaceLayout}
      workspace_auto_back_and_forth ${
        if workspaceAutoBackAndForth then "yes" else "no"
      }

      client.focused ${colorSetStr colors.focused}
      client.focused_inactive ${colorSetStr colors.focusedInactive}
      client.unfocused ${colorSetStr colors.unfocused}
      client.urgent ${colorSetStr colors.urgent}
      client.placeholder ${colorSetStr colors.placeholder}
      client.background ${colors.background}

      ${keybindingsStr { inherit keybindings; }}
      ${keycodebindingsStr keycodebindings}
      ${concatStringsSep "\n" (mapAttrsToList modeStr modes)}
      ${concatStringsSep "\n" (mapAttrsToList assignStr assigns)}
      ${concatStringsSep "\n" (map barStr bars)}
      ${optionalString (gaps != null) gapsStr}
      ${concatStringsSep "\n" (map floatingCriteriaStr floating.criteria)}
      ${concatStringsSep "\n" (map windowCommandsStr window.commands)}
      ${concatStringsSep "\n" (map startupEntryStr startup)}
    ''
  else
    "") + "\n" + cfg.extraConfig);

  # Validates the i3 configuration
  checkI3Config =
    pkgs.runCommandLocal "i3-config" { buildInputs = [ cfg.package ]; } ''
      # We have to make sure the wrapper does not start a dbus session
      export DBUS_SESSION_BUS_ADDRESS=1

      # A zero exit code means Sway succesfully validated the configuration
      i3 -c ${configFile} -C -d all || {
        echo "i3 configuration validation failed"
        echo "For a verbose log of the failure, run 'i3 -c ${configFile} -C -d all'"
        exit 1
      };
      cp ${configFile} $out
    '';

in {
  options = {
    xsession.windowManager.i3 = {
      enable = mkEnableOption "i3 window manager.";

      package = mkOption {
        type = types.package;
        default = pkgs.i3;
        defaultText = literalExample "pkgs.i3";
        example = literalExample "pkgs.i3-gaps";
        description = ''
          i3 package to use.
          If 'i3.config.gaps' settings are specified, 'pkgs.i3-gaps' will be set as a default package.
        '';
      };

      config = mkOption {
        type = types.nullOr configModule;
        default = { };
        description = "i3 configuration options.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description =
          "Extra configuration lines to add to ~/.config/i3/config.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];
      xsession.windowManager.command = "${cfg.package}/bin/i3";
      xdg.configFile."i3/config" = {
        source = checkI3Config;
        onChange = ''
          i3Socket=''${XDG_RUNTIME_DIR:-/run/user/$UID}/i3/ipc-socket.*
          if [ -S $i3Socket ]; then
            echo "Reloading i3"
            $DRY_RUN_CMD ${cfg.package}/bin/i3-msg -s $i3Socket reload 1>/dev/null
          fi
        '';
      };
    }

    (mkIf (cfg.config != null) {
      xsession.windowManager.i3.package =
        mkDefault (if (cfg.config.gaps != null) then pkgs.i3-gaps else pkgs.i3);
    })

    (mkIf (cfg.config != null
      && (any (s: s.workspace != null) cfg.config.startup)) {
        warnings = [
          ("'xsession.windowManager.i3.config.startup.*.workspace' is deprecated, "
            + "use 'xsession.windowManager.i3.config.assigns' instead."
            + "See https://github.com/rycee/home-manager/issues/265.")
        ];
      })
  ]);
}
