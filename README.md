# RetroArch Assets Server

Implementation of RetroArch's Build-Bot Assets Server.

## Installation

1. Clone the repository
   ```sh
   git clone https://github.com/robloach/retroarch-assets-server.git
   ```

2. Make sure submodules are there
   ```
   git submodule update --init
   ```

3. Put any of your own content into the `public/cores` directory. For cores, use one directory per platform/arch (e.g. `public/cores/linux/x86_64/`) holding `<core>_libretro.<ext>.zip` files, each zip holding the single core file

4. Build everything
   ```sh
   make
   ```

5. Point your web server at the `public` directory. Apache works out of the box via `public/.htaccess`; for nginx or Caddy, see [docs/nginx.conf](docs/nginx.conf) or [docs/Caddyfile](docs/Caddyfile)

6. Set up a cronjob to rebuild the indexes
   ```sh
   make update
   ```

## Usage

Within RetroArch...
1. Visit Online Updater > Updater Settings
2. Set "Build-bot Assets URL" to where your server is
3. Disable "Automatically Extract Downloaded Archive"
4. Optional, only if serving cores: Set "Buildbot Cores URL" to your cores directory for that device (e.g. `public/cores/linux/x86_64/` -> `https://example.com/cores/linux/x86_64`)

## License

[MIT](LICENSE)