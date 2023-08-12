--[[
This neorg module houses the shared utilities across
the auto-cats plugin for the different neorg modules
--]]

local module = Neorg.modules.create("external.auto_cats_utils")

function module.setup()
	return {
		success = true,
        requires = {
			"core.neorgcmd",
			"core.dirman",
        }
	}
end

module.public = {
	debug_print = function(something)
		vim.print(vim.inspect(something))
	end,

    -- sideffect: register neorg command
	register_neorg_command = function(cmd_table)
	    module.required["core.neorgcmd"].add_commands_from_table(cmd_table)
    end,

    -- returns nil or string to workspace
    get_workspace = function()
        local dirman = module.required["core.dirman"]

		local workspace = dirman.get_workspace_match()
		if workspace == "default" then
			workspace = dirman.config.public.default_workspace
		end

        return workspace
    end,
}

return module
