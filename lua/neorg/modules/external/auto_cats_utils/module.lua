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

	-- Returns a simple set in which you can store simple types
	-- so things like tables will raise an error
	---@class Set
	---@field type nil|string
	---@field data table<boolean|string|number|integer, boolean>,
	---@field add function,
	---@field get function
	---@field remove function
	Set = {
		-- constructor for Set
		---@param array? table # optional array of elements of 1 type param from which to init the set
		---@return Set
		new = function(array)
			---@type {type: nil|string, data: table<boolean|string|number|integer, boolean>}
			local self = {
				type = nil,

				data = {},
			}

			---@type string[]
			local accepted_types = { "boolean", "string", "number", "integer" }

			-- Adds the element to the set, If Set has been initialized with a type then the element
			-- must be of that type.
			-- Checking against nil type as elem is important otherwise you get actual type "nil" Set
			---@param elem boolean|string|number|integer # if set type is not nil must be of set type
			---@return Set
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

			---@param requested_elem any # but only accepted types really make sense
			---@return boolean # whether or not the element is included in the set
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
			---@return Set
			self.remove = function(requested_elem, error)
				if type(requested_elem) ~= self.type then
					error(
						"element in array was of type: "
							.. type(requested_elem)
							.. " where previous type was: "
							.. self.type
					)
				end

				local raise_error = true
				if error == false then
					raise_error = false
				end

				for _, set_elem in ipairs(self.data) do
					if set_elem == requested_elem then
						-- this is safe because error checked before hand
						-- could also fail here but this way its a bit nicer
						---@diagnostic disable-next-line: param-type-mismatch
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

				-- return self for the case that turned off error behavior
				return self
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

	-- Error if can't find WS and else return
	-- the full path
	---@return string
	get_workspace_path = function(workspace) end,

	-- As per notes in the readme devdoc section
	-- this is should return a Set and not an Array
	-- think of (filepath - workspace_root) as a Set
	---@param path string # filepath
	---@param workspace_name string # neorg workspace name
	---@return Set
	get_workspace_categories = function(path, workspace_name)
		-- this will always return a path because of the default workspace behavior
		local workspace_path = module.required["core.dirman"].get_workspaces()[workspace_name]
		-- thing after the last / (doesn't need to be the same as the name so its good to fetch for stability)
		-- TODO: test this by having a { Test: '/tmp/test' } kinda mapping
		local workspace_dir = string.match(workspace_path, "[^/]+$")

		local index = string.find(path, workspace_dir)
		if index == nil then
			-- TODO: err msg
			error()
		end

		-- TODO: this here and the thing below should just be made into something that
		-- can get slices of a table and maybe also something
		local split_path = vim.split(string.sub(path, index), "/", { trimempty = true })
		local cats = {}
		local len = #split_path
		for i, value in ipairs(split_path) do
			if i ~= len then -- skip the last elem
				table.insert(cats, #cats + 1, value)
			end
		end

		return module.public.Set.new(cats)
	end,

	---@param inital_metadata string[]
	---@return string[]
	parse_out_cats_from_metadata = function(inital_metadata)
		for i, line in ipairs(inital_metadata) do
            -- NOTE: that 'categories:A' isnt valid in the treesitter so 
            -- it would be okay to say we just split on \s but its nice to
            -- do the extra step so that when someone makes a mistake we 
            -- actually can catch it for them
            -- and this way we can not do the whole iter table and push into it thing
			if vim.startswith(line, "categories:") then
                local x = vim.split(line, ":", {trimempty = true})
                local cat_str = table.remove(x, #x) -- last elem

				local cats = vim.split(cat_str, " ", { trimempty = true })
                return cats
			end
		end
        return {}
	end,

	-- cut_path_before_workspace = function(path, workspace)
	-- 	check if this needs to escape characters
	-- 	-- but i don't think so
	-- 	local index = string.find(path, workspace)
	-- 	if not index then
	-- 		vim.api.nvim_err_writeln([[
	--            Couldn't find Workspace Name in Path.
	--
	--            ]])
	-- 		return
	-- 	end
	-- 	path = string.sub(path, index)
	-- 	return path
	-- end,
	--
	-- get_categories = function(path, workspace)
	-- 	path = module.private.cut_path_before_workspace(path, workspace)
	-- 	path = string.gsub(path, "/", " ")
	-- 	-- remove everything after the last space
	-- 	local categories = string.gsub(path, "%s[^%s]*$", "")
	--
	-- 	return categories
	-- end,
}

return module
