CURL = curl -fL --retry 3 --connect-timeout 15

FRONTEND_URL = https://buildbot.libretro.com/assets/frontend
FRONTEND_ZIPS = assets autoconfig cheats database-cursors database-rdb \
	glui_minimal_assets info overlays shaders_cg shaders_glsl shaders_slang

.PHONY: build clean update frontend

# Drop partially-downloaded targets when curl fails.
.DELETE_ON_ERROR:

build: src/system/README.md frontend
	./build.sh

clean:
	rm -rf public/frontend public/system
	find public -type f -name .index -delete
	find public -type f -name .index-dirs -delete
	find public -type f -name .index-extended -delete

update: clean build

src/system/README.md:
	git submodule update --init

frontend: $(FRONTEND_ZIPS:%=public/frontend/%.zip)

public/frontend:
	mkdir -p public/frontend

public/frontend/%.zip: | public/frontend
	$(CURL) -o "$@" "$(FRONTEND_URL)/$*.zip"

