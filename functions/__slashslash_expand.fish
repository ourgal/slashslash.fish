function __slashslash_expand --description "Expand // based on current directory"
  if not functions -q __slashslash_root
    string join -- \n $argv
    return
  end
  for arg in $argv
    # Is there // somewhere in this arg?
    if not string match -rq '^(?<cell>[^/\s]*)//(?<subpath>[^\s]*)$' -- $arg
      echo "$arg"
      continue
    end

    # Ok there is, now to actually expand cell//
    if test -n "$cell"
      set -f cached_key "cached_cell_$cell"
      if set -q "$cached_key"
        set -f root "$$cached_key"
      else if functions -q __slashslash_resolve_cell
        if set -f root (__slashslash_resolve_cell "$cell")
          set -f "$cached_key" "$root"
        else
          set -e root  # unset root to fall through to below
        end
      end
    end
    if not set -q root
      if set -q cached_root
        set -f root "$cached_root"
      else if not set -f root (__slashslash_root)
        echo "$arg"
        continue
      else
        set -f cached_root "$root"
      end
    end

    if functions -q __slashslash_resolve_subpath
      # This is to e.g. expand foo:bar.bzl > foo/bar.bzl
      set -f subpath (__slashslash_resolve_subpath "$subpath")
    end

    set -l abs "$root/$subpath"
    echo -n (realpath -s --relative-to=. "$abs")
    # Use abs instead of $subpath so that when $subpath is empty
    # the match succeeds and we correctly get a trailing slash.
    string match -rq '/$' -- "$abs"; and echo -n "/"
    echo
  end
end
