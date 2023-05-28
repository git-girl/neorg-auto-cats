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
			"core.esupports.metagen",
			"core.dirman",
			"core.integrations.treesitter",
		},
	}
end

module.private = {
	enabled = true,

	-- returns true or false
	get_existing_metadata = function(buffer)
		return module.required["core.esupports.metagen"].is_metadata_present(buffer)
	end,

	cut_path_before_workspace = function(path, workspace)
		index = string.find(path, workspace)
		path = string.sub(path, index)
		return path
	end,

	get_categories = function(path, workspace)
		path = module.private.cut_path_before_workspace(path, workspace)
		path = string.gsub(path, "/", " ")
		-- remove everything after the last space
		categories = string.gsub(path, "%s[^%s]*$", "")

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
		content = module.required["core.integrations.treesitter"].get_document_metadata(buffer)
		return content
	end,

	-- TODO: refactor into smaller methods
	get_updated_categories = function(metadata, new_categories)
		-- handle_nil_categories()
		existing_categories = metadata.categories

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

		updated_categories = existing_categories
		del_space_flag = false
		for new_cat in new_categories:gmatch("%S+") do
			if not existing_categories_table[new_cat] then
				updated_categories = updated_categories .. new_cat .. " "
				del_space_flag = true
			end
		end
		if del_space_flag then
			updated_categories = updated_categories:sub(1, -2)
		end

		return updated_categories
	end,

	main = function(buffer, path)
		metadata_exists, data = module.private.get_existing_metadata(buffer)
		-- only if there is a workspace defined
		workspace = module.required["core.dirman"].get_workspace_match()
		-- TODO: find  a way  to resolve default workspace name and do some extra checks there

		if workspace == "default" then
      return
		end

		categories = module.private.get_categories(path, workspace)

		if not metadata_exists then
			constructed_metadata = module.required["core.esupports.metagen"].construct_metadata(buffer)
			constructed_metadata = module.private.set_categories(constructed_metadata, categories)
      print(vim.inspect(constructed_metadata))

			vim.api.nvim_buf_set_lines(buffer, data.range[1], data.range[2], false, constructed_metadata)
		else
			-- i would say it should update it regardeless but i think this goes against the
			-- neorg design of the metagen module having to be used explicitly and not overwriting so aggressively
			-- module.required["core.esuppports.metagen"]

			content = module.private.get_existing_metadata_content(buffer)
			updated_categories = module.private.get_updated_categories(content, categories)

      -- use treesitter to update the metadata info
      -- LanguageTree:named_node_for_range

      -- category_node = vim.treesitter.execute_query( TODO: )

      -- vim.treesitter.get_node_range(category_node)

      -- vim.api.nvim_buf_set_text(buffer, start_row, start_col, end_row, end_col, updated_categories)
		end
	end,
}

function module.load()
	-- TODO: check how to properly add the aucomand group
	autocats_augroup = vim.api.nvim_create_augroup("NeorgAutoCats", { clear = false })

	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		desc = "Inject Metadata into Neorg file if not there, use directories for categories",
		pattern = { "*.norg" },
		callback = function(ev)
			buffer = ev.buf
			path = ev.file
			module.private.main(buffer, path)
		end,
	})
end

return module
