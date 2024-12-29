status is-interactive; or return

# User can run e.g. `ss //foo/bar`
alias ss "eval"

# Setup defaults: user can disable with slashslash -d|--disable CMD
slashslash ss cat ls cp rm mv cd zip unzip vim nvim vi buck sl git hg grep ack

slashslash_plugin buck __slashslash_buck
slashslash_plugin git __slashslash_git
slashslash_plugin hg __slashslash_hg

# Call initial reload to setup event handlers
slashslash_cells --reload

function __slashslash_exit --on-event fish_exit
  rm /tmp/slashslash_fish_cells_$fish_pid
  rm /tmp/slashslash_fish_cell_paths_$fish_pid
end
