CURL = curl -fL --retry 3 --connect-timeout 15

FRONTEND_URL = https://buildbot.libretro.com/assets/frontend
FRONTEND_ZIPS = assets autoconfig cheats database-cursors database-rdb \
	glui_minimal_assets info overlays shaders_cg shaders_glsl shaders_slang

.PHONY: build clean update frontend FORCE

# Drop partially-downloaded targets when curl fails.
.DELETE_ON_ERROR:

build: src/system/README.md frontend
	./build.sh

clean:
	rm -rf public/frontend public/system
	find public -type f -name .index -delete
	find public -type f -name .index-dirs -delete
	find public -type f -name .index-extended -delete

# Refresh in place: never removes served files, only re-downloads changed zips.
update: build

src/system/README.md:
	git submodule update --init

frontend: $(FRONTEND_ZIPS:%=public/frontend/%.zip)

public/frontend:
	mkdir -p public/frontend

# Always check upstream, but only download when newer than the local copy
# (-z). Download to a hidden temp file, then swap it in only if something
# was received, so the served zip is never removed or truncated.
public/frontend/%.zip: FORCE | public/frontend
	$(CURL) $(if $(wildcard $@),-z "$@") -R -o "$(@D)/.$(@F).part" "$(FRONTEND_URL)/$*.zip"
	if [ -s "$(@D)/.$(@F).part" ]; then mv "$(@D)/.$(@F).part" "$@"; else rm -f "$(@D)/.$(@F).part"; fi

FORCE:

