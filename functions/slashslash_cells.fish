function slashslash_cells --description "Query the currently available cells"
  if not set -qg __slashslash_current_cells; or not set -qg __slashslash_current_cell_paths
    return 0
  end
  set -f n (count $__slashslash_current_cells)
  if test $n -ne (count $__slashslash_current_cell_paths)
    echo "Internal error: mismatch number of cells and paths" >&2
    return 1
  end
  test $n -eq 0; and return 0

  for i in (seq 1 $n)
    echo $__slashslash_current_cells[$i] : $__slashslash_current_cell_paths[$i]
  end
end
