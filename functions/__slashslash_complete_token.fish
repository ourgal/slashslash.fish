function __slashslash_complete_token --description "Underlying impl of __slashslash_complete"
  set -l cur "$argv[1]"
  string match --quiet -- '-*' $cur && return
  set -l expanded (__slashslash_expand "$cur")
  if test "$expanded" != "$cur"
    set -l unexpanded_dirname (string split --right --max 1 / -- "$cur")[1]
    set -l expanded_dirname (string split --right --max 1 / -- "$expanded")[1]
    set -l start_idx (math (string length "$expanded_dirname") + 1)
    for p in (__fish_complete_path $expanded)
      set -l completed (string sub -s $start_idx -- "$p")
      echo $unexpanded_dirname$completed
    end
  else
    __fish_complete_path $cur
  end
  functions -q __slashslash_plugin_complete; and __slashslash_plugin_complete "$cur"
  return 0
end
