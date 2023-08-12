--[[
This neorg module houses the shared utilities across 
the auto-cats plugin for the different neorg modules
--]]

local module = Neorg.modules.create("external.auto_cats_utils")

function module.setup()
	return {
		success = true,
	}
end

module.public  = {
    debug_print = function(something)
        vim.print(vim.inspect(something))
    end
}

return module
