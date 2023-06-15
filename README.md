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
  ["external.auto-cats"] = {},
  }
}

```

## State 

I want to clean up the code a bit more, but yeah it works.  \
Also I want to add a hierarchical generate-workspace-summary that respects your folder structure
