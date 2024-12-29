function __slashslash_expand --description "Expand // based on current directory"
  if not set -qg __slashslash_current_cells; or not set -qg __slashslash_current_cell_paths
    set -qg __slashslash_verbose; and echo "No loaded cells" >&2
    string join \n -- $argv
    return 0
  end

  for arg in $argv
    set -qg __slashslash_verbose; and echo "processing $arg" >&2

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
    set -qg __slashslash_verbose; and echo "idx=$idx" >&2

    set -l root $__slashslash_current_cell_paths[$idx]
    set -qg __slashslash_verbose; and echo "root=$root" >&2
    set -l abs "$root/$subpath"
    set -qg __slashslash_verbose; and echo "abs=$abs" >&2

    echo -n (realpath -s --relative-to=. "$abs")
    # Use abs instead of $subpath so that when $subpath is empty
    # the match succeeds and we correctly get a trailing slash.
    string match -rq '/$' -- "$abs"; and echo -n "/"
    echo
  end
end
