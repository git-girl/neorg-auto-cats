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

	remove_file_name_from_path = function(path)
		-- local fileName = path:match("/([^/]+)$")
		-- if fileName then
		--   trimmedPath = trimmedPath:gsub("/" .. fileName, "")
		-- end
		-- return trimmedPath
	end,

	cut_path_before_workspace = function(path, workspace)
		index = string.find(path, workspace)
		path = string.sub(path, index)
		return path
	end,

	get_categories = function(path)
		workspace = module.required["core.dirman"].get_workspace_match()

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

	-- NOTE: This should ideally be constructed in the same way that metagen module is using TS
	get_existing_metadata_content = function(buffer)
		-- WARNING: there is a bug here that on empty lines for categories the next line gets retrieved
		-- @document.meta
		-- title: index
		-- description:
		-- authors: cherry-cat
		-- categories:
		-- created: 2023-05-23
		-- updated: 2023-05-28
		-- version: 1.1.1
		-- @end
		-- RETURNS:
		--{
		--   categories = "created: 2023-05-23",
		--   description = "authors: cherry-cat",
		--   title = "index",
		--   updated = "2023-05-28",
		--   version = "1.1.1"
		-- }
		content = module.required["core.integrations.treesitter"].get_document_metadata(buffer)
		print(vim.inspect(content))
		return content
	end,

	update_categories = function(constructed_metadata, categories) end,
	-- if categoriesIndex then
	--   local currentCategories = constructed_metadata[categoriesIndex]
	--   print(categories)
	--   local newCategories = currentCategories .. categories
	--
	--   constructed_metadata[categoriesIndex] = newCategories
	-- end
	main = function(buffer, path)
		metadata_exists, data = module.private.get_existing_metadata(buffer)
		categories = module.private.get_categories(path)

		if not metadata_exists then
			constructed_metadata = module.required["core.esupports.metagen"].construct_metadata(buffer)
			constructed_metadata = module.private.set_categories(constructed_metadata, categories)

			vim.api.nvim_buf_set_lines(buffer, data.range[1], data.range[2], false, constructed_metadata)
		else
			-- i would say it should update it regardeless but i think this goes against the
			-- neorg design of the metagen module having to be used explicitly and not overwriting so aggressively
			-- module.required["core.esuppports.metagen"]

			print(vim.inspect(vim.treesitter.get_parser(buffer, "norg")))
			content = module.private.get_existing_metadata_content(buffer)
			categories = content.categories
			if categories then
			end

			-- get the meta data that exists
			-- categories = already contained categories + any categories in path that arent contained already
			-- set_categories
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
