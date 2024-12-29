function __slashslash_pwd_hook --on-variable PWD --description '// PWD change hook'
  status is-interactive; or return
  set -qg NO_SLASHSLASH; and return
  set -qg __slashslash_plugins; or return

  for plugin in $__slashslash_plugins
    set -l function_key __slashslash_plugin_$plugin
    set -qg $function_key; or continue
    set -af plugin_funcs $$function_key
  end

  if set -q slashslash_verbose
    set -f inherited_env slashslash_verbose=1
  end
  if set -q slashslash_sync
    env $inherited_env fish -c "__slashslash_write_cells $fish_pid $plugin_funcs"
  else
    env $inherited_env fish -c "__slashslash_write_cells $fish_pid $plugin_funcs" &
  end
end
