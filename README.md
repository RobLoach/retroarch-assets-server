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

4. Build everything
   ```sh
   make
   ```

5. Point your web server at the `public` directory

6. Set up a cronjob to rebuild the indexes
   ```sh
   make update
   ```

## Usage

Within RetroArch...
1. Visit Online Updater > Updater Settings
2. Set "Build-bot Assets URL" to where your server is

Open the server in a web browser to browse the content it's serving.

## License

[MIT](LICENSE)