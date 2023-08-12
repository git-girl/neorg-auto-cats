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
        autosave = false,
        -- this flag sets wheter we register an autocmd to
        -- insert the categories on default.
        -- the workflow for having this as false probably
        -- includes some keybind to quickly insert categories
        -- when you want.
        autocmd = true,
    },
},
```

## State

I want to clean up the code a bit more, but yeah it works.  \
Also I want to add a hierarchical generate-workspace-summary that respects your folder structure
