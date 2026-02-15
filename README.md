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

3. Put any of your own content into the `public/cores` directory

4. Run the Build script
   ```sh
   ./build.sh
   ```

5. Point your web server at the `public` directory

## Usage

Within RetroArch...
1. Visit Online Updater > Updater Settings
2. Set "Build-bot Assets URL" to where your server is

## License

[MIT](LICENSE)