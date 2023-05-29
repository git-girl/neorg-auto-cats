# neorg-auto-cats

A plugin to automatically inject metadata that adds directory structure as categories

- Adding categories to new files works 
- Updates categories respecting whatever was written there beforehand

- On a new file injects full metadata 
- On an existing file updates only the categories section of the metadata ( not stuff like updated )

[![demo](https://asciinema.org/a/588188.svg)](https://asciinema.org/a/588188?autoplay=1)

## Install 

For example using packer: 

``` 
use { "git-girl/neorg-auto-cats "}

```
in your neorg config: 
``` 
require('neorg').setup {
  load = { 

  -- all your other stuff

  ["external.auto-cats"] = {},
  }
}

```

## State 

It works i think.
I think i will clean this up over the week and fix the issue on updating but then this should be good to go.
