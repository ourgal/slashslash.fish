type -q git; or return 1
set root (git rev-parse --show-toplevel 2>/dev/null); or return 1

function __slashslash_root --description 'Lookup git root' --inherit-variable root
  echo "$root"
end
