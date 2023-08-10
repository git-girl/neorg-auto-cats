--[[
A Neorg module to register an AutoCommand to inject metadata
with the relative path from the root workspace as categories

As per Neorg wiki on core.autocommands using the lua vim.api over the core.autocommands module
--]]

-- TODO: make everything stable

local neorg = require("neorg.core")

local module = neorg.modules.create("external.auto-cats")

function module.setup()
	return {
		success = true,
		requires = {
			"core.esupports.metagen",
			"core.dirman",
			"core.integrations.treesitter",
			"core.neorgcmd",
			"core.fs",
		},
	}
end

module.private = {
	enabled = true,

	-- returns true or false
	check_for_existing_metadata = function(buffer)
		return module.required["core.esupports.metagen"].is_metadata_present(buffer)
	end,

	cut_path_before_workspace = function(path, workspace)
		local index = string.find(path, workspace)
		if not index then
			vim.api.nvim_err_writeln([[
      Couldn't find Workspace Name in Path.
      Sorry but you need to name your Workspace the same as your
      Workspace Directory.
      ]])
			return
		end
		path = string.sub(path, index)
		return path
	end,

	get_categories = function(path, workspace)
		path = module.private.cut_path_before_workspace(path, workspace)
		path = string.gsub(path, "/", " ")
		-- remove everything after the last space
		local categories = string.gsub(path, "%s[^%s]*$", "")

		return categories
	end,

	set_categories = function(constructed_metadata, categories)
		for index, element in ipairs(constructed_metadata) do
			if element:match("^categories:") then
				constructed_metadata[index] = "categories: " .. categories
			end
		end
		return constructed_metadata
	end,

	get_existing_metadata_content = function(buffer)
		local content = module.required["core.integrations.treesitter"].get_document_metadata(buffer)
		return content
	end,

	-- TODO: refactor into smaller methods
	get_updated_categories = function(metadata, new_categories)
		-- handle_nil_categories()
		local existing_categories = metadata.categories

		if existing_categories == vim.NIL then
			existing_categories = ""
		end

		-- Case there are actual categories to be updated
		-- From new_categories subtract any matches with existing categories
		-- string_to_included_table()
		local existing_categories_table = {}
		for exisiting_cat in existing_categories:gmatch("%S+") do
			existing_categories_table[exisiting_cat] = true
		end

		local updated_categories = existing_categories
		for new_cat in new_categories:gmatch("%S+") do
			if not existing_categories_table[new_cat] then
				updated_categories = updated_categories .. " " .. new_cat
			end
		end

		return "categories: " .. updated_categories
	end,

	-- Copy pasted from metagen module
	get_meta_root = function()
		local languagetree = vim.treesitter.get_parser(buf, "norg")
		if not languagetree then
			return
		end
		local meta_root = nil

		languagetree:for_each_child(function(tree)
			if tree:lang() ~= "norg_meta" or meta_root then
				return
			end

			local meta_tree = tree:parse()[1]

			if not meta_tree then
				return
			end

			meta_root = meta_tree:root()
		end)

		if not meta_root then
			return
		end
		return meta_root
	end,

	auto_cat_main = function(buffer, path)
		local metadata_exists, data = module.private.check_for_existing_metadata(buffer)
		-- only if there is a workspace defined
		local workspace = module.required["core.dirman"].get_workspace_match()
		-- TODO: find a way  to resolve default workspace name and do some extra checks there
		-- FIX: an option would be to use get_workspace to get at the path of the default
		-- i think jsut using that path would also make things easier here

		if workspace == "default" then
			return
		end

		local categories = module.private.get_categories(path, workspace)

		if not metadata_exists then
			local constructed_metadata = module.required["core.esupports.metagen"].construct_metadata(buffer)
			local constructed_metadata = module.private.set_categories(constructed_metadata, categories)

			vim.api.nvim_buf_set_lines(buffer, data.range[1], data.range[2], false, constructed_metadata)
		else
			-- i would say it should update it regardeless but i think this goes against the
			-- neorg design of the metagen module having to be used explicitly and not overwriting so aggressively
			-- module.required["core.esuppports.metagen"]

			local content = module.private.get_existing_metadata_content(buffer)
			local updated_categories = module.private.get_updated_categories(content, categories)

			local query = vim.treesitter.query.get("norg_meta", "highlights")
			local meta_root = module.private.get_meta_root()
			if not meta_root then
				return
			end

			local start_row, start_col, end_row, end_col = nil

			-- returns pattern id, match, metadata  only need matches
			for _, match in query:iter_matches(meta_root, buffer) do
				for id, node in pairs(match) do
					local name = query.captures[id]
					if node:type() == "key" then
						local text = vim.treesitter.get_node_text(node, buffer, {})
						if text == "categories" then
							start_row, _, end_row = vim.treesitter.get_node_range(node)
						end
					end
				end
			end

			-- replace line updated categories
			vim.api.nvim_buf_set_lines(buffer, start_row, start_row + 1, false, { updated_categories })
		end
	end,

	-- INFO: THIS IS THE FORMAT COMMAND STUFF

	format_categories_main = function(buffer)
		local workspace = module.required["core.dirman"].get_current_workspace()
		local ws_path = workspace[2]

		-- TODO: left of at this kinda working but I need a thing
		-- to ignore all hidden .dirs like .git
        -- and i need to ignore all dirs defined in gitignore
		print(vim.inspect(module.private.directory_map(ws_path)))
		-- TODO: take this and then match the top level names against things in cats
		-- voila proper hierarchy cats

		-- module.private.directory_map(workspace)
	end,

	directory_map = function(path)
		local directories = {}

		local function exploreDirectory(subPath)
			for name, type in vim.fs.dir(subPath) do
				if type == "directory" then
					local dirPath = subPath .. "/" .. name
					table.insert(directories, dirPath)
					exploreDirectory(dirPath)
				end
			end
		end

		exploreDirectory(path)

		return directories
	end,

	format_categories_cmd_table = {
		["format-cats"] = {
			args = 0,
			condition = "norg",
			name = "neorg-auto-cats.format-cats",
		},
	},

	-- end module private
}

function module.load()
	-- TODO: check how to properly add the aucomand group
	local autocats_augroup = vim.api.nvim_create_augroup("NeorgAutoCats", { clear = false })

	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		desc = "Inject Metadata into Neorg file if not there, use directories for categories",
		pattern = { "*.norg" },
		callback = function(ev)
			local buffer = ev.buf
			local path = ev.file
			module.private.auto_cat_main(buffer, path)
		end,
	})

	-- not a user command but register the command as a Neorg command
	module.required["core.neorgcmd"].add_commands_from_table(module.private.format_categories_cmd_table)
	-- listen to the event
	module.events.subscribed = {
		["core.neorgcmd"] = {
			["neorg-auto-cats.format-cats"] = true, -- Has the same name as our "name" variable had in the "data" table },
		},
	}
end

function module.on_event(event)
	if event.type == "core.neorgcmd.events.neorg-auto-cats.format-cats" then
		module.private.format_categories_main(event.buffer, event.filehead)
	end
end

return module
