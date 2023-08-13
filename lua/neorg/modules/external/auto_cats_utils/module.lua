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
		},
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

	--- Returns a simple set in which you can store simple types
	--- so things like tables will raise an error
	Set = {
		type = nil,

		---@param array table # optional array of elements of 1 type param from which to init the set
		---@return { type: string|nil , new: function, add: function, get: function, remove: function }
		new = function(array, self)
			if type(array) == "table" then -- check the type of each element against self
				---@type string
				for _, elem in pairs(array) do
					self._check_against_set_type(type(elem))

					self.add(elem)
				end
				return self
			elseif type(array == "nil") then
				return self
			else
				error("passed something of type " .. type(array) .. "to Set.new")
			end
		end,

		-- TODO:
		-- where add needs to check element type again and account for
		-- no type being initialized in the elseif type(array == "nil") case
        -- this might benefit from extracting some things out of _check_against_set_type 
		add = function(elem) end,

		includes = function(elem) end,

		remove = function(elem) end,

		-- TODO: fix this type annotation also can't nil be in a set? nahhh
		--
		---@type <boolean|string|number|integer boolean>
		_data = {},

		_accepted_types = { "boolean", "string", "number", "integer" },

		---@param elem_type string
		_check_against_set_type = function(elem_type, self)
			if self.type ~= nil then
				if elem_type ~= self.type then
					error("element in array was of type: " .. elem_type .. "where previous type was: " .. self.type)
				end
			else -- set self.type
				for _, accepted_type in pairs(self._accepted_types) do
					if elem_type == accepted_type then
						self.type = elem_type
					end
				end
				if self.type == nil then
					error(
						"no accepted type was found in the passed array"
							.. "accepted types are: "
							.. self._accepted_types
					)
				end
			end
		end,
	},

	---@return nil|string # to the workspace
	get_workspace = function()
		local dirman = module.required["core.dirman"]

		local workspace = dirman.get_workspace_match()
		if workspace == "default" then
			workspace = dirman.config.public.default_workspace
		end

		return workspace
	end,

	-- As per notes in the readme devdoc section
	-- this is should return a Set and note an Array
	---@param workspace string # neorg workspace name
	---@return Set
	get_workspace_categories = function(workspace)
		-- QUESTION: does this return an array or a set?
		-- + array i think categories can be duplicated
		--   because hierarchical categories
		-- - IF norg categories are deduplicated anyways
		--   it doesn't make so much sense
	end,
}

return module
