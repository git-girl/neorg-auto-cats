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
			-- "core.integrations.treesitter",
			-- "core.fs",
			"external.auto_cats_utils",
		},
	}
end

module.load = function()
	if module.config.custom.autocmd then
		module.required["external.auto_cats_utils"].register_neorg_command(module.config.private.cmd_table)
	end

	-- module.required["external.auto_cats_utils"].debug_print(module.config.custom)
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

		-- WARN: i do end up doing similar things for both branches
		-- of the if
		-- local categories
		-- if not metadata:
		--     inital metadata: metagen.construct_metadata(buffer)
		--     update the metadata
		--     write them
		--  else:
		--      inital metadata: get_existing_metadata_content
		--      updatae the metadata
		--      write them

		-- this constructs metadata maybe i could be doing more stuff
		-- already here or save those results better
		local metadata_present, metadata_node = metagen.is_metadata_present(buffer)
        utils.debug_print(
        {
            metadata_present,
            metadata_node,
            metadata_node.node:child_count(),
            vim.treesitter.get_node_text(metadata_node.node, buffer),
        })

		local inital_metadata
		if metadata_present then
			-- NOTE: rather then this treesitter thing i could also maybe use
			-- the metadata_node better
			-- utils.debug_print(metadata_node.node)
			-- userdata is a c pointer to a TSNode
            --
			--  local query = utils.ts_parse_query(
			--     "norg",
			--     [[
			--          (ranged_verbatim_tag
			--              (tag_name) @name
			--              (#eq? @name "document.meta")
			--          ) @meta
			--     ]]
			-- )
			-- local _, found = query:iter_matches(root, buf)()
			--        for id, node in pairs(found) do
            --  NOTE: 
            --  the node is a c pointer userdata thingy so i can hardly ask it things
            -- get_document_metadata calls utils.ts_parse_query
            -- which calls the vim.treesitter.query.parse() version agnostically
            -- but that returns a Query (lua-treesitter-query)
            -- then it calls itermatches on the query
            -- TODO: rather then using the integrations.treesitter i just wanna get something that 
            -- matches what construct metadata returns (probs a table)
            -- -> iterate children insert into table
			inital_metadata = module.required["core.integrations.treesitter"].get_document_metadata(buffer)
		else
			inital_metadata = metagen.construct_metadata(buffer)
		end

		local categories = private.get_categories(path, workspace)

		private.update_metdata_with_cats(inital_metadata, categories)

		-- vim.api.nvim_buf_set_lines(buffer, metadata_node.range[1], meta.range[2], false, metadata)
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
