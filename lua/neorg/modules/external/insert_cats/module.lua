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

		local inital_metadata = private.get_initial_metadata(buffer)
		-- utils.debug_print(inital_metadata)

		-- TODO:
		-- local categories = private.get_categories(path, workspace)
		-- private.update_metdata_with_cats(inital_metadata, categories)
		-- vim.api.nvim_buf_set_lines(buffer, metadata_node.range[1], meta.range[2], false, metadata)
	end,

    -- Needs to match the output of metagen.construct_metadata(buffer) in all cases:
    -- so something like:
			-- {
			-- "@document.meta",
			-- "title: index",
			-- "description: ",
			-- "authors: cherry-cat",
			-- "categories: ",
			-- "created: 2023-08-13",
			-- "updated: 2023-08-13",
			-- "version: 1.1.1",
			-- "@end",
			-- ""
			-- }
    ---@return string[]
	get_initial_metadata = function(buffer)
		local metagen = module.required["core.esupports.metagen"]
		local utils = module.required["external.auto_cats_utils"]

		---@type string[]
		local inital_metadata = {}

		--  TODO: this type annotation
		--  metadata_node = node
		-- range[1], _, range[2], _ = node:range()
		-- range[2] = range[2] + 2
		-- return true, {
		--            range = range,
		--            node = metadata_node,
		--        }
		local metadata_present, metadata_ranged_verbatim_tag = metagen.is_metadata_present(buffer)

		-- more specifically this is always %2 = 0
		-- @type integer
		-- local child_count = metadata_ranged_verbatim_tag_content:child_count()

		-- the 'true' treesitter nodes from the base norg parser that are the
		-- simple paragraph strings are at the end so we get the second half
		-- of the array
		-- @type integer
		-- local plain_true_ts_nodes_start_index = child_count - child_count / 2
		-- WARN: i don't think that the true ts nodes are ordered in
		-- the table in a specific way i get 1 0 1 0 1 0 ... for the
		-- child counts when iterating over the entire table
		-- maybe the true nodes are defined via not having children

		-- for i = 0, child_count - 1, 1 do
			-- @type TSNode
			-- local plain_true_ts_metadata_node = metadata_ranged_verbatim_tag_content:child(i)

			-- utils.debug_print(vim.treesitter.get_node_text(plain_true_ts_metadata_node))
			-- utils.debug_print(plain_true_ts_metadata_node:child_count())
			-- this is for the later half of the array
			-- 0
			-- 1
			-- 0
			-- 1
			-- 0
			-- 1
			-- 0
		-- end

		if metadata_present then
			-- WARN: the first return is a table of one element so
			-- need to retrieve its first elem then its a node with 1 child
			-- with 1 child that wraps the actual array of nodes
			-- that array is contains each node TWICE
			-- first the injected language nodes
			-- (remember meta and base norg each have their own ts parsers)
			-- then second the 'true' treesitter nodes
			--
			-- this contains the node that can be itered to iter through
			-- the duplicated array
			---@type TSNode
			local metadata_ranged_verbatim_tag_content = metadata_ranged_verbatim_tag.node:field("content")[1]:child(0)

			for node, _ in metadata_ranged_verbatim_tag_content:iter_children() do
				if node:type() == "paragraph_segment" then
					table.insert(inital_metadata, vim.treesitter.get_node_text(node, buffer, nil))
				end
			end

            -- fully match metagen.construct_metadata in adding the end and start line here as well
            table.insert(inital_metadata, 1, "@document.metadata")
            -- default is insert at n + 1 so this is all good
            table.insert(inital_metadata, "@end")
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
