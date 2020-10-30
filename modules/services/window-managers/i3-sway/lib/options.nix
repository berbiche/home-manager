{ config, lib, moduleName, cfg, pkgs, capitalModuleName ? moduleName
, isGaps ? true }:

with lib;

let
  fonts = mkOption {
    type = types.listOf types.str;
    default = [ "monospace 8" ];
    description = ''
      Font list used for window titles. Only FreeType fonts are supported.
      The order here is important (e.g. icons font should go before the one used for text).
    '';
    example = [ "FontAwesome 10" "Terminus 10" ];
  };

  startupModule = types.submodule {
    options = {
      command = mkOption {
        type = types.str;
        description = "Command that will be executed on startup.";
      };

      always = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to run command on each ${moduleName} restart.";
      };
    } // optionalAttrs (moduleName == "i3") {
      notification = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable startup-notification support for the command.
          See <option>--no-startup-id</option> option description in the i3 user guide.
        '';
      };

      workspace = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Launch application on a particular workspace. DEPRECATED:
          Use <varname><link linkend="opt-xsession.windowManager.i3.config.assigns">xsession.windowManager.i3.config.assigns</link></varname>
          instead. See <link xlink:href="https://github.com/rycee/home-manager/issues/265"/>.
        '';
      };
    };

  };

  barModule = types.submodule {
    options = let
      versionAtLeast2009 = versionAtLeast config.home.stateVersion "20.09";
      mkNullableOption = { type, default, ... }@args:
        mkOption (args // optionalAttrs versionAtLeast2009 {
          type = types.nullOr type;
          default = null;
          example = default;
        } // {
          defaultText = literalExample ''
            ${
              if isString default then default else "See code"
            } for state version < 20.09,
            null for state version ≥ 20.09
          '';
        });
    in {
      fonts = fonts // optionalAttrs versionAtLeast2009 { default = [ ]; };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra configuration lines for this bar.";
      };

      id = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Specifies the bar ID for the configured bar instance.
          If this option is missing, the ID is set to bar-x, where x corresponds
          to the position of the embedding bar block in the config file.
        '';
      };

      mode = mkNullableOption {
        type = types.enum [ "dock" "hide" "invisible" ];
        default = "dock";
        description = "Bar visibility mode.";
      };

      hiddenState = mkNullableOption {
        type = types.enum [ "hide" "show" ];
        default = "hide";
        description = "The default bar mode when 'bar.mode' == 'hide'.";
      };

      position = mkNullableOption {
        type = types.enum [ "top" "bottom" ];
        default = "bottom";
        description = "The edge of the screen ${moduleName}bar should show up.";
      };

      workspaceButtons = mkNullableOption {
        type = types.bool;
        default = true;
        description = "Whether workspace buttons should be shown or not.";
      };

      workspaceNumbers = mkNullableOption {
        type = types.bool;
        default = true;
        description =
          "Whether workspace numbers should be displayed within the workspace buttons.";
      };

      command = mkOption {
        type = types.str;
        default = "${cfg.package}/bin/${moduleName}bar";
        defaultText = "i3bar";
        description = "Command that will be used to start a bar.";
        example = if moduleName == "i3" then
          "\${pkgs.i3-gaps}/bin/i3bar -t"
        else
          "\${pkgs.waybar}/bin/waybar";
      };

      statusCommand = mkOption {
        type = types.nullOr types.str;
        default =
          if versionAtLeast2009 then null else "${pkgs.i3status}/bin/i3status";
        example = "i3status";
        description = "Command that will be used to get status lines.";
      };

      colors = mkOption {
        type = types.submodule {
          options = {
            background = mkNullableOption {
              type = types.str;
              default = "#000000";
              description = "Background color of the bar.";
            };

            statusline = mkNullableOption {
              type = types.str;
              default = "#ffffff";
              description = "Text color to be used for the statusline.";
            };

            separator = mkNullableOption {
              type = types.str;
              default = "#666666";
              description = "Text color to be used for the separator.";
            };

            focusedWorkspace = mkNullableOption {
              type = barColorSetModule;
              default = {
                border = "#4c7899";
                background = "#285577";
                text = "#ffffff";
              };
              description = ''
                Border, background and text color for a workspace button when the workspace has focus.
              '';
            };

            activeWorkspace = mkNullableOption {
              type = barColorSetModule;
              default = {
                border = "#333333";
                background = "#5f676a";
                text = "#ffffff";
              };
              description = ''
                Border, background and text color for a workspace button when the workspace is active.
              '';
            };

            inactiveWorkspace = mkNullableOption {
              type = barColorSetModule;
              default = {
                border = "#333333";
                background = "#222222";
                text = "#888888";
              };
              description = ''
                Border, background and text color for a workspace button when the workspace does not
                have focus and is not active.
              '';
            };

            urgentWorkspace = mkNullableOption {
              type = barColorSetModule;
              default = {
                border = "#2f343a";
                background = "#900000";
                text = "#ffffff";
              };
              description = ''
                Border, background and text color for a workspace button when the workspace contains
                a window with the urgency hint set.
              '';
            };

            bindingMode = mkNullableOption {
              type = barColorSetModule;
              default = {
                border = "#2f343a";
                background = "#900000";
                text = "#ffffff";
              };
              description =
                "Border, background and text color for the binding mode indicator";
            };
          };
        };
        default = { };
        description = ''
          Bar color settings. All color classes can be specified using submodules
          with 'border', 'background', 'text', fields and RGB color hex-codes as values.
          See default values for the reference.
          Note that 'background', 'status', and 'separator' parameters take a single RGB value.

          See <link xlink:href="https://i3wm.org/docs/userguide.html#_colors"/>.
        '';
      };

      trayOutput = mkNullableOption {
        type = types.str;
        default = "primary";
        description = "Where to output tray.";
      };
    };
  };

  barColorSetModule = types.submodule {
    options = {
      border = mkOption {
        type = types.str;
        visible = false;
      };

      background = mkOption {
        type = types.str;
        visible = false;
      };

      text = mkOption {
        type = types.str;
        visible = false;
      };
    };
  };

  colorSetModule = types.submodule {
    options = {
      border = mkOption {
        type = types.str;
        visible = false;
      };

      childBorder = mkOption {
        type = types.str;
        visible = false;
      };

      background = mkOption {
        type = types.str;
        visible = false;
      };

      text = mkOption {
        type = types.str;
        visible = false;
      };

      indicator = mkOption {
        type = types.str;
        visible = false;
      };
    };
  };

  windowCommandModule = types.submodule {
    options = {
      command = mkOption {
        type = types.str;
        description = "${capitalModuleName}wm command to execute.";
        example = "border pixel 1";
      };

      criteria = mkOption {
        type = criteriaModule;
        description =
          "Criteria of the windows on which command should be executed.";
        example = { title = "x200: ~/work"; };
      };
    };
  };

  keybindType = types.submodule (let
    flags = [ "--whole-window" "--border" "--exclude-titlebar" "--release" ]
      ++ optionals (moduleName == "sway") [ "--locked" "--no-warn" ];
    inputDevice = types.strMatching "--input-device=.+";
    flagsType = assert moduleName == "sway" || moduleName == "i3";
      if moduleName == "sway" then
        types.either inputDevice (types.enum flags)
      else
        types.enum flags;
  in {
    options = {
      flags = mkOption {
        type = types.listOf flagsType;
        default = [ ];
        description = "Keybind flags";
        example = literalExample ''[ "--release" ]'';
      };
      value = mkOption {
        type = types.nullOr types.str;
        description = "Keybind value";
        example = "exec /bin/script.sh";
      };
    };
  });

  keycodeType = types.submodule (let
    flags = [ "--release" ] ++ optionals (moduleName == "sway") [
      "--whole-window"
      "--border"
      "--exclude-titlebar"
      "--locked"
      "--no-warn"
    ];
    inputDevice = types.strMatching "--input-device=.+";
    flagsType = if moduleName == "sway" then
      types.either inputDevice (types.enum flags)
    else
      types.enum flags;
  in {
    options = {
      flags = mkOption {
        type = types.listOf flagsType;
        default = [ ];
        description = "Keycode flags";
        example = literalExample ''[ "--release" ]'';
      };
      value = mkOption {
        type = types.nullOr types.str;
        description = "Keycode value";
        example = "exec /bin/script.sh";
      };
    };
  });

  /* This is copied from <nixpkgs>/lib/types.nix @ types.either
     with a modification to the last outer else clause.

     Basically, we want key{bindings,codes} to be me mergeable where the user only redefines
     `defaultKeybinding.flags` to `defaultKeybinding = { inherit flags; value = defaultKeybinding; };`.
     Keybindings/Keycodes are an `either str {keybind/keycode}Type`.

     We copied the merge definition of either and expanded that of `mergeOneOption`
     to ressemble the one of `mergeEqualOption` plus our modifications.

     The logic is somewhat similar to `types.coercedTo` where we coerced the string to a set.

     There are test cases in `tests/modules/services/window-managers/sway` for the merging.
  */
  bindingType = t1: t2:
    (types.either t1 t2) // {
      merge = loc: defs:
        let
          defList = traceSeq defs (map (d: d.value) defs);
          notNull = def: attr: (def.value.${attr} or null) != null;
          isNull = def: attr: !notNull def attr;
          areEqual = def1: def2: attr:
            def1.value.${attr} or null == def2.value.${attr} or null;
          # This is available in the latest master of Nixpkgs as `lib.options.showDefs`
          showDefs = defs:
            concatMapStrings (def:
              let
                # Pretty print the value for display, if successful
                prettyEval =
                  builtins.tryEval (lib.generators.toPretty { } def.value);
                # Split it into its lines
                lines =
                  filter (v: !isList v) (builtins.split "\n" prettyEval.value);
                # Only display the first 5 lines, and indent them for better visibility
                value = concatStringsSep "\n    "
                  (take 5 lines ++ optional (length lines > 5) "...");
                result =
                  # Don't print any value if evaluating the value strictly fails
                  if !prettyEval.success then
                    ""
                    # Put it on a new line if it consists of multiple
                  else if length lines > 1 then
                    ''
                      :
                          '' + value
                  else
                    ": " + value;
              in ''

                - In `${def.file}'${result}'') defs;
          error = first: def:
            throw
            "The option `${showOption loc}' has conflicting definition values:${
              showDefs [ first def ]
            }";
        in if all (x: t1.check x) defList then
          t1.merge loc defs
        else if all (x: t2.check x) defList then
          t2.merge loc defs
        else if defs == [ ] then
          abort "This case should never happen."
          # Our modifications start here
        else if length defs == 1 then
          (elemAt defs 0).value
        else
        /* We recurse on all of the definitions and try to merge a single string value with
           a set where only flags is defined.
        */
          (foldl' (first: def:
            # Merge string with set if they have the same value
            if isAttrs first && isString def
            && (isNull first "value" || areEqual def first "value") then
              first // {
                value = {
                  flags = first.value.flags or [ ];
                  value = def.value;
                };
              }
              # Merge string with set if they have the same value
            else if isString first && isAttrs def
            && (isNull def "value" || areEqual def first "value") then
              def // {
                value = {
                  flags = def.value.flags or [ ];
                  value = first.value;
                };
              }
              # Noop if the two are sets with the same value
            else if isAttrs first && isAttrs def && first.value
            == def.value then
              first
              # Noop if the two are strings with the same value
            else if isString first && isString def && first.value
            == def.value then
              first
            else if isAttrs first && isAttrs def && areEqual def first "flags"
            && (isNull first "value" || isNull def "value") then
              first // {
                value = {
                  flags = first.value.flags;
                  value = null;
                };
              }
            else if first.value == null then
              def
            else
              error first def) (head defs) (tail defs)).value;
    };

  coercedToKeybind = keybindType:
    let
      func = value: {
        flags = [ ];
        value = builtins.trace "value ${value}" value;
      };
    in types.coercedTo types.str func keybindType;

  criteriaModule = types.attrsOf types.str;
in {
  inherit fonts bindingType keybindType keycodeType coercedToKeybind;

  window = mkOption {
    type = types.submodule {
      options = {
        titlebar = mkOption {
          type = types.bool;
          default = !isGaps;
          defaultText = if moduleName == "i3" then
            "xsession.windowManager.i3.package != nixpkgs.i3-gaps (titlebar should be disabled for i3-gaps)"
          else
            "false";
          description = "Whether to show window titlebars.";
        };

        border = mkOption {
          type = types.int;
          default = 2;
          description = "Window border width.";
        };

        hideEdgeBorders = mkOption {
          type = types.enum [ "none" "vertical" "horizontal" "both" "smart" ];
          default = "none";
          description = "Hide window borders adjacent to the screen edges.";
        };

        commands = mkOption {
          type = types.listOf windowCommandModule;
          default = [ ];
          description = ''
            List of commands that should be executed on specific windows.
            See <option>for_window</option> ${moduleName}wm option documentation.
          '';
          example = [{
            command = "border pixel 1";
            criteria = { class = "XTerm"; };
          }];
        };
      };
    };
    default = { };
    description = "Window titlebar and border settings.";
  };

  floating = mkOption {
    type = types.submodule {
      options = {
        titlebar = mkOption {
          type = types.bool;
          default = !isGaps;
          defaultText = if moduleName == "i3" then
            "xsession.windowManager.i3.package != nixpkgs.i3-gaps (titlebar should be disabled for i3-gaps)"
          else
            "false";
          description = "Whether to show floating window titlebars.";
        };

        border = mkOption {
          type = types.int;
          default = 2;
          description = "Floating windows border width.";
        };

        modifier = mkOption {
          type =
            types.enum [ "Shift" "Control" "Mod1" "Mod2" "Mod3" "Mod4" "Mod5" ];
          default = cfg.config.modifier;
          defaultText = "${moduleName}.config.modifier";
          description =
            "Modifier key that can be used to drag floating windows.";
          example = "Mod4";
        };

        criteria = mkOption {
          type = types.listOf criteriaModule;
          default = [ ];
          description =
            "List of criteria for windows that should be opened in a floating mode.";
          example = [
            { "title" = "Steam - Update News"; }
            { "class" = "Pavucontrol"; }
          ];
        };
      };
    };
    default = { };
    description = "Floating window settings.";
  };

  focus = mkOption {
    type = types.submodule {
      options = {
        newWindow = mkOption {
          type = types.enum [ "smart" "urgent" "focus" "none" ];
          default = "smart";
          description = ''
            This option modifies focus behavior on new window activation.

            See <link xlink:href="https://i3wm.org/docs/userguide.html#focus_on_window_activation"/>
          '';
          example = "none";
        };

        followMouse = mkOption {
          type = if moduleName == "sway" then
            types.either (types.enum [ "yes" "no" "always" ]) types.bool
          else
            types.bool;
          default = if moduleName == "sway" then "yes" else true;
          description = "Whether focus should follow the mouse.";
          apply = val:
            if (moduleName == "sway" && isBool val) then
              (if val then "yes" else "no")
            else
              val;
        };

        forceWrapping = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to force focus wrapping in tabbed or stacked container.

            See <link xlink:href="https://i3wm.org/docs/userguide.html#_focus_wrapping"/>
          '';
        };

        mouseWarping = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether mouse cursor should be warped to the center of the window when switching focus
            to a window on a different output.
          '';
        };
      };
    };
    default = { };
    description = "Focus related settings.";
  };

  assigns = mkOption {
    type = types.attrsOf (types.listOf criteriaModule);
    default = { };
    description = ''
      An attribute set that assigns applications to workspaces based
      on criteria.
    '';
    example = literalExample ''
      {
      "1: web" = [{ class = "^Firefox$"; }];
      "0: extra" = [{ class = "^Firefox$"; window_role = "About"; }];
      }
    '';
  };

  modifier = mkOption {
    type = types.enum [ "Shift" "Control" "Mod1" "Mod2" "Mod3" "Mod4" "Mod5" ];
    default = "Mod1";
    description = "Modifier key that is used for all default keybindings.";
    example = "Mod4";
  };

  workspaceLayout = mkOption {
    type = types.enum [ "default" "stacked" "tabbed" ];
    default = "default";
    example = "tabbed";
    description = ''
      The mode in which new containers on workspace level will
      start.
    '';
  };

  workspaceAutoBackAndForth = mkOption {
    type = types.bool;
    default = false;
    example = true;
    description = ''
      Assume you are on workspace "1: www" and switch to "2: IM" using
      mod+2 because somebody sent you a message. You don’t need to remember
      where you came from now, you can just press $mod+2 again to switch
      back to "1: www".
    '';
  };

  keycodebindings = mkOption {
    type = types.attrsOf (types.nullOr (types.either types.str keycodeType));
    default = { };
    description = ''
      An attribute set that assigns keypress to an action using key code.
      See <link xlink:href="https://i3wm.org/docs/userguide.html#keybindings"/>.
    '';
    example = { "214" = "exec /bin/script.sh"; };
  };

  colors = mkOption {
    type = types.submodule {
      options = {
        background = mkOption {
          type = types.str;
          default = "#ffffff";
          description = ''
            Background color of the window. Only applications which do not cover
            the whole area expose the color.
          '';
        };

        focused = mkOption {
          type = colorSetModule;
          default = {
            border = "#4c7899";
            background = "#285577";
            text = "#ffffff";
            indicator = "#2e9ef4";
            childBorder = "#285577";
          };
          description = "A window which currently has the focus.";
        };

        focusedInactive = mkOption {
          type = colorSetModule;
          default = {
            border = "#333333";
            background = "#5f676a";
            text = "#ffffff";
            indicator = "#484e50";
            childBorder = "#5f676a";
          };
          description = ''
            A window which is the focused one of its container,
            but it does not have the focus at the moment.
          '';
        };

        unfocused = mkOption {
          type = colorSetModule;
          default = {
            border = "#333333";
            background = "#222222";
            text = "#888888";
            indicator = "#292d2e";
            childBorder = "#222222";
          };
          description = "A window which is not focused.";
        };

        urgent = mkOption {
          type = colorSetModule;
          default = {
            border = "#2f343a";
            background = "#900000";
            text = "#ffffff";
            indicator = "#900000";
            childBorder = "#900000";
          };
          description = "A window which has its urgency hint activated.";
        };

        placeholder = mkOption {
          type = colorSetModule;
          default = {
            border = "#000000";
            background = "#0c0c0c";
            text = "#ffffff";
            indicator = "#000000";
            childBorder = "#0c0c0c";
          };
          description = ''
            Background and text color are used to draw placeholder window
            contents (when restoring layouts). Border and indicator are ignored.
          '';
        };
      };
    };
    default = { };
    description = ''
      Color settings. All color classes can be specified using submodules
      with 'border', 'background', 'text', 'indicator' and 'childBorder' fields
      and RGB color hex-codes as values. See default values for the reference.
      Note that '${moduleName}.config.colors.background' parameter takes a single RGB value.

      See <link xlink:href="https://i3wm.org/docs/userguide.html#_changing_colors"/>.
    '';
  };

  bars = mkOption {
    type = types.listOf barModule;
    default = if versionAtLeast config.home.stateVersion "20.09" then [{
      mode = "dock";
      hiddenState = "hide";
      position = "bottom";
      workspaceButtons = true;
      workspaceNumbers = true;
      statusCommand = "${pkgs.i3status}/bin/i3status";
      fonts = [ "monospace 8" ];
      trayOutput = "primary";
      colors = {
        background = "#000000";
        statusline = "#ffffff";
        separator = "#666666";
        focusedWorkspace = {
          border = "#4c7899";
          background = "#285577";
          text = "#ffffff";
        };
        activeWorkspace = {
          border = "#333333";
          background = "#5f676a";
          text = "#ffffff";
        };
        inactiveWorkspace = {
          border = "#333333";
          background = "#222222";
          text = "#888888";
        };
        urgentWorkspace = {
          border = "#2f343a";
          background = "#900000";
          text = "#ffffff";
        };
        bindingMode = {
          border = "#2f343a";
          background = "#900000";
          text = "#ffffff";
        };
      };
    }] else
      [ { } ];
    description = ''
      ${capitalModuleName} bars settings blocks. Set to empty list to remove bars completely.
    '';
  };

  startup = mkOption {
    type = types.listOf startupModule;
    default = [ ];
    description = ''
      Commands that should be executed at startup.

      See <link xlink:href="https://i3wm.org/docs/userguide.html#_automatically_starting_applications_on_i3_startup"/>.
    '';
    example = if moduleName == "i3" then
      literalExample ''
        [
        { command = "systemctl --user restart polybar"; always = true; notification = false; }
        { command = "dropbox start"; notification = false; }
        { command = "firefox"; workspace = "1: web"; }
        ];
      ''
    else
      literalExample ''
        [
        { command = "systemctl --user restart waybar"; always = true; }
        { command = "dropbox start"; }
        { command = "firefox"; }
        ]
      '';
  };

  gaps = mkOption {
    type = types.nullOr (types.submodule {
      options = {
        inner = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Inner gaps value.";
          example = 12;
        };

        outer = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Outer gaps value.";
          example = 5;
        };

        horizontal = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Horizontal gaps value.";
          example = 5;
        };

        vertical = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Vertical gaps value.";
          example = 5;
        };

        top = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Top gaps value.";
          example = 5;
        };

        left = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Left gaps value.";
          example = 5;
        };

        bottom = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Bottom gaps value.";
          example = 5;
        };

        right = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Right gaps value.";
          example = 5;
        };

        smartGaps = mkOption {
          type = types.bool;
          default = false;
          description = ''
            This option controls whether to disable all gaps (outer and inner)
            on workspace with a single container.
          '';
          example = true;
        };

        smartBorders = mkOption {
          type = types.enum [ "on" "off" "no_gaps" ];
          default = "off";
          description = ''
            This option controls whether to disable container borders on
            workspace with a single container.
          '';
        };
      };
    });
    default = null;
    description = if moduleName == "sway" then ''
      Gaps related settings.
    '' else ''
      i3Gaps related settings. The i3-gaps package must be used for these features to work.
    '';
  };

  terminal = mkOption {
    type = types.str;
    default = if moduleName == "i3" then
      "i3-sensible-terminal"
    else
      "${pkgs.rxvt-unicode-unwrapped}/bin/urxvt";
    description = "Default terminal to run.";
    example = "alacritty";
  };

  menu = mkOption {
    type = types.str;
    default = if moduleName == "sway" then
      "${pkgs.dmenu}/bin/dmenu_path | ${pkgs.dmenu}/bin/dmenu | ${pkgs.findutils}/bin/xargs swaymsg exec --"
    else
      "${pkgs.dmenu}/bin/dmenu_run";
    description = "Default launcher to use.";
    example = "bemenu-run";
  };
}
