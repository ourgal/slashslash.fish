function __slashslash_hg
  if type -q sl
    set root (sl root 2>/dev/null); or return 0
  else if type -q hg
    set root (hg root 2>/dev/null); or return 0
  end
  echo "//:$root"
end
