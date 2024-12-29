function __slashslash_load_cells --description "Internal func to load cells from disk" --on-signal WINCH
  status is-interactive; or return

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
