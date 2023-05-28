update_dev: 
	@mkdir -p ~/.local/share/nvim/site/pack/packer/start/neorg-auto-cats
	@cp -r ./lua/neorg/modules/external/auto-cats/module.lua ~/.local/share/nvim/site/pack/packer/start/neorg-auto-cats/lua/neorg/modules/external/auto-cats/module.lua	
	@echo 'updated module.lua'

format: 
	stylua -v --verify .
