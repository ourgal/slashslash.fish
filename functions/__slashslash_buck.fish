function __slashslash_buck
  type -q buck; or return
  set -l root (buck root 2>/dev/null); or return
  echo "//: $root"
  buck audit cell 2>/dev/null
end
