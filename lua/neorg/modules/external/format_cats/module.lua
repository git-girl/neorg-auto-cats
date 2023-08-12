--[[
A Neorg module that exposes a Neorg command that wraps
Neorgs summary command `Neorg generate-workspace-summary`
so that the headings mirror the hierarchical nature of
the categories analogous to the filesystem that auto-cats
assumes

It is managed and configured via the auto-cats module.
--]]

-- TODO: check If i can do something like taking out this bit here
-- to be not a Neorg module at this point and just return a tbale
-- then in the main module i take this as a table set the mains
-- things on it and then its good
-- -> NOTE: main will be able to overwrite settings on this then

-- did also checkout import param on create
-- that seemed to again be a dependency loop and this lower
-- level thing shouldn't require the top level thing
local module = Neorg.modules.create("external.format_cats")

module.setup = function()
	return {
		success = true,
		requires = {
			"external.auto_cats_utils",
		},
	}
end

module.load = function()
	module.required["external.auto_cats_utils"].register_neorg_command(module.config.private.cmd_table)
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
		module.required["external.auto_cats_utils"].debug_print(module.config.custom)
	end,

	-- format_categories_main = function(buffer)
	-- 	local workspace = module.required["core.dirman"].get_current_workspace()
	-- 	local ws_path = workspace[2]
	--
	-- 	-- TODO: left of at this kinda working but I need a thing
	-- 	-- to ignore all hidden .dirs like .git
	-- 	-- and i need to ignore all dirs defined in gitignore
	-- 	-- print(vim.inspect(module.private.directory_map(ws_path)))
	-- 	-- TODO: take this and then match the top level names against things in cats
	-- 	-- voila proper hierarchy cats
	--
	-- 	-- module.private.directory_map(workspace)
	-- end,
}

module.config.public = {}

module.events.subscribed = {
	["core.neorgcmd"] = {
		-- "Has the same name as our "name" variable had in the "data" table },"
		["neorg-auto-cats.format-cats"] = true,
	},
}

-- i'm not 100% sure because i saw other code that checked the event type
-- however with this modular approach of each neorg command we register
-- being in its own module this doesn't seem necessary
module.on_event = function(event)
	module.private.main(event)
end

return module
