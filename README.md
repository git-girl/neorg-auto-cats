# neorg-auto-cats

A plugin to automatically inject metadata that adds directory structure as categories

- Adding categories to new files works
- Updates categories respecting whatever was written there beforehand

- On a new file injects full metadata
- On an existing file updates only the categories section of the metadata ( not stuff like updated )

[![demo](https://asciinema.org/a/588188.svg)](https://asciinema.org/a/588188?autoplay=1)

## Install

For example using packer:

``` lua
use {"git-girl/neorg-auto-cats"}

```

in your neorg config:

``` lua
require('neorg').setup {
  load = { 
  ["core.dirman"] = {
    config = {
      workspaces = {
        -- NOTE: your workspaces have to be named the same 
        -- as their directory. Pro Tip TM: use Symlinks
        General =    "~/Notes/General",
        Work =       "~/Notes/Work",
        Uni =        "~/Notes/Uni"
      }
    }
  },
  -- all your other stuff
  ["external.auto-cats"] = {
    -- for auto-cats config see below
  },
  }
}

```

## Configuration

These are the current deafults that you can overwrite
as part of your neorg config.

``` lua
["external.auto-cats"] = {
    config = {
        -- this flag sets whether we autosave as part of the
        -- autocomand.
        -- i think this is useful and not having it leads
        -- to many buffers that are being written to and you
        -- having to save manually which i don't like.
        -- it's not the default because i think saving
        -- files for you is evil.
        -- interacts with `Neorg insert-cats`
        autosave = false,
        -- this flag sets wheter we register an autocmd to
        -- insert the categories on default.
        -- the workflow for having this as false probably
        -- includes some keybind to `Neorg insert-cats`
        autocmd = true,
    },
},
```
## Neorg Commands from this module: 

| Command             | Functionality                           | Config Options        |
|---------------------|-----------------------------------------|-----------------------|
| `Neorg insert-cats` | inserts the categories like the autocmd | `autosave`            |

## State

I want to clean up the code a bit more, but yeah it works.  \
Also I want to add a hierarchical generate-workspace-summary that respects your folder structure

---

## Dev Notes

### Are Categories Unique?

_with unique i mean global unhierarchical categories_
_so that in the example we treat both foos as the same_
_single foo_

As far as i can tell no neorg spec says anything about 
categories being unique identifiers. \
However thinking about the neorg Roadmap and a rewrite of 
the GTD module i think maybe there it makes more sense 
to think of categories as unique but that's kind of a 
different discussion.

This plugin generally views categories as hierarchical.
Take this example structure:
```
.
├── bar
│   └── foo
└── baz
    └── foo
```
from a file system perspective both `foo` directories are
unique, that would imply that this plugin should view them 
as unique.

However from my intuition dependening on how concrete the 
thing `foo` is the opposite might be more appropriate (i.e.
`docker` vs `exploration`). Imo `exploration` only gains
it's meaning through the hierarchy of directories, so this
would be tied to its parent however `docker` is something
i think can stand on its own.

I think the default should be unique assumption
and maybe there is an option that lets you 
define a table of categories you want tied to 
its parent. \
Then i can concatenate them with a default char
"_" you get to configure though
( so from the example "bar exploration"
to "bar bar_exploration" ) \ 
This way categories are still unique.

An issue i see in unqiue categories is that this
concept kind of breaks the workspace concept and
maybe i have a workspace `Work` and one called
`Uni` and in both places i learn about rust and 
i have a category `Rust` in both. \
Now i would kind of expect both workspace 
categories to hold all entries in the `Rust`
category. \
i think this happens aside from this idea of 
specificity here because if you assume categories
to be unique you kind of expect them to be 
unique on a global workspace level. \
and i think this is kinda bad as it breaks a lot 
with the neorg setup and this would then place 
more and more burden on this plugin to implement
things that keep this logic across the board

Aside from this which is a general 'issue' when
thinking about workspaces and categories i think
unique categories are pretty safe. \
Furthermore we can just set up an option to pull
in for workspace summary generation to pull in 
things across workspaces for a category \
Or another option would be a global generate 
workspace summary.
