## slashslash.fish: Expanding // in commands

TL;DR: This is a fish plugin that lets you remap `//` or `foo//` (for arbitrary 'foo') to paths on disk. You can then enable this remapping logic for any command you'd like.

---

With this plugin you can remap `//` to:
- The root of your current git/sapling/hg repo (if you're in one)
- The root returned by `buck root` if you're in a buck workspace
- Custom 'global' cells
- Custom 'local' cells

If your git repo lives at `/home/foo/bar`, then no matter where you are within that repo `//` will map to `/home/foo/bar`. For example
```
> cd /home/foo/bar
> mkdir baz
> echo "meow" > baz/cat

> cd another/directory
> ls //baz/cat
../../baz/cat
> cat //baz/cat
meow
```

If you've setup a global cell via `ss cells -a code $HOME/Code` then
```
> cd code//
> pwd
$HOME/code

> ls code//  # the same thing as ls $HOME/Code

> !! code//bin/script.sh  # the same thing as eval $HOME/Code/bin/script.sh
```

The last command is defined within this plugin. `!!` simply wraps `eval`, but expands `//` in its args prior to executing. By default the following commands also expand their args prior to executing:

> `cat`, `ls`, `cp`, `rm`, `mv`, `cd`, `zip`, `unzip`, `vim`,
> `nvim`, `vi`, `buck`, `sl`, `git`, `hg`, `grep`, `ack`, `rsync`

You get no warranty, good luck.

## Cells

### Global

#### Static

You can define static cells via `.ss` files. By default `$HOME/.ss` will be loaded if it exists. Otherwise any `.ss` file in your `PWD` or any parent directory will be used as well (the union of all defined cells will be used). Each `.ss` file should look like
```
cell_name : cell_path
cell_name2 : cell_path2
```
You can optionally specify a priority, too by appending it to the end of the line after a space, e.g.
```
special_cell : special/path 10000
```
This is useful when multiple `.ss` files define the same cell. See `ss cells --help` for more info about priority (including the default priority for the builtin plugins).

#### Dynamic

You can define a (dynamic) global cell (meaning it exists no matter what your PWD is) via
```
ss cells -a new_cell /path/to/whatever
```
See `ss cells --help` for more info.

### buck

In buck workspaces buck cells will also automatically expand. So e.g. if you have a cell defined `foobar = path/to/foobar` then `foobar//` will expand to `$WORKSPACE_ROOT/path/to/foobar`, where `$WORKSPACE_ROOT` is the absolute root of the buck repo (i.e. not the curernt cell's root).

### git/sl/hg

For now there are no cells outside of the root `//`. This is because of a lack of imagination: I'm not sure what cell might be useful in a generic SCM repo.

## Installing

### Fisher

```
fisher install danzimm/slashslash.fish
```

### Manual

Copy each of the contents of `conf.d` and `functions` into `~/.config/fish`.

## Controlling Expansion

### Disabling

You can disable expanding `//` for any of the default commands by running
```
ss disable cmd1 cmd2 ...
```

### Enabling
You can enable additional commands to expand `//` prior to execution by running
```
ss secret_command
ss enable secret_command_2
```

## Plugins

Want to expand `//` in more contexts? Follow what's done with `__slashslash_buck` in `conf.d/slashslash.fish`. Essentially you define a (portable, meaning it can run without any configs) function that prints out what cells are available. You then register that function with `ss plugin`. See `ss plugin --help` for more info.

## Motivation

In both buck (& bazel I think) there's a concept of a 'cell' which dictates the current "workspace" you're building from (this is helpful because e.g. each cell has its own configuration). When building/running things within buck you refer to the executable/test/library by a "target", e.g. of the form `cell//path/to:target` (henceforth referred to as a fully qualified target). The `cell` part is optional, and will default to most enclosing cell your $PWD is in.

This "qualified target" specification is also used when loading build files, e.g.
```
load("@cell//build/helper:super_useful.bzl", "magic")
```

I found it annoying to have to convert between the qualified target format & raw paths, so I created a layer in `fish` which will translate `//` into the right path based on your context. Within a buck repo `//` will map to `buck root` (so, in particular it will map to the current cell you're in) and `cell//` will map to the path for that cell (see e.g. `buck audit cell`).

## Roadmap

None, currently. Turns out this was a weekend project for me.

## Contributing

Please do! Glad to accept help, but will respond slowly as time permits. This is a side project, to the extreme.

## NAQBMBAIF

Stands for "Never Asked Questions But Might Be Asked In Future".

### Why only fish?

I don't use any other shell, and don't know if other shells have the required hooks

### Your code is bad

Yep, checks out. But hey, this isn't a question!

### Will you support X?

Put up your request in an issue, maybe!

## Dedication

These scripts are dedicated to my cat Tippy. She unfortunately passed from lymphoma late 2024.

![Photo of Tippy the Cat](tippy.jpeg)
