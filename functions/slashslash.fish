function slashslash --description 'Initialize // handling for the specified commands/functions'
  argparse h/help d/disable p/prioritize l/list -- $argv; or return

  if set -q _flag_h
    # TODO: docs about -l/-p
    echo "Usage: slashslash [-h|--help] [-d|--disable] [CMD [CMD [CMD...]]]"
    echo
    echo "Enables slashslash expansion & autocomplete for the specified commands"
    echo "unless -d|--disable is specified, in which case expansion/autocomplete"
    echo "is disabled for the specified commands."
    return 0
  end

  if set -q _flag_p
    set -l new_vals
    for val in $slashslash_plugins
      if not contains $val $argv[1..]
        set -a new_vals $val
      end
    end
    set -p new_vals $argv[1..]
    set -g slashslash_plugins $new_vals
    return 0
  end

  if set -q _flag_l
    for plug in $slashslash_plugins
      echo $plug
    end
    return 0
  end

  if set -q _flag_d
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
  else
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
end
