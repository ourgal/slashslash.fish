# User can run e.g. `ss //foo/bar`
alias ss "eval"

# Setup defaults: user can disable with slashslash -d|--disable CMD
slashslash ss cat ls cp rm mv cd zip unzip vim nvim vi buck sl git hg grep ack

# Call initial reload to setup event handlers
slashslash_cells --reload
