status is-interactive; or return

function __slashslash_verbose
  set -q slashslash_verbose; and echo $argv >&2
end

function __slashslash_write_cells --description "Internal func to update the cells available for a given process" -a pid
  set -l pid_info (ps -p "$pid" 2>/dev/null); or return 1
  test (count $pid_info) -eq 2; or return 1
  string match -rq 'fish$' -- "$pid_info[2]"; or return 1
  __slashslash_verbose Running plugins: $argv[2..]
  for plugin in $argv[2..]
    for line in ($plugin)
      if not string match -rq '^\s*(?<cell>([a-zA-Z_0-9-]+|//))\s*:\s*(?<path>[^\s]+)(\s+(?<prio>\d+))?$' -- "$line"
        __slashslash_verbose "Unable to parse cell: $line"
        continue
      end
      if not set -q prio; or test -z "$prio"
        set prio 100
      end
      if set idx (contains -i -- "$cell" $cell_names)
        set other_path $cell_paths[$idx]
        set other_prio $cell_prios[$idx]
        if test "$other_path" = "$path"
          set cell_prios[$idx] (math "max($prio, $other_prio)")
        else if test "$other_prio" -lt "$prio"
          __slashslash_verbose "Overwriting $cell: $other_path < $path"
          set cell_paths[$idx] "$path"
          set cell_prios[$idx] "$prio"
        else
          __slashslash_verbose "Not overwriting $cell: $other_path >= $path"
        end
        continue
      end
      set -af cell_names "$cell"
      set -af cell_paths "$path"
      set -af cell_prios "$prio"
    end
  end
  string join \n -- $cell_names > /tmp/slashslash_fish_cells_$pid
  string join \n -- $cell_paths >> /tmp/slashslash_fish_cells_$pid
  echo $PWD >> /tmp/slashslash_fish_cells_$pid
end

function __slashslash_load_cells --description "Internal func to load cells from disk"
  argparse r/reset -- $argv
  if set -ql _flag_r
    set -e __slashslash_current_cells
    set -e __slashslash_current_cell_paths
    set -e __slashslash_loaded_pwd
    return 0
  end

  test "$__slashslash_loaded_pwd" = "$PWD"; and return

  set loaded_data (cat /tmp/slashslash_fish_cells_$fish_pid 2>/dev/null)
  set n (count $loaded_data)
  if test $n -eq 0
    set -e __slashslash_current_cells
    set -e __slashslash_current_cell_paths
    return 0
  end

  if test (math $n % 2) -ne 1
    __slashslash_verbose "Mismatch number of cells and paths"
    return 1
  end

  set n_cells (math "($n - 1) / 2")
  for i in (seq 1 $n_cells)
    set cell $loaded_data[$i]
    set path $loaded_data[(math $n_cells + $i)]
    if not string match -rq '.*//$' -- $cell
      set cell "$cell//"
    end
    set -a cells "$cell"
    set -a paths "$path"
  end

  set -g __slashslash_current_cells $cells
  set -g __slashslash_current_cell_paths $paths
  set -g __slashslash_loaded_pwd $loaded_data[$n]
  return 0
end

function __slashslash_invoke --description 'Expand any // and invoke'
  set -f cmd (__slashslash_expand_cmd -f (string escape -- $argv))
  __slashslash_verbose "//> $cmd"
  eval $cmd
end

function __slashslash_write_cell_script
  functions --no-details __slashslash_verbose
  functions --no-details __slashslash_write_cells
  for arg in $argv
    functions --no-details "$arg"
  end
  if set -q slashslash_verbose
    echo 'set -g slashslash_verbose'
  end
  echo "__slashslash_write_cells $fish_pid $argv"
end

function __slashslash_pwd_hook --on-variable PWD --description '// PWD change hook'
  set -qg NO_SLASHSLASH; and return
  set -qg __slashslash_plugins; or return
  test "$__slashslash_loaded_pwd" = "$PWD"; and return

  for plugin in $__slashslash_plugins
    set -l function_key __slashslash_plugin_$plugin
    set -qg $function_key; or continue
    set -af plugin_funcs $$function_key
  end

  __slashslash_load_cells -r

  if set -q slashslash_verbose
    set -f inherited_env slashslash_verbose=1
  end

  begin
    set -l IFS
    set -l shell_exe (status fish-path)
    set -l shell_script (__slashslash_write_cell_script $plugin_funcs)

    __slashslash_verbose "Running under $shell_exe: `$shell_script`"
    if set -q slashslash_sync
      $shell_exe --no-config -c "$shell_script"
    else
      $shell_exe --no-config -c "$shell_script" &; disown
    end
  end
end

function __slashslash_exit --on-event fish_exit
  test -f "/tmp/slashslash_fish_cells_$fish_pid"; and rm -f "/tmp/slashslash_fish_cells_$fish_pid"
end

# User can run e.g. `!! //foo/bar`
alias !! "eval"

# Setup defaults: user can disable with ss disable
ss !! cat ls cp rm mv cd zip unzip vim nvim vi buck sl git hg grep ack

# Builtin plugins
function __slashslash_buck_complete -a cur
  command buck complete --target="$cur" 2>/dev/null | command grep -v ':$'
end

function __slashslash_buck
  type -q buck; or return
  set -l root (buck root 2>/dev/null); or return
  echo "//: $root 200"
  buck audit cell 2>/dev/null | sed 's|$| 200|'
end

function __slashslash_git
  set root (git rev-parse --show-toplevel 2>/dev/null); or return
  echo "//:$root 150"
end

function __slashslash_hg
  if type -q sl
    set root (sl root 2>/dev/null); or return 0
  else if type -q hg
    set root (hg root 2>/dev/null); or return 0
  end
  echo "//:$root"
end

ss plugin buck __slashslash_buck -c __slashslash_buck_complete
ss plugin git __slashslash_git
ss plugin hg __slashslash_hg

# Load cells for initial PWD
__slashslash_pwd_hook
