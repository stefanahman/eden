.PHONY: help install update doctor status clean graft

# Detect OS for clean target
UNAME := $(shell uname -s)
ifeq ($(UNAME),Linux)
	OS := arch
endif
ifeq ($(UNAME),Darwin)
	OS := mac
endif

help:
	@echo "Eden - Personal Environment Manager"
	@echo ""
	@echo "Usage:"
	@echo "  make install        Bootstrap Eden wrapper (no stow required)"
	@echo "  make update         Update Eden from git and re-apply configs"
	@echo "  make doctor         Validate Eden installation health"
	@echo "  make graft          Graft branch configs into local gitconfig"
	@echo "  make status         Show Eden system overview"
	@echo "  make clean          Remove all Eden symlinks from \$$HOME"
	@echo ""
	@echo "Bootstrap workflow:"
	@echo "  ./install.sh        # Install eden wrapper (no dependencies)"
	@echo "  eden install        # Install packages (includes GNU Stow)"
	@echo "  eden plant          # Plant configs (wraps stow with checks)"
	@echo "  eden doctor         # Validate installation"

install:
	@./install.sh

update:
	@./update.sh

doctor:
	@./doctor.sh

graft:
	@./graft.sh

status:
	@echo "Status command not yet implemented"
	@echo "Run 'make doctor' for health check"

clean:
	@echo "Unplanting Eden configs..."
	@stow -D -t $(HOME) -d packages common $(OS) 2>/dev/null || true
	@echo "✓ Eden configs unplanted"
