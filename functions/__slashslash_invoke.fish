function __slashslash_invoke --description 'Expand any // and invoke'
  set -f cmd (__slashslash_expand (string escape -- $argv))
  __slashslash_verbose "//> $cmd"
  eval $cmd
end
