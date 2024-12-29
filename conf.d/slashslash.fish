function __slashslash_verbose
  set -gq slashslash_verbose; and echo $argv >&2
end

function __slashslash_buck
  type -q buck; or return
  set -l root (buck root 2>/dev/null); or return
  echo "//: $root"
  buck audit cell 2>/dev/null
end

function __slashslash_git
  set root (git rev-parse --show-toplevel 2>/dev/null); or return
  echo "//:$root"
end

function __slashslash_hg
  if type -q sl
    set root (sl root 2>/dev/null); or return 0
  else if type -q hg
    set root (hg root 2>/dev/null); or return 0
  end
  echo "//:$root"
end

function __slashslash_write_cells --description "Internal func to update the cells available for a given process" -a pid
  set -l pid_info (ps -p "$pid" 2>/dev/null); or return 1
  test (count $pid_info) -eq 2; or return 1
  string match -rq 'fish$' -- "$pid_info[2]"; or return 1
  __slashslash_verbose Running plugins: $argv[2..]
  for plugin in $argv[2..]
    for line in ($plugin)
      if not string match -rq '^\s*(?<cell>([a-zA-Z_0-9-]+|//))\s*:\s*(?<path>[^\s]+)$' -- "$line"
        __slashslash_verbose "Unable to parse cell: $line"
        continue
      end
      if contains "$cell" $cell_names
        __slashslash_verbose "Ignoring duplicate '$cell'"
        continue
      end
      set -af cell_names "$cell"
      set -af cell_paths "$path"
    end
  end
  string join \n -- $cell_names > /tmp/slashslash_fish_cells_$pid
  string join \n -- $cell_paths > /tmp/slashslash_fish_cell_paths_$pid
  kill -WINCH $pid
end

status is-interactive; or return

function __slashslash_load_cells --description "Internal func to load cells from disk" --on-signal WINCH
  argparse r/reset -- $argv
  if set -ql _flag_r
    set -e __slashslash_current_cells
    set -e __slashslash_current_cell_paths
    return 0
  end

  set -l cells (cat /tmp/slashslash_fish_cells_$fish_pid 2>/dev/null)
  set -l paths (cat /tmp/slashslash_fish_cell_paths_$fish_pid 2>/dev/null)
  if test (count $cells) -ne (count $paths)
    __slashslash_verbose "Mismatch number of cells and paths"
    return 1
  end
  set -g __slashslash_current_cells $cells
  set -g __slashslash_current_cell_paths $paths
  return 0
end

function __slashslash_invoke --description 'Expand any // and invoke'
  set -f cmd (slashslash expand (string escape -- $argv))
  __slashslash_verbose "//> $cmd"
  eval $cmd
end

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

function __slashslash_exit --on-event fish_exit
  rm /tmp/slashslash_fish_cells_$fish_pid
  rm /tmp/slashslash_fish_cell_paths_$fish_pid
end

# User can run e.g. `ss //foo/bar`
alias ss "eval"

# Setup defaults: user can disable with slashslash -d|--disable CMD
slashslash ss cat ls cp rm mv cd zip unzip vim nvim vi buck sl git hg grep ack

# Builtin plugins
slashslash plugin buck __slashslash_buck
slashslash plugin git __slashslash_git
slashslash plugin hg __slashslash_hg

# Load cells for initial PWD
__slashslash_pwd_hook
