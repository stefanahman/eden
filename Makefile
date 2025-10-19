.PHONY: help install update doctor status clean arch mac

# Detect OS for platform-specific targets
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
	@echo "  make install    Bootstrap Eden on a fresh system"
	@echo "  make update     Update Eden from git and re-deploy"
	@echo "  make doctor     Validate Eden installation health"
	@echo "  make status     Show Eden system overview (not yet implemented)"
	@echo "  make clean      Remove all Eden symlinks from \$$HOME"
	@echo "  make arch       Deploy common + arch packages only"
	@echo "  make mac        Deploy common + mac packages only"

install:
	@./install.sh

update:
	@./update.sh

doctor:
	@./doctor.sh

status:
	@echo "Status command not yet implemented"
	@echo "Run 'make doctor' for health check"

clean:
	@echo "Removing Eden symlinks..."
	@stow -D -t $(HOME) -d packages common $(OS) 2>/dev/null || true
	@echo "✓ Eden symlinks removed"

arch:
	@stow -v -t $(HOME) -d packages common arch

mac:
	@stow -v -t $(HOME) -d packages common mac

