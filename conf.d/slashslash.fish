# User can run e.g. `ss //foo/bar`
alias ss "eval"

# Setup defaults: user can disable with slashslash -d|--disable CMD
slashslash ss cat ls cp rm mv cd zip unzip vim nvim vi buck sl git hg grep ack

set -g slashslash_plugins

for path in ~/.config/fish/conf.d/slashslash/*_plugin.fish
  string match -rq "(?<name>[^/]+)_plugin.fish" -- $path; or continue
  function __slashslash_load_$name --description "Load slashslash plugin $name from $path" --inherit-variable path
    source $path
  end
  set -a slashslash_plugins "$name"
end

slashslash -p buck git hg

# Call the hook to setup the event listener & check if initial PWD is inside a //
__slashslash_pwd_hook
