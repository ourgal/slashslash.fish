type -q buck; or return 1
buck root 1>/dev/null 2>/dev/null; or return 1

function __buck_sanitize_cell
  string trim (string replace -a '-' '_' -- "$argv[1]")
end

set -l inherited_env
for cell_mapping in (buck audit cell 2>/dev/null)
  set kv (string split ': ' -- "$cell_mapping")
  if test (count $kv) -ne 2
    continue
  end
  set key "__buck_cell_"(__buck_sanitize_cell "$kv[1]")
  set "$key" (string trim -- "$kv[2]")
  set -a inherited_env "--inherit-variable"
  set -a inherited_env "$key"
end

function __slashslash_root --description 'Lookup buck root'
  # We can't cache this because entering cells changes the meaning of // without
  # any cell specified.
  buck root 2>/dev/null
end

function __slashslash_resolve_cell --description 'Resolve buck cell' $inherited_env
  set cell_key "__buck_cell_"(__buck_sanitize_cell "$argv[1]")
  if set -q "$cell_key"
    echo "$$cell_key"
  else
    return 1
  end
end

function __slashslash_resolve_subpath --description 'Expand :foo.bzl > /foo.bzl'
  string replace -r '(?<!\\\\):(?!.*/)' / -- "$argv[1]"
end

function __slashslash_plugin_complete --description 'Autocomplete for buck'
  buck2 complete --target="$argv[1]" 2>/dev/null | command grep -v ':$'
end
