function __slashslash_pwd_hook --on-variable PWD --description '// PWD change hook'
  status --is-command-substitution; and return
  set -qg NO_SLASHSLASH; and return
  set -qg __slashslash_plugins; or return

  # Reset to start
  for plugin in $__slashslash_plugins
    set -l function_key __slashslash_plugin_$name
    set -qg $function_key; or continue
    set -af plugin_funcs $$function_key
  end

  fish -c "set -l cells
for func in $plugin_funcs
  set -a cells (func)
end
__slashslash_write_cells $fish_pid \$cells" &
end
