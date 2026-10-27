# Macroassembler AS (asl, p2bin); the released patch is built with 1.42 Beta.
ASL ?= asl
P2BIN ?= p2bin
PATCH := build/microwave-xt.xtpatch
SOURCES := $(shell find src -name '*.asm' -o -name '*.inc') src/patch_layout.json
.PHONY: all check release clean
all: $(PATCH)
$(PATCH): $(SOURCES) VERSION tools/make_patch.py tools/edition_version.py
	python3 tools/make_patch.py $@ --asl '$(ASL)' --p2bin '$(P2BIN)'
# With XT_STOCK_UPDATE set to Waldorf's OS v2.33 update, the browser patcher applies it under Node.
check: $(PATCH)
	python3 tools/check_patch.py $(PATCH) $(XT_STOCK_UPDATE)
release: $(PATCH) web/patcher.mjs web/app.mjs web/patcher.template.html
	@test -n "$(XT_STOCK_UPDATE)" || { echo "Set XT_STOCK_UPDATE to Waldorf's OS v2.33 update" >&2; exit 1; }
	python3 tools/package_release.py "$(XT_STOCK_UPDATE)"
clean:
	rm -rf build
