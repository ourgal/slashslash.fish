function ss --description "Frontend to configure //. See ss --help"
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
    echo "  complete -- print completions of a given token after expanding //"
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
    complete -e -c $arg -a '(__slashslash_complete_cmd (commandline --current-token))'
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
    complete -c $arg -a '(__slashslash_complete_cmd (commandline --current-token))'
    complete -c $arg --no-files  # Our completion handler will handle this
  end
end

function __slashslash_plugin_cmd --description "Enable/disable slashslash plugins"
  argparse h/help u/unregister l/list v/verbose c/complete= s/subpath= -- $argv; or return

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
    echo "slashslash plugin [-c|--complete COMPLETE_CALLBACK] [-s|--subpath SUBPATH_CALLBACK] NAME CALLBACK"
    echo "slashslash plugin -u|--unregister NAME"
    echo "slashslash plugin -l|--list -v|--verbose"
    echo
    echo "The default command registers/unregisters a plugin named NAME with callback CALLBACK."
    echo "The optional -c|--complete flag specifies a callback to be called with a token that"
    echo "should be autocompleted. If -s|--subpath is specified then it will be called to"
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
      echo "Usage: slashslash plugin [-c|--complete COMPLETE_CALLBACK] NAME CALLBACK" >&2
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
    if not contains -- "$name" $__slashslash_plugins
      set -ga __slashslash_plugins "$name"
    end

    set -l function_key __slashslash_plugin_$name
    if set -gq $function_key
      echo "I: Overwriting $name, was "$$function_key
    end
    set -g $function_key $callback

    if set -q _flag_c
      if not functions -q "$_flag_c"
        echo -n "W: Ignoring $_flag_c: not a function. "(type $_flag_c) >&2
      else
        set -g __slashslash_completer_$name "$_flag_c"
        set -ga __slashslash_completers "$name"
      end
    end

    if set -q _flag_s
      if not functions -q "$_flag_s"
        echo -n "W: Ignoring $_flag_s: not a function. "(type $_flag_s) >&2
      else
        set -g __slashslash_subpather_$name "$_flag_s"
      end
    end

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

    if not set -f idx (contains -i -- "$name" $__slashslash_plugins)
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
    set -q __slashslash_completer_$name; and set -e __slashslash_completer_$name
    if set -f cidx (contains -i -- "$name" $__slashslash_completers)
      set -e __slashslash_completers[$cidx]
    end
    set -q __slashslash_subpather_$name; and set -e __slashslash_subpather_$name

    set -q __slashslash_verbose; and echo "Unregistered $name"
  end
  return 0
end

function __slashslash_expand_cmd --description "Expand // based on current cells"
  argparse -i f/force -- $argv
  if not set -q _flag_f; and status is-command-substitution
    string join \n -- $argv
    return 0
  end

  if set -q __slashslash_expanding
    string join \n -- $argv
    return 0
  end
  set -g __slashslash_expanding

  __slashslash_load_cells

  if not set -qg __slashslash_current_cells; or not set -qg __slashslash_current_cell_paths
    __slashslash_verbose "No loaded cells"
    string join \n -- $argv
    set -e __slashslash_expanding
    return 0
  end

  __slashslash_load_cells

  for arg in $argv
    if string match --quiet -- '-*' $arg
      echo "$arg"
      continue
    end
    __slashslash_verbose "// Expanding '$arg'"

    # Is there // somewhere in this arg?
    if not string match -rq '^(?<cell>[^/\s]*//)(?<subpath>[^\s]*)$' -- $arg
      echo "$arg"
      continue
    end

    if not set idx (contains -i -- "$cell" $__slashslash_current_cells)
      echo "$arg"
      continue
    end

    set -l plugin_name $__slashslash_current_cell_plugin_names[$idx]
    set -l root $__slashslash_current_cell_paths[$idx]

    if set -q __slashslash_subpather_$plugin_name
      set subpather __slashslash_subpather_$plugin_name
      set new_subpath ($$subpather "$subpath")
      __slashslash_verbose "  expanded subpath $subpath > $new_subpath"
      set subpath "$new_subpath"
    end

    set -l abs "$root/$subpath"
    __slashslash_verbose "  matched idx=$idx plugin=$plugin_name root=$root abs=$abs"

    echo -n (realpath -s --relative-to=. "$abs")
    # Use abs instead of $subpath so that when $subpath is empty
    # the match succeeds and we correctly get a trailing slash.
    string match -rq '/$' -- "$abs"; and echo -n "/"
    echo
  end
  set -e __slashslash_expanding
end

function __slashslash_complete_cmd -a cur --description "Print completions for a token after expanding //"
  string match --quiet -- '-*' $cur && return
  set -l expanded (__slashslash_expand_cmd -f "$cur")
  if test "$expanded" != "$cur"
    set -f unexpanded_dirname (string split --right --max 1 / -- "$cur")[1]
    if string match -q '*/*' -- "$expanded"
      set -l expanded_dirname (string split --right --max 1 / -- "$expanded")[1]
      set -f start_idx (math (string length "$expanded_dirname") + 1)
    else
      set -f unexpanded_dirname "$unexpanded_dirname/"
      set -f start_idx 1
    end
    for p in (__fish_complete_path $expanded)
      set -l completed (string sub -s $start_idx -- "$p")
      echo $unexpanded_dirname$completed
    end
    for completer_name in $__slashslash_completers
      set -l completer __slashslash_completer_$completer_name
      set -q $completer; and $$completer "$cur"
    end
  else
    __fish_complete_path $cur
    for cell_name in $__slashslash_current_cells
      if test (string sub --length (string length -- "$cur") -- $cell_name) = "$cur"
        echo $cell_name
      end
    end
  end
  return 0
end

function __slashslash_cells_cmd --description "Query the currently available cells. Pass -r/--reload to reload"
  argparse r/reload h/help -- $argv; or return

  if set -ql _flag_h
    echo "Usage:"
    echo "slashslash cells [-h|--help]"
    echo "slashslash cells [-r|reload]"
    echo
    echo "Prints the currently available cells. Passing -r|--reload force reloads the cells"
    return 0
  end

  if set -ql _flag_r
    __slashslash_load_cells --reset
    __slashslash_pwd_hook
    return $status
  end

  __slashslash_load_cells

  if not set -qg __slashslash_current_cells; or not set -qg __slashslash_current_cell_paths
    return 0
  end
  set -f n (count $__slashslash_current_cells)
  if test $n -ne (count $__slashslash_current_cell_paths)
    echo "Internal error: mismatch number of cells and paths" >&2
    return 1
  else if test $n -ne (count $__slashslash_current_cell_plugin_names)
    echo "Internal error: mismatch number of cells and cell plugin names" >&2
    return 1
  end
  test $n -eq 0; and return 0

  for i in (seq 1 $n)
    echo $__slashslash_current_cells[$i] : $__slashslash_current_cell_paths[$i] '('$__slashslash_current_cell_plugin_names[$i]')'
  end
end
