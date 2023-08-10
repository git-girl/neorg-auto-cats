update_dev: 
	@mkdir -p ~/.local/share/nvim/lazy/neorg-auto-cats/lua
	@cp -r ./lua/* ~/.local/share/nvim/lazy/neorg-auto-cats/lua
	@echo 'updated module.lua'

format: 
	stylua -v --verify .
