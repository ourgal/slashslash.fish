function __slashslash_update_cells --description "Internal func to update the cells available for a given process" -a pid
  set -l pid_info (ps -p "$pid" 2>/dev/null); or return 1
  test (count $pid_info) -eq 2; or return 1
  string match -rq 'fish$' -- "$pid_info[2]"; or return 1
  for arg in $argv[2..]
    if not string match -rq '^\s*(?<cell>([a-zA-Z_0-9-]+|//))\s*:\s*(?<path>[^\s]+)$' -- "$arg"
      set -q __slashslash_verbose; and echo "Unable to parse cell: $arg" >&2
      continue
    end
    if test "$cell" = "//"
      set cell ""
    end
    if contains "$cell" $cell_names
      set -q __slashslash_verbose; and echo "Ignoring duplicate '$cell'" >&2
      continue
    end
    set -af cell_names "$cell"
    set -af cell_paths "$path"
  end
  set -f n (count $cell_names)
  test $n -gt 0; or return 0
  string join \n -- $cell_names > /tmp/slashslash_fish_cells_$pid
  string join \n -- $cell_paths > /tmp/slashslash_fish_cell_paths_$pid
end
