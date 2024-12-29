function slashslash --description 'Initialize // handling for the specified commands/functions'
  if test (count $argv) -ne 0
    set subcmd __slashslash_$argv[1]_cmd
    if functions -q $subcmd
      $subcmd $argv[2..]
      return $status
    end
  end

  argparse h/help -- $argv; or return

  if set -q _flag_h; or test (count $argv) -eq 0
    echo "Subcommands:"
    echo "  enable -- enable // expansion on a command"
    echo "  disable -- disable // expansion on a command"
    echo "  plugin -- enable/disable/list plugins"
    echo "  expand -- expand //"
    echo
    echo "Defaults to 'enable' if not subcommand specified"
    return 0
  end

  __slashslash_enable_cmd $argv
end

function __slashslash_disable_cmd
  argparse h/help -- $argv; or return

  if set -q _flag_h
    echo "Usage:"
    echo "slashslash disable CMD [CMD [CMD ..]]"
    echo
    echo "Disable expanding // for CMD(s)"
    return 0
  end

  for arg in $argv
    if not functions -q __slashslash_restore_$arg; or not type -q __slashslash_real_$arg
      echo "W: $arg wasn't ever slashslash enabled" >&2
      continue
    end
    # Remove our alias
    functions -e "$arg"
    # Restore original definition
    __slashslash_restore_$arg
    # Disable completion
    complete -e -c $arg -a '(__slashslash_complete)'
    complete -e -c $arg --no-files
    complete -e -c $arg --wraps "__slashslash_invoke __slashslash_real_$arg"
  end
end

function __slashslash_enable_cmd
  argparse h/help -- $argv; or return

  if set -q _flag_h
    echo "Usage:"
    echo "slashslash enable CMD [CMD [CMD ..]]"
    echo
    echo "Enable expanding // for CMD(s)"
    return 0
  end

  for arg in $argv
    if functions -q "__slashslash_real_$arg"
      echo "W: $arg already slashslash enabled, ignoring" >&2
      continue
    end
    if functions -q "$arg"
      functions -c "$arg" "__slashslash_real_$arg"
      function __slashslash_restore_$arg --description "Disable // expansion for $arg"
        functions -c "__slashslash_real_$arg" "$arg"
      end
    else
      alias "__slashslash_real_$arg" "command $arg"
      function __slashslash_restore_$arg --description "Disable // expansion for $arg"
        functions -e "__slashslash_real_$arg"
      end
    end
    alias "$arg" "__slashslash_invoke __slashslash_real_$arg"
    complete -c $arg -a '(__slashslash_complete)'
    complete -c $arg --no-files  # Our completion handler will handle this
  end
end

function __slashslash_plugin_cmd --description "Enable/disable slashslash plugins"
  argparse h/help u/unregister l/list v/verbose -- $argv; or return

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

  if set -ql _flag_h; or test (count $argv) -eq 0
    echo "Usage:"
    echo "slashslash plugin [-h|--help]"
    echo "slashslash plugin [-u|--unregister] NAME CALLBACK"
    echo "slashslash plugin -l|--list -v|--verbose"
    echo
    echo "The default command registers/unregisters a plugin named NAME with callback CALLBACK."
    echo
    echo "When -l|--list is passed then the currently registered plugins are printed. When"
    echo "-v|--verbose is also passed then the plugin definitions will be printed as well."
    echo
    echo "Each plugin should be a function which accepts a path as an argument and prints"
    echo "the list of cells recognized at that path."
    return 0
  end

  if not set -ql _flag_u
    if test (count $argv) -ne 2
      echo "Usage: slashslash plugin NAME CALLBACK" >&2
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
      echo "Usage: slashslash plugin -d|--disable NAME" >&2
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

function __slashslash_expand_cmd --description "Expand // based on current cells"
  if not set -qg __slashslash_current_cells; or not set -qg __slashslash_current_cell_paths
    __slashslash_verbose "No loaded cells"
    string join \n -- $argv
    return 0
  end

  for arg in $argv
    __slashslash_verbose "processing $arg"

    # Is there // somewhere in this arg?
    if not string match -rq '^(?<cell>[^/\s]*)//(?<subpath>[^\s]*)$' -- $arg
      echo "$arg"
      continue
    end

    if test -z "$cell"
      # Default to 'root'
      set cell "//"
    end

    if not set idx (contains -i "$cell" $__slashslash_current_cells)
      echo "$arg"
      continue
    end
    __slashslash_verbose "idx=$idx"

    set -l root $__slashslash_current_cell_paths[$idx]
    __slashslash_verbose "root=$root"
    set -l abs "$root/$subpath"
    __slashslash_verbose "abs=$abs"

    echo -n (realpath -s --relative-to=. "$abs")
    # Use abs instead of $subpath so that when $subpath is empty
    # the match succeeds and we correctly get a trailing slash.
    string match -rq '/$' -- "$abs"; and echo -n "/"
    echo
  end
end
