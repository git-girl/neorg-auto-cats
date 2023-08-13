--[[
A Neorg module to register an AutoCommand and a Neorg Command
to inject metadata with the relative path from the root
workspace as categories

It is managed and configured via the auto-cats module.

As per Neorg wiki on core.autocommands using the lua vim.api
over the core.autocommands module
--]]

local module = Neorg.modules.create("external.insert_cats")

module.setup = function()
	return {
		success = true,
		requires = {
			"core.esupports.metagen",
			-- "core.dirman",
			"core.integrations.treesitter",
			-- "core.fs",
			"external.auto_cats_utils",
		},
	}
end

module.load = function()
	if module.config.custom.autocmd then
		module.required["external.auto_cats_utils"].register_neorg_command(module.config.private.cmd_table)
	end
end

module.config.private = {
	cmd_table = {
		["insert-cats"] = {
			args = 0,
			condition = "norg",
			name = "neorg-auto-cats.insert-cats",
		},
	},
}

module.private = {
	main = function(buffer, path)
		local metagen = module.required["core.esupports.metagen"]
		local utils = module.required["external.auto_cats_utils"]
		local private = module.private

		local workspace = utils.get_workspace()
		if workspace == nil then
			return
		end

		-- NOTE:control flow:
		--
		--     ✔️ inital metadata: branches internally back to unified thing
		--
		--     update the metadata: WARN: might be nice to consume stuff from different metadata things here
        --     - the thing i think is interesting is the node index -> because maybe you could use that 
        --     to get the categories rather then regexing it
		--
		--     write them

		---@type string[]
		local inital_metadata = private.get_initial_metadata(buffer)
		utils.debug_print(inital_metadata)

        -- this should be a set of strings and i want to get it via tree sitter
        -- then with tree sitter i get  PERF:i want to carry the ts query along
        local inital_metadata_categories

        -- this an array and then you push to the set
        -- WARN: this wouldn't be nice because then you couldn't have 
        -- repeating hierarchical categories 
        -- however that also depends on how neorg does it 
        -- or maybe i can overwrite that
        local workspace_categories = utils.get_workspace_categories(workspace)

        -- update_metadata_with_cats

		-- TODO:
		-- local categories = private.get_categories(path, workspace)
		-- private.update_metdata_with_cats(inital_metadata, categories)
		-- vim.api.nvim_buf_set_lines(buffer, metadata_node.range[1], meta.range[2], false, metadata)
	end,

	-- Needs to match the return of metagen.construct_metadata(buffer)
    -- in all paths it takes
	---@param buffer number # Buffer for which to get the metadata
	---@return string[]
	get_initial_metadata = function(buffer)
		local metagen = module.required["core.esupports.metagen"]

		---@type string[]
		local inital_metadata = {}

		---@type boolean, { node: TSNode, range: number[] }
		local metadata_present, metadata_ranged_verbatim_tag = metagen.is_metadata_present(buffer)

		if metadata_present then
            -- this could call metagen.get_metadata
            --
            -- also it could use the actual metadata parser but since we only want to write it 
            -- and not do stuff here the base norg parser is just fine (maybe dodging the string
            -- comparison would be faster though)

			-- this holds the node that can be itered to iter through
			-- the base norg ts parser array consisting out of paragraph_segment s
			-- and _line_break s
			---@type TSNode
			local metadata_ranged_verbatim_tag_content = metadata_ranged_verbatim_tag.node:field("content")[1]:child(0)

			for node in metadata_ranged_verbatim_tag_content:iter_children() do
				if node:type() == "paragraph_segment" then
					table.insert(inital_metadata, vim.treesitter.get_node_text(node, buffer, nil))
				end
			end

			-- fully match metagen.construct_metadata in adding the end and start line here as well
			table.insert(inital_metadata, 1, "@document.metadata")
			-- default is insert at n + 1 so this is all good
			table.insert(inital_metadata, "@end")
			table.insert(inital_metadata, "")
		else
			inital_metadata = metagen.construct_metadata(buffer)
		end

		return inital_metadata
	end,

	get_categories = function(path, workspace)
		path = module.private.cut_path_before_workspace(path, workspace)
		path = string.gsub(path, "/", " ")
		-- remove everything after the last space
		local categories = string.gsub(path, "%s[^%s]*$", "")

		return categories
	end,

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

	register_insert_cats_autocmd = function()
		-- TODO: check how to properly add the aucomand group
		--
		-- local autocats_augroup = vim.api.nvim_create_augroup("NeorgAutoCats", { clear = false })

		vim.api.nvim_create_autocmd({ "BufEnter" }, {
			desc = "Inject Metadata into Neorg file if not there, use directories for categories",
			pattern = { "*.norg" },
			callback = function(event)
				module.private.main(event.buf, event.file)
			end,
		})
	end,
}

module.public = {}

module.events.subscribed = {
	["core.neorgcmd"] = {
		-- "Has the same name as our "name" variable had in the "data" table },"
		["neorg-auto-cats.insert-cats"] = true,
	},
}

-- i'm not 100% sure because i saw other code that checked the event type
-- however with this modular approach of each neorg command we register
-- being in its own module this doesn't seem necessary
module.on_event = function(event)
	module.private.main(event.buffer, event.filehead .. "/" .. event.filename)
end

return module
