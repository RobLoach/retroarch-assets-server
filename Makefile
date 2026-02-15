build: src/system/README.md public/pico.min.css frontend
	./build.sh

clean:
	rm -rf frontend system public/pico.min.css
	find . -type f -name .index -delete
	find . -type f -name .index-dirs -delete

update: clean build

src/system/README.md:
	git submodule update --init

public/pico.min.css:
	curl -L -o "public/pico.min.css" "https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css"

frontend: public/frontend/assets.zip \
	public/frontend/autoconfig.zip \
	public/frontend/cheats.zip \
	public/frontend/database-cursors.zip \
	public/frontend/database-rdb.zip \
	public/frontend/glui_minimal_assets.zip \
	public/frontend/info.zip \
	public/frontend/overlays.zip \
	public/frontend/shaders_cg.zip \
	public/frontend/shaders_glsl.zip \
	public/frontend/shaders_slang.zip \

public/frontend:
	mkdir -p public/frontend

public/frontend/assets.zip: public/frontend
	curl -L -o "public/frontend/assets.zip" "https://buildbot.libretro.com/assets/frontend/assets.zip"

public/frontend/autoconfig.zip: public/frontend
	curl -L -o "public/frontend/autoconfig.zip" "https://buildbot.libretro.com/assets/frontend/autoconfig.zip"

public/frontend/cheats.zip: public/frontend
	curl -L -o "public/frontend/cheats.zip" "https://buildbot.libretro.com/assets/frontend/cheats.zip"

public/frontend/database-cursors.zip: public/frontend
	curl -L -o "public/frontend/database-cursors.zip" "https://buildbot.libretro.com/assets/frontend/database-cursors.zip"

public/frontend/database-rdb.zip: public/frontend
	curl -L -o "public/frontend/database-rdb.zip" "https://buildbot.libretro.com/assets/frontend/database-rdb.zip"

public/frontend/glui_minimal_assets.zip: public/frontend
	curl -L -o "public/frontend/glui_minimal_assets.zip" "https://buildbot.libretro.com/assets/frontend/glui_minimal_assets.zip"

public/frontend/info.zip: public/frontend
	curl -L -o "public/frontend/info.zip" "https://buildbot.libretro.com/assets/frontend/info.zip"

public/frontend/overlays.zip: public/frontend
	curl -L -o "public/frontend/overlays.zip" "https://buildbot.libretro.com/assets/frontend/overlays.zip"

public/frontend/shaders_cg.zip: public/frontend
	curl -L -o "public/frontend/shaders_cg.zip" "https://buildbot.libretro.com/assets/frontend/shaders_cg.zip"

public/frontend/shaders_glsl.zip: public/frontend
	curl -L -o "public/frontend/shaders_glsl.zip" "https://buildbot.libretro.com/assets/frontend/shaders_glsl.zip"

public/frontend/shaders_slang.zip: public/frontend
	curl -L -o "public/frontend/shaders_slang.zip" "https://buildbot.libretro.com/assets/frontend/shaders_slang.zip"

