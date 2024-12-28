function __slashslash_invoke --description 'Expand any // and invoke'
  eval (__slashslash_expand (string escape -- $argv))
end
