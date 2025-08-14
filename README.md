# Giferator

A drag-and-drop macOS app for quickly optimising GIFs en-masse to a set of hardcoded media standards, using FFMpeg, Gifsicle and ImageOptim. It now exports multiple variants per input so designers can pick the best tradeoff. [Download macOS app (Universal)](https://github.com/markomitranic/giferator/releases/latest/download/Giferator.app.zip)

<img src="test/giferator-readme-intro.png?raw=true" width="400" alt="Giferator App Screenshot"/>

This project was created in 2017 for Catena Media, and later updated in 2023 for NoA Ignite Denmark, as an easy way for designers to resize and optimize Gifs used in products.

I tend to forget how it works, so I wrote an explainer a while ago [Compressing animated gifs in PHP](https://medium.com/homullus/compressing-animated-gifs-with-php-e26e655ec3e0)

| Original                                                          | Optimised                                                                             |
| ----------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| [test/Garder.gif](test/Garder.gif?raw=true)                       | [test/giferated/Garder.gif](test/giferated/Garder.gif?raw=true)                       |
| 1024 x 1024 @ 30fps (898kb)                                       | 308 x 308 @ 15fps (104kb)                                                             |
| <img src="test/Garder.gif?raw=true" width="400"/>                 | <img src="test/giferated/Garder.gif?raw=true" width="150"/>                           |
| [test/Ein Cowboy Bebop.gif](<test/Ein Cowboy Bebop.gif?raw=true>) | [test/giferated/Ein Cowboy Bebop.gif](<test/giferated/Ein Cowboy Bebop.gif?raw=true>) |
| 1044 x 800 @ 4fps (715kb)                                         | 308 x 308 @ 4fps (57kb)                                                               |
| <img src="test/Ein Cowboy Bebop.gif?raw=true" width="400"/>       | <img src="test/giferated/Ein Cowboy Bebop.gif?raw=true" width="150"/>                 |

## Usage

The application offers no interface and contains hardcoded output profiles. For each input, it will generate several variants differing by FPS, max width and color count. Profiles can be edited in `src/giferator.sh`.

Once you start the app, you can drag and drop any gif, image or video file, and it will automatically be compressed.

The gifs will be output into a new `./giferated` folder, using a descriptive suffix like `__308w_12fps_128c.gif`. It will automatically overwrite older versions if they exist. Application is dependency free, so it can be directly copied to your Applications folder.

## Compression

Compression algorhythm uses a few steps in order to make image smaller without changing the quality.
Via FFMPEG, static frames are made transparent and a per-variant color palette is calculated.
Both Gifsicle level 3 and ImageOptim are used for final compression and metadata removal.

### Default Profiles

The default profiles are conservative-to-aggressive to help compare quality vs size:

- tiny: 220w @ 6fps, 64 colors
- small: 260w @ 8fps, 96 colors
- medium: 308w @ 12fps, 128 colors
- large: 400w @ 15fps, 256 colors

Each uses FFMpeg palettegen/paletteuse with Bayer dithering and Gifsicle `-O3` with mild lossy quantization.

# Development

The easiest way to use it during development is to invoke the shell script directly:

```shell
$ cd src
$ ./giferator.sh ../test/Himmelskibet.gif
```

This allows us to change the script on-the-fly. Alternatively we can build the application every time we make a change, or use Platypus' option "Bundle as symlinks" during export, but that is still experimental.

## Building the Application

We use [Platypus](https://sveinbjorn.org/platypus) to bundle a simple shell script `src/giferator.sh` and its vendor dependencies. The vendor dependencies are managed manually by downloading them from `brew` or developer (in case of ImageOptim).

Platypus config file is saved at `src/Giferator.platypus` and outputed app goes into `dist/Giferator.app`. Due to the way Platypus handles icons, we have to provide one each time we open the project.

Some notable settings (tend to get forgotten) include:

- Script path should lead to `giferator.sh`
- Interface type `Droplet`
- Not root or in background
- Accepts dropped items
- `public.image` UTI to limit filetypes
- Doesn't prompt on launch
- Bundled: `vendor` as a whole folder.
- Doesn't use symlinks for bundled files (except during dev?)
