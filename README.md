## slashslash.fish: Expanding // in commands

TL;DR These scripts allow you to do
```
ls some_cell//path
cp foo another//path/
```

You get no warranty, good luck.

---

In both buck (& bazel I think) there's a concept of a 'cell' which dictates the current "workspace" you're building from (this is helpful because e.g. each cell has its own configuration). When building/running things within buck you refer to the executable/test/library by a "target", e.g. of the form `cell//path/to:target` (henceforth referred to as a fully qualified target). The `cell` part is optional, and will default to most enclosing cell your $PWD is in.

This "qualified target" specification is also used when loading build files, e.g.
```
load("@cell//build/helper:super_useful.bzl", "magic")
```

I found it annoying to have to convert between the qualified target format & raw paths, so I created a layer in `fish` which will translate `//` into the right path based on your context. Within a buck repo `//` will map to `buck root` (so, in particular it will map to the current cell you're in) and `cell//` will map to the path for that cell (see e.g. `buck audit cell`).

## git, hg, sl support

In each of these tools there's a similar concept to a "root". These scripts also pick up these roots so that e.g. `ls //` will list the files at the root of your directory.

## Installing

Copy each of the contents of these folders into `~/.config/fish` (you'll need to make the `slashslash` directory). You might be able to use a plugin manager like fisher, but I haven't tried that workflow yet, so it might be broken.

## Configuration

### Defaults

By default `//` will expand for
- `ss` (this is a wrapper around `eval` so that you can eval with `//` patterns)
- `cat`
- `ls`
- `cp`
- `rm`
- `mv`
- `cd`
- `zip`
- `unzip`
- `vim`
- `nvim`
- `vi`
- `buck`
- `sl`
- `git`
- `hg`
- `grep`
- `ack`

### Disabling

You can disable any of these by editing `conf.d/slashslash.fish` directly or specifying
```
slashslash -d cmd1 cmd2 ...
```
to disable expansion for cmd1, cmd2, etc..

### Enabling
You can enable additional commands which have `//` expansion by calling `slashslash` without any flags
```
slashslash secret_command
```

## Plugins

Want to expand `//` in more contexts? There's a very rough plugin system, see e.g. `conf.d/slashslash/buck_plugin.fish`. Each plugin should be placed in `conf.d/slashslash` and return non-0 if it doesn't detect a valid context (e.g. for buck if it doesn't detect a buck workspace, for git no git repo, etc.). The plugin API is as follows (each of these are functions):
- `__slashslash_root` is the only required function: This doesn't take any args and should print the current root given the user's `$PWD`
- `__slashslash_resolve_cell` is optional: it tells slashslash how to convert `cell//` to its own path (if unimplemented then `cell//` expands to `"cell/"(__slashslash_root)`). This function accepts a single argument, the name of the parsed cell. You can return non-0 from this function to indicate no cell was found (and fallback to the behavior as if this function wasn't implemented)
- `__slashslash_resolve_subpath` is optional: it allows manual remapping of `subpath` in a `cell//subpath` expansion. This is used by the `buck` plugin to remap e.g. `foo/bar:baz.bzl` to `foo/bar/baz.bzl` so that you can do e.g. `vim //foo/bar:baz.bzl` (i.e. you can copy strings from load statements directly)
- `__slashslash_plugin_complete` is optional: it accepts a single arg whose autocompletions should be expanded. The completions should be printed one per line. This API is additonal: by default filepaths will always be expanded based on `__slashslash_root`

## Roadmap

Not really one, but I want to implement:
- Better root caching: right now on my M3 MBA cd-ing between git directories takes a non-trivial amount of time. We should be able to detect without any subprocess invocations that we're still inside, or now outside of a git repo. This hasn't been implemented yet because `buck` was the first plugin I made and it doesn't have the same possible optimization (because cd-ing within a buck repo can put you within a new cell, hence `buck root` has to be invalidated/re-called)
- User specified cells. It'd be cool to have `.slashslash_cells` files wherever on disk and they'll automatically be used for expansions, regardless of whether you're in a repo of any sort
