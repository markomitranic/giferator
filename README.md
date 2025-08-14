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

The gifs will be output into a new `./giferated` folder, using human-readable profile suffixes like `__low-motion.gif` or `__large.gif`. It will automatically overwrite older versions if they exist. Application is dependency free, so it can be directly copied to your Applications folder.

## Compression

Compression algorhythm uses a few steps in order to make image smaller without changing the quality.
Via FFMPEG, static frames are made transparent and a per-variant color palette is calculated.
Both Gifsicle level 3 and ImageOptim are used for final compression and metadata removal.

### Default Profiles

The default profiles are conservative-to-aggressive to help compare quality vs size:

| Name/label | Specs | Expected effect |
| --- | --- | --- |
| tiny | 220w, 6fps, 64 colors; dither=bayer; lossy=60 | Very small footprint; choppier motion and potential banding; good for small UI/icons and low-detail clips |
| small | 260w, 8fps, 96 colors; dither=bayer; lossy=50 | Small file size; mild choppiness; good for small thumbnails |
| medium | 308w, 12fps, 128 colors; dither=bayer; lossy=40 | Balanced default; good quality/size tradeoff |
| large | 400w, 15fps, 256 colors; dither=bayer; lossy=30 | Higher fidelity; smoother motion and more colors; larger size |
| floyd-steinberg | 308w, 12fps, 128 colors; dither=floyd_steinberg; lossy=40 | Crisper edges via error diffusion; grain-like appearance; preserves detail; size ~ medium |
| low-motion | 308w, 8fps, 128 colors; dither=bayer; lossy=40 | Optimized for low-motion clips; significant size cut with minimal perceptual loss |
| noise-removal | 308w, 12fps, 128 colors; dither=bayer; lossy=40; denoise=hqdn3d | Reduces noise/grain crawl; smaller files; can slightly soften textures |

Each profile uses FFMpeg palettegen/paletteuse with the listed dithering and Gifsicle `-O3` with mild lossy quantization. The `noise-removal` profile applies `hqdn3d` denoising before palette generation.

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
