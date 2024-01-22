--[[
    A Neorg module to manage and configure the other modules
    of this plugin.

    This modules hands it's private and custom config over to the modules
    it loads which is then accessible like so:
    other_module.config.custom.public
    -> so you just prepend custom to the public thing

    i might also add the private config later if it makes sense
    to share more config across all plugins but this way
    the table seemed to be much less simple

    TODO: add doc comments i think thats stuff like ---@return string

    TODO: handle the read only case properly

    NOTE: REFACTOR:

    Files to extract into:
    - lua/neorg/auto_cats_shared_utils.lua   <-- shared utils go here
    - lua/neorg/modules/external/auto-cats   <-- entry for global config and stuff like that
    - lua/neorg/modules/external/insert-cats <-- thing for the core of auto-cats currently
    - lua/neorg/modules/external/format-cats <-- thing for the new generate workspace summary command

    BUG: i think there is a bug in switching between workspaces
    like i did one insert-cats that was fine
    then switch workspace in one readonly that was fine
    then switched back to the first one and that broke
--]]

Neorg = require("neorg.core")

local module = Neorg.modules.create("external.auto-cats")

-- module.config.private = { test = "test" }

module.config.public = {
	-- this flag sets whether we autosave as part of the
	-- autocomand.
	-- i think this is useful and not having it leads
	-- to many buffers that are being written to and you
	-- having to save manually which i don't like.
	-- it's not the default because i think saving
	-- files is evil.
	autosave = false,
	-- this flag sets wheter we register an autocmd to
	-- insert the categories on default.
	-- the workflow for having this as false probably
	-- includes some keybind to quickly insert categories
	-- when you want.
	autocmd = true,

	-- TODO: consider adding config for categories: so you
	-- can do something like this category implies this table
	-- of other categories
	-- my linux category should then also always add { "beep", "boop", "catgirls" }
}

function module.setup()
	return { success = true }
end

module.private = {
	-- returns true or false
	cut_path_before_workspace = function(path, workspace)
		-- TODO: check if this needs to escape characters
		-- but i don't think so
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
		local categories = module.private.get_categories(path, workspace)

		if not metadata_exists then
			local constructed_metadata = module.required["core.esupports.metagen"].construct_metadata(buffer)
			constructed_metadata = module.private.set_categories(constructed_metadata, categories)

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

		if module.config.public.autosave then
			-- i'm not all to sure about this here because what
			-- happens if some macro races this and then we
			-- get writes to the wrong buffer no?
			vim.cmd.write({ bang = false })
		end
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

	-- TODO: debug this inserting so damn much config
	-- like the print at the top of module.load() body
	-- is so much less and then the debug from main is
	-- super hardcore
	-- its not even that its about loaded modules
	-- because In auto_cats main the thing is also much
	-- more limited
	-- NOTE: maybe the issue is that i'm not matching the
	-- config in the format of:
	-- `neorg.config.user_config.load["module.name"].config`
	-- but i couldn't find anything in that direction
	-- NOTE: imma just leave it as is atm because i think
	-- i can go on and fix this later
	setup_other_module = function(name)
		Neorg.modules.load_module(name, module.config.public)
	end,
}

function module.load()
	-- vim.print(vim.inspect(module.config))
	module.private.setup_other_module("external.format_cats")
	module.private.setup_other_module("external.insert_cats")
end

return module
