function slashslash_plugin --description "Enable/disable slashslash plugins"
  argparse h/help d/disable l/list v/verbose -- $argv; or return

  if set -ql _flag_h
    echo "Usage:"
    echo "  slashslash_plugin [-h|--help]"
    echo
    echo "    Print this help text"
    echo
    echo "  slashslash_plugin [-d|--disable] NAME CALLBACK"
    echo
    echo "    Enable/disable a plugin named NAME with callback CALLBACK. The"
    echo "    callback should be a function which accepts a single argument."
    echo "    It should print out a list of the form:"
    echo
    echo "      /path/to/root"
    echo "      cell:/path/to/root/cell"
    echo "      cell2:/path/to/root/another/cell2"
    echo
    echo "  slashslash_plugin -l|--list -v|--verbose"
    echo
    echo "    List the available (and enabled) plugins. If --verbose then"
    echo "    each plugins definition will also be printed"
    echo
    return 0
  end

  if set -ql _flag_l
    if not set -qg __slashslash_plugins
      echo "No registered plugins"
      return 1
    end
    for plugin in $__slashslash_plugins
      set -l function_key __slashslash_plugin_$plugin
      if not set -q "$function_key"
        echo "W: Configuration error. $plugin registered but no known definition" >&2
        continue
      end
      set -l function_name $$function_key
      if not functions -q "$function_name"
        echo "W: Configuration error. $plugin registered but missing definition" >&2
        continue
      end
      echo "$plugin : $function_name"
      if set -ql _flag_v
        functions $function_name
      end
    end
    return 0
  end

  if not set -ql _flag_d
    if test (count $argv) -ne 2
      echo "Usage: slashslash_plugin NAME CALLBACK" >&2
      return 1
    end

    set name "$argv[1]"
    set callback "$argv[2]"

    if not functions -q "$callback"
      echo -n "E: $callback is not a function. "(type $callback) >&2
      return 1
    end

    if not set -qg __slashslash_plugins
      set -g __slashslash_plugins
    end
    if not contains "$name" $__slashslash_plugins
      set -ga __slashslash_plugins "$name"
    end

    set -l function_key __slashslash_plugin_$name
    if set -gq $function_key
      echo "I: Overwriting $name, was "$$function_key
    end
    set -g $function_key $callback
    set -q __slashslash_verbose; and echo "Registered $name > $callback"
  else
    if test (count $argv) -ne 1
      echo "Usage: slashslash_plugin -d|--disable NAME" >&2
      return 1
    end
    set name "$argv[1]"

    if not set -qg __slashslash_plugins
      echo "W: No plugins registered, ignoring" >&2
      return 1
    end

    if not set -f idx (contains -i "$name" $__slashslash_plugins)
      echo "W: $name never registered, ignoring" >&2
      return 1
    end

    set -e __slashslash_plugins[$idx]

    set -l function_key __slashslash_plugin_$name
    if not set -gq $function_key
      echo "W: $name callback missing, ignoring" >&2
      return 1
    end
    set -e $function_key
    set -q __slashslash_verbose; and echo "Unregistered $name"
  end
  return 0
end
