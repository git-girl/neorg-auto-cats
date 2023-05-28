--[[
A Neorg module to register an AutoCommand to inject metadata 
with the relative path from the root workspace as categories

Im trying to just copy paste as much as I can from the Telescope plugin though (*~*)

As per Neorg wiki on core.autocommands using the lua vim.api over the core.autocommands module

I think the directory structure is similar to a regular nvim plugin
and it gets sourced by neorg somehow
--]]

require("neorg.modules.base")

local module = neorg.modules.create("external.auto-cats")

function module.setup()
  return { 
    success = true,
    requires = { 
      "core.keybinds",
      "core.dirman" 
    }
  }
end

module.private = { 
  enabled = true,

  say_hello = function()
    print("saying hello :)")
  end,

  get_existing_metadata = function() 
  end,

  get_path_as_table = function() 
  end,
}

function module.load()
    -- TODO: check how to properly add the aucomand group
    autocats_augroup = vim.api.nvim_create_augroup("NeorgAutoCats", { clear = false })

    vim.api.nvim_create_autocmd({"BufEnter"}, {
        desc = "Inject Metadata into Neorg file if not there, use directories for categories",
        pattern = {"*.norg"},
        callback = function(ev)
          module.private.say_hello()
        end  
    })
end


--[[
Helpful stuff from the api wiki: 
- core.dirman.utils.expand_path: akes a path like $name/my/location and 
converts $name into the full path of the workspace called name.

neorg modules attrs: 
  
  private 
  config  
  public  
  events  

--]]

return module
