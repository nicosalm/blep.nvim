NVIM = $(shell which nvim 2>/dev/null || which /opt/homebrew/bin/nvim 2>/dev/null || which /Users/nicosalm/dev/nvim-macos-arm64/bin/nvim 2>/dev/null || echo "nvim")
GREEN = \033[32m
BLUE = \033[34m
BOLD = \033[1m
RESET = \033[0m

.PHONY: test lint clean

test:
	@if [ ! -x "$$(command -v $(NVIM))" ]; then \
		printf "$(BOLD)Error: nvim not found in PATH$(RESET)\n"; \
		exit 1; \
	fi
	@printf "$(BLUE)Running tests...$(RESET)\n"
	@$(NVIM) --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/blep/ {minimal_init = 'tests/minimal_init.lua'}" || \
		(printf "$(BOLD)Tests failed!$(RESET)\n" && exit 1)
	@printf "$(GREEN)$(BOLD)All tests passed!$(RESET)\n"

lint:
	@printf "$(BLUE)Linting with Luacheck...$(RESET)\n"
	@luacheck . || (printf "$(BOLD)Lint failed!$(RESET)\n" && exit 1)
	@printf "$(GREEN)$(BOLD)Lint passed!$(RESET)\n"

clean:
	@printf "$(BLUE)Cleaning...$(RESET)\n"
	@rm -rf .luacheckcache
	@printf "$(GREEN)$(BOLD)Clean complete!$(RESET)\n"
