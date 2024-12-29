function __slashslash_expand --description "Expand // based on current directory"
  if not set -qg __slashslash_current_cells; or not set -qg __slashslash_current_cell_paths
    __slashslash_verbose "No loaded cells"
    string join \n -- $argv
    return 0
  end

  for arg in $argv
    __slashslash_verbose "processing $arg"

    # Is there // somewhere in this arg?
    if not string match -rq '^(?<cell>[^/\s]*)//(?<subpath>[^\s]*)$' -- $arg
      echo "$arg"
      continue
    end

    if test -z "$cell"
      # Default to 'root'
      set cell "//"
    end

    if not set idx (contains -i "$cell" $__slashslash_current_cells)
      echo "$arg"
      continue
    end
    __slashslash_verbose "idx=$idx"

    set -l root $__slashslash_current_cell_paths[$idx]
    __slashslash_verbose "root=$root"
    set -l abs "$root/$subpath"
    __slashslash_verbose "abs=$abs"

    echo -n (realpath -s --relative-to=. "$abs")
    # Use abs instead of $subpath so that when $subpath is empty
    # the match succeeds and we correctly get a trailing slash.
    string match -rq '/$' -- "$abs"; and echo -n "/"
    echo
  end
end
