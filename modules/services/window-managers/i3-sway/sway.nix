{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.wayland.windowManager.sway;

  commonOptions = import ./lib/options.nix {
    inherit config lib cfg pkgs;
    moduleName = "sway";
    capitalModuleName = "Sway";
  };

  configModule = types.submodule {
    options = {
      inherit (commonOptions)
        fonts window floating focus assigns workspaceLayout
        workspaceAutoBackAndForth modifier keycodebindings colors bars startup
        gaps menu terminal;

      left = mkOption {
        type = types.str;
        default = "h";
        description = "Home row direction key for moving left.";
      };

      down = mkOption {
        type = types.str;
        default = "j";
        description = "Home row direction key for moving down.";
      };

      up = mkOption {
        type = types.str;
        default = "k";
        description = "Home row direction key for moving up.";
      };

      right = mkOption {
        type = types.str;
        default = "l";
        description = "Home row direction key for moving right.";
      };

      keybindings = mkOption {
        type = types.attrsOf (types.nullOr
          # (commonOptions.coercedToKeybind commonOptions.keybindType));
          (commonOptions.bindingType types.str commonOptions.keybindType));
        default =
          let conf = commonFunctions.mkDefaultKeybind {
            "${cfg.config.modifier}+Return".value = "exec ${cfg.config.terminal}";
            "${cfg.config.modifier}+Shift+q".value = "kill";
            "${cfg.config.modifier}+d".value = "exec ${cfg.config.menu}";

            "${cfg.config.modifier}+${cfg.config.left}".value = "focus left";
            "${cfg.config.modifier}+${cfg.config.down}".value = "focus down";
            "${cfg.config.modifier}+${cfg.config.up}".value = "focus up";
            "${cfg.config.modifier}+${cfg.config.right}".value = "focus right";

            "${cfg.config.modifier}+Left".value = "focus left";
            "${cfg.config.modifier}+Down".value = "focus down";
            "${cfg.config.modifier}+Up".value = "focus up";
            "${cfg.config.modifier}+Right".value = "focus right";

            "${cfg.config.modifier}+Shift+${cfg.config.left}".value = "move left";
            "${cfg.config.modifier}+Shift+${cfg.config.down}".value = "move down";
            "${cfg.config.modifier}+Shift+${cfg.config.up}".value = "move up";
            "${cfg.config.modifier}+Shift+${cfg.config.right}".value =
              "move right";

            "${cfg.config.modifier}+Shift+Left".value = "move left";
            "${cfg.config.modifier}+Shift+Down".value = "move down";
            "${cfg.config.modifier}+Shift+Up".value = "move up";
            "${cfg.config.modifier}+Shift+Right".value = "move right";

            "${cfg.config.modifier}+b".value = "splith";
            "${cfg.config.modifier}+v".value = "splitv";
            "${cfg.config.modifier}+f".value = "fullscreen toggle";
            "${cfg.config.modifier}+a".value = "focus parent";

            "${cfg.config.modifier}+s".value = "layout stacking";
            "${cfg.config.modifier}+w".value = "layout tabbed";
            "${cfg.config.modifier}+e".value = "layout toggle split";

            "${cfg.config.modifier}+Shift+space".value = "floating toggle";
            "${cfg.config.modifier}+space".value = "focus mode_toggle";

            "${cfg.config.modifier}+1".value = "workspace number 1";
            "${cfg.config.modifier}+2".value = "workspace number 2";
            "${cfg.config.modifier}+3".value = "workspace number 3";
            "${cfg.config.modifier}+4".value = "workspace number 4";
            "${cfg.config.modifier}+5".value = "workspace number 5";
            "${cfg.config.modifier}+6".value = "workspace number 6";
            "${cfg.config.modifier}+7".value = "workspace number 7";
            "${cfg.config.modifier}+8".value = "workspace number 8";
            "${cfg.config.modifier}+9".value = "workspace number 9";

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

            "${cfg.config.modifier}+Shift+minus".value = "move scratchpad";
            "${cfg.config.modifier}+minus".value = "scratchpad show";

            "${cfg.config.modifier}+Shift+c".value = "reload";
            "${cfg.config.modifier}+Shift+e".value =
              "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'";

            "${cfg.config.modifier}+r".value = "mode resize";
          };
        in lib.traceSeq (attrNames conf) conf;
        defaultText = "Default sway keybindings.";
        description = ''
          An attribute set that assigns a key press to an action using a key symbol.
          See <link xlink:href="https://i3wm.org/docs/userguide.html#keybindings"/>.
          </para><para>
          Consider to use <code>lib.mkOptionDefault</code> function to extend or override
          default keybindings instead of specifying all of them from scratch.
        '';
        example = literalExample ''
          let
            modifier = config.wayland.windowManager.sway.config.modifier;
          in lib.mkOptionDefault {
            "''${modifier}+Return" = "exec ${cfg.config.terminal}";
            "''${modifier}+Shift+q" = "kill";
            "''${modifier}+d" = "exec ${cfg.config.menu}";
            "''${modifier}+Print" = { flags = [ "--release" ]; value = "exec screenshot.sh"; };
          }
        '';
      };

      bindkeysToCode = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Whether to make use of <option>--to-code</option> in keybindings.
        '';
      };

      input = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = { };
        example = { "*" = { xkb_variant = "dvorak"; }; };
        description = ''
          An attribute set that defines input modules. See man sway_input for options.
        '';
      };

      output = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = { };
        example = { "HDMI-A-2" = { bg = "~/path/to/background.png fill"; }; };
        description = ''
          An attribute set that defines output modules. See man sway_output for options.
        '';
      };

      modes = mkOption {
        type = types.attrsOf (types.attrsOf (types.nullOr (commonOptions.coercedToKeybind commonOptions.keybindType)));
        default = {
          resize = mkDefaultKeybind {
            "${cfg.config.left}".value = "resize shrink width 10 px";
            "${cfg.config.down}".value = "resize grow height 10 px";
            "${cfg.config.up}".value = "resize shrink height 10 px";
            "${cfg.config.right}".value = "resize grow width 10 px";
            "Left".value = "resize shrink width 10 px";
            "Down".value = "resize grow height 10 px";
            "Up".value = "resize shrink height 10 px";
            "Right".value = "resize grow width 10 px";
            "Escape".value = "mode default";
            "Return".value = "mode default";
          };
        };
        description = ''
          An attribute set that defines binding modes and keybindings
          inside them

          Only basic keybinding is supported (bindsym keycomb action),
          for more advanced setup use 'sway.extraConfig'.
        '';
      };
    };
  };

  wrapperOptions = types.submodule {
    options = let
      mkWrapperFeature = default: description:
        mkOption {
          type = types.bool;
          inherit default;
          example = !default;
          description = "Whether to make use of the ${description}";
        };
    in {
      base = mkWrapperFeature true ''
        base wrapper to execute extra session commands and prepend a
        dbus-run-session to the sway command.
      '';
      gtk = mkWrapperFeature false ''
        wrapGAppsHook wrapper to execute sway with required environment
        variables for GTK applications.
      '';
    };
  };

  commonFunctions = import ./lib/functions.nix {
    inherit cfg lib;
    moduleName = "sway";
  };

  inherit (commonFunctions)
    keybindingsStr keycodebindingsStr modeStr assignStr barStr gapsStr
    floatingCriteriaStr windowCommandsStr colorSetStr;

  startupEntryStr = { command, always, ... }: ''
    ${if always then "exec_always" else "exec"} ${command}
  '';

  inputStr = name: attrs: ''
    input "${name}" {
    ${concatStringsSep "\n"
    (mapAttrsToList (name: value: "${name} ${value}") attrs)}
    }
  '';

  outputStr = name: attrs: ''
    output "${name}" {
    ${concatStringsSep "\n"
    (mapAttrsToList (name: value: "${name} ${value}") attrs)}
    }
  '';

  configFile = pkgs.writeText "sway.conf" ((if cfg.config != null then
    with cfg.config; ''
      font pango:${concatStringsSep ", " fonts}
      floating_modifier ${floating.modifier}
      default_border ${if window.titlebar then "normal" else "pixel"} ${
        toString window.border
      }
      default_floating_border ${
        if floating.titlebar then "normal" else "pixel"
      } ${toString floating.border}
      hide_edge_borders ${window.hideEdgeBorders}
      focus_wrapping ${if focus.forceWrapping then "yes" else "no"}
      focus_follows_mouse ${focus.followMouse}
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

      ${keybindingsStr {
        inherit keybindings;
        bindsymArgs =
          lib.optionalString (cfg.config.bindkeysToCode) "--to-code";
      }}
      ${keycodebindingsStr keycodebindings}
      ${concatStringsSep "\n" (mapAttrsToList inputStr input)}
      ${concatStringsSep "\n" (mapAttrsToList outputStr output)}
      ${concatStringsSep "\n" (mapAttrsToList modeStr modes)}
      ${concatStringsSep "\n" (mapAttrsToList assignStr assigns)}
      ${concatStringsSep "\n" (map barStr bars)}
      ${optionalString (gaps != null) gapsStr}
      ${concatStringsSep "\n" (map floatingCriteriaStr floating.criteria)}
      ${concatStringsSep "\n" (map windowCommandsStr window.commands)}
      ${concatStringsSep "\n" (map startupEntryStr startup)}
    ''
  else
    "") + "\n" + (if cfg.systemdIntegration then ''
      exec "systemctl --user import-environment; systemctl --user start sway-session.target"
    '' else
      "") + cfg.extraConfig);

  # Validates the Sway configuration
  checkSwayConfig =
    pkgs.runCommandLocal "sway-config" { buildInputs = [ cfg.package ]; } ''
      # We have to make sure the wrapper does not start a dbus session
      export DBUS_SESSION_BUS_ADDRESS=1

      # A zero exit code means Sway succesfully validated the configuration
      sway --config ${configFile} --validate --debug || {
        echo "Sway configuration validation failed"
        echo "For a verbose log of the failure, run 'sway --config ${configFile} --validate --debug'"
        exit 1
      };
      cp ${configFile} $out
    '';

  defaultSwayPackage = pkgs.sway.override {
    extraSessionCommands = cfg.extraSessionCommands;
    extraOptions = cfg.extraOptions;
    withBaseWrapper = cfg.wrapperFeatures.base;
    withGtkWrapper = cfg.wrapperFeatures.gtk;
  };

in {
  meta.maintainers = [ maintainers.alexarice ];

  options.wayland.windowManager.sway = {
    enable = mkEnableOption "sway wayland compositor";

    package = mkOption {
      type = with types; nullOr package;
      default = defaultSwayPackage;
      defaultText = literalExample "${pkgs.sway}";
      description = ''
        Sway package to use. Will override the options
        'wrapperFeatures', 'extraSessionCommands', and 'extraOptions'.
        Set to <code>null</code> to not add any Sway package to your
        path. This should be done if you want to use the NixOS Sway
        module to install Sway.
      '';
    };

    systemdIntegration = mkOption {
      type = types.bool;
      default = pkgs.stdenv.isLinux;
      example = false;
      description = ''
        Whether to enable <filename>sway-session.target</filename> on
        sway startup. This links to
        <filename>graphical-session.target</filename>.
      '';
    };

    xwayland = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable xwayland, which is needed for the default configuration of sway.
      '';
    };

    wrapperFeatures = mkOption {
      type = wrapperOptions;
      default = { };
      example = { gtk = true; };
      description = ''
        Attribute set of features to enable in the wrapper.
      '';
    };

    extraSessionCommands = mkOption {
      type = types.lines;
      default = "";
      example = ''
        export SDL_VIDEODRIVER=wayland
        # needs qt5.qtwayland in systemPackages
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        # Fix for some Java AWT applications (e.g. Android Studio),
        # use this if they aren't displayed properly:
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
      description = ''
        Shell commands executed just before Sway is started.
      '';
    };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "--verbose"
        "--debug"
        "--unsupported-gpu"
        "--my-next-gpu-wont-be-nvidia"
      ];
      description = ''
        Command line arguments passed to launch Sway. Please DO NOT report
        issues if you use an unsupported GPU (proprietary drivers).
      '';
    };

    config = mkOption {
      type = types.nullOr configModule;
      default = { };
      description = "Sway configuration options.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description =
        "Extra configuration lines to add to ~/.config/sway/config.";
    };
  };

  config = mkIf cfg.enable {
    # wayland.windowManager.sway.config.keybindings = ;

    home.packages = optional (cfg.package != null) cfg.package
      ++ optional cfg.xwayland pkgs.xwayland;
    xdg.configFile."sway/config" = {
      source = checkSwayConfig;
      onChange = ''
        swaySocket=''${XDG_RUNTIME_DIR:-/run/user/$UID}/sway-ipc.$UID.$(${pkgs.procps}/bin/pgrep -x sway || ${pkgs.coreutils}/bin/true).sock
        if [ -S $swaySocket ]; then
          echo "Reloading sway"
          $DRY_RUN_CMD ${pkgs.sway}/bin/swaymsg -s $swaySocket reload
        fi
      '';
    };
    systemd.user.targets.sway-session = mkIf cfg.systemdIntegration {
      Unit = {
        Description = "sway compositor session";
        Documentation = [ "man:systemd.special(7)" ];
        BindsTo = [ "graphical-session.target" ];
        Wants = [ "graphical-session-pre.target" ];
        After = [ "graphical-session-pre.target" ];
      };
    };
  };
}
