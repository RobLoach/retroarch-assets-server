CURL = curl -fL --retry 3 --connect-timeout 15

FRONTEND_URL = https://buildbot.libretro.com/assets/frontend
FRONTEND_ZIPS = assets autoconfig cheats database-cursors database-rdb \
	glui_minimal_assets info overlays shaders_cg shaders_glsl shaders_slang

.PHONY: build clean update frontend

# Drop partially-downloaded targets when curl fails.
.DELETE_ON_ERROR:

build: src/system/README.md public/pico.min.css frontend
	./build.sh

clean:
	rm -rf public/frontend public/system public/pico.min.css
	find public -type f -name .index -delete
	find public -type f -name .index-dirs -delete
	find public -type f -name .index-extended -delete

update: clean build

src/system/README.md:
	git submodule update --init

public/pico.min.css:
	$(CURL) -o "$@" "https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css"

frontend: $(FRONTEND_ZIPS:%=public/frontend/%.zip)

public/frontend:
	mkdir -p public/frontend

public/frontend/%.zip: | public/frontend
	$(CURL) -o "$@" "$(FRONTEND_URL)/$*.zip"

