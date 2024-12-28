function __slashslash_pwd_hook --on-variable PWD --description '// PWD change hook'
  status --is-command-substitution; and return
  set -q NO_SLASHSLASH; and return
  set -q slashslash_plugins; or return

  # Reset to start
  functions -e __slashslash_root __slashslash_resolve_cell __slashslash_resolve_subpath __slashslash_plugin_complete
  set -e __slashslash_plugin

  for plugin in $slashslash_plugins
    set -q __slashslash_verbose; and echo "Loading $plugin"
    if not functions -q "__slashslash_load_$plugin"
      set -q __slashslash_verbose; and echo "W: No plugin loader for $plugin"
      continue
    end
    if __slashslash_load_$plugin
      set -q __slashslash_verbose; and echo "Success!"
      if functions -q __slashslash_root
        set -g __slashslash_plugin "$plugin"
        break
      else
        echo "W: slashslash plugin succeeded loading, but didn't define __slashslash_root: $plugin" >&2
      end
    end
  end
end
