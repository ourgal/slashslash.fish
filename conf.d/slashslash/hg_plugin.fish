if type -q sl
  set -f cmd sl
else if type -q hg
  set -f cmd hg
else
  return 1
end
set root ($cmd root 2>/dev/null); or return 1

function __slashslash_root --description "Lookup $cmd root" --inherit-variable root
  echo $root
end
