function __slashslash_expand --description "Expand // based on current directory"
  if not set -qg __slashslash_current_cell_names; or not set -qg __slashslash_current_cell_paths
    string join \n -- $argv
    return 0
  end

  for arg in $argv
    # Is there // somewhere in this arg?
    if not string match -rq '^(?<cell>[^/\s]*)//(?<subpath>[^\s]*)$' -- $arg
      echo "$arg"
      continue
    end

    if test -z "$cell"
      # Default to 'root'
      set cell "//"
    end

    if not set idx (contains -i "$cell" -- $__slashslash_current_cell_names)
      echo "$arg"
      continue
    end

    set -l root $__slashslash_current_cell_paths[$idx]
    set -l abs "$root/$subpath"

    echo -n (realpath -s --relative-to=. "$abs")
    # Use abs instead of $subpath so that when $subpath is empty
    # the match succeeds and we correctly get a trailing slash.
    string match -rq '/$' -- "$abs"; and echo -n "/"
    echo
  end
end
