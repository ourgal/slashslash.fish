function __slashslash_git
  set root (git rev-parse --show-toplevel 2>/dev/null); or return
  echo "//:$root"
end
