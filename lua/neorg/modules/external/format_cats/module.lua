--[[
A Neorg module that exposes a Neorg command that wraps
Neorgs summary command `Neorg generate-workspace-summary`
so that the headings mirror the hierarchical nature of
the categories analogous to the filesystem that auto-cats
assumes

It is managed and configured via the auto-cats module.
--]]

local module = Neorg.modules.create("external.format_cats")

module.setup = function()
	return {
		success = true,
		requires = {
			"core.neorgcmd",
			"external.auto_cats_utils",
		},
	}
end

module.load = function()
	module.required["core.neorgcmd"].add_commands_from_table(module.config.private.cmd_table)
end

module.config.private = {
	cmd_table = {
		["format-cats"] = {
			args = 0,
			condition = "norg",
			name = "neorg-auto-cats.format-cats",
		},
	},
}

module.private = {
	main = function(event)
		module.required["external.auto_cats_utils"].debug_print(event)
    end,
}

module.events.subscribed = {
		["core.neorgcmd"] = {
			-- "Has the same name as our "name" variable had in the "data" table },"
			["neorg-auto-cats.format-cats"] = true,
        }
}

module.on_event = function(event)
	module.private.main(event)
end

return module
