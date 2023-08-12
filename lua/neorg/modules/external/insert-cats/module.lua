--[[
A Neorg module to register an AutoCommand and a Neorg Command
to inject metadata with the relative path from the root 
workspace as categories

It is managed and configured via the auto-cats module.

As per Neorg wiki on core.autocommands using the lua vim.api
over the core.autocommands module
--]]

local module = Neorg.modules.create("external.insert-cats")

module.setup = function()
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
}

module.public = {
}

return module
