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
		---@param array table # optional array of elements of 1 type param from which to init the set
		---@return { type: string|nil , new: function, add: function, get: function, remove: function }
		new = function(array)
			---@type {type: nil|string, data: table<boolean|string|number|integer, boolean>}
			local self = {
				type = nil,

				data = {},
			}

			---@type string[]
			local accepted_types = { "boolean", "string", "number", "integer" }

			-- TODO:
			-- where add needs to check element type again and account for
			-- no type being initialized in the elseif type(array == "nil") case
			-- this might benefit from extracting some things out of _check_against_set_type
			self.add = function(elem)
				local elem_type = type(elem)

				if self.type == nil then
					if elem_type ~= "nil" then
						self.type = elem_type
					else
						error(
							"Set.add: tried to add nil to empty Set without a type, pass one of "
								.. table.concat(accepted_types, ", ")
						)
					end
				end

				if elem_type == self.type then
					table.insert(self.data, elem)
				else
					error("Set.add: type of elem was: " .. elem_type .. " type of Set is: " .. self.type)
				end

				return self
			end

			self.includes = function(requested_elem)
				for _, set_elem in ipairs(self.data) do
					if set_elem == requested_elem then
						return true
					end
				end
				return false
			end

			---@param requested_elem boolean|string|number|integer # The element to remove
			---@param error boolean # Default: true, Whether or not to raise an error if the element isn't included
			self.remove = function(requested_elem, error)
				local raise_error = true
				if error == false then
					raise_error = false
				end

				for _, set_elem in ipairs(self.data) do
					if set_elem == requested_elem then
						table.remove(self.data, requested_elem)
						return self
					end
				end

				if raise_error then
					error(
						"Set.remove: element: "
							.. requested_elem
							.. " wasn't found in: "
							.. self.data
							.. " pass error=true to remove to disable this error"
					)
				end
			end

			---@param elem_type string
			local check_against_set_type = function(elem_type)
				if self.type ~= nil then
					if elem_type ~= self.type then
						error(
							"element in array was of type: " .. elem_type .. " where previous type was: " .. self.type
						)
					end
				else -- set self.type
					for _, accepted_type in pairs(accepted_types) do
						if elem_type == accepted_type then
							self.type = elem_type
						end
					end
					if self.type == nil then
						error(
							"no accepted type was found in the passed array"
								.. " accepted types are: "
								.. table.concat(accepted_types, ", ")
						)
					end
				end
			end

			if type(array) == "table" then -- check the type of each element against self
				---@type string
				for _, elem in pairs(array) do
					check_against_set_type(type(elem))

					self.add(elem)
				end
				return self
			elseif type(array == "nil") then
				return self
			else
				error("passed something of type " .. type(array) .. "to Set.new")
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
