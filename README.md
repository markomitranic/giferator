# Giferator

A drag-and-drop macOS app for quickly optimising GIFs en-masse to a set of hardcoded media standards, using FFMpeg, Gifsicle and ImageOptim. It now exports multiple variants per input so designers can pick the best tradeoff. [Download macOS app (Universal)](https://github.com/markomitranic/giferator/releases/latest/download/Giferator.app.zip)

<img src="test/giferator-readme-intro.png?raw=true" width="400" alt="Giferator App Screenshot"/>

This project was created in 2017 for Catena Media, and later updated in 2023 for NoA Ignite Denmark, as an easy way for designers to resize and optimize Gifs used in products.

I tend to forget how it works, so I wrote an explainer a while ago [Compressing animated gifs in PHP](https://medium.com/homullus/compressing-animated-gifs-with-php-e26e655ec3e0)

| Original                                                          | Optimised                                                                             |
| ----------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| [test/Garder.gif](test/Garder.gif?raw=true)                       | [test/giferated/Garder.gif](test/giferated/Garder.gif?raw=true)                       |
| 1024 x 1024 @ 30fps (898kb)                                       | 288 x 288 @ 15fps (104kb)                                                             |
| <img src="test/Garder.gif?raw=true" width="400"/>                 | <img src="test/giferated/Garder.gif?raw=true" width="150"/>                           |
| [test/Ein Cowboy Bebop.gif](<test/Ein Cowboy Bebop.gif?raw=true>) | [test/giferated/Ein Cowboy Bebop.gif](<test/giferated/Ein Cowboy Bebop.gif?raw=true>) |
| 1044 x 800 @ 4fps (715kb)                                         | 288 x 288 @ 4fps (57kb)                                                               |
| <img src="test/Ein Cowboy Bebop.gif?raw=true" width="400"/>       | <img src="test/giferated/Ein Cowboy Bebop.gif?raw=true" width="150"/>                 |

## Usage

The application offers no interface and contains hardcoded output profiles. For each input, it will generate several variants differing by FPS, max width and color count. Profiles can be edited in `src/giferator.sh`.

Once you start the app, you can drag and drop any gif, image or video file, and it will automatically be compressed.

The gifs will be output into a new `./giferated` folder, using numbered tier-based profile names like `1-aggressive-plus.gif`, `4-balanced.gif` or `6-quality.gif`. Files are automatically sorted from smallest to largest. It will automatically overwrite older versions if they exist. Application is dependency free, so it can be directly copied to your Applications folder.

## Compression

Compression algorhythm uses a few steps in order to make image smaller without changing the quality.
Via FFMPEG, static frames are made transparent and a per-variant color palette is calculated.
Both Gifsicle level 3 and ImageOptim are used for final compression and metadata removal.

### Default Profiles

The default profiles use a standardized 288px width and are organized into 3 tiers based on compression/quality tradeoffs. Files are numbered for proper sorting (smallest to largest):

**Tier 1 - Aggressive Compression:**
| Name/label | Specs | Expected effect |
| --- | --- | --- |
| 1-aggressive-plus | 288w, 6fps, 64 colors; dither=bayer; lossy=60 | Maximum compression; smallest file size; reduced colors and frame rate; some motion choppiness and color banding |
| 2-aggressive | 288w, 8fps, 96 colors; dither=bayer; lossy=50 | High compression; small file size with slightly better colors and motion than aggressive-plus |

**Tier 2 - Balanced (with specialized alternatives):**
| Name/label | Specs | Expected effect |
| --- | --- | --- |
| 3-balanced-low-motion | 288w, 4fps, 128 colors; dither=bayer; lossy=40 | Balanced quality optimized for static content; ultra-low frame rate with good colors for maximum size savings |
| 4-balanced | 288w, 12fps, 128 colors; dither=bayer; lossy=40 | Balanced default; good quality/size tradeoff with moderate colors and smooth motion |
| 5-balanced-crisp | 288w, 12fps, 128 colors; dither=floyd_steinberg; lossy=40 | Balanced quality with alternative dithering; crisper edges and fine detail preservation using Floyd-Steinberg |

**Tier 3 - High Quality:**
| Name/label | Specs | Expected effect |
| --- | --- | --- |
| 6-quality | 288w, 15fps, 256 colors; dither=bayer; lossy=30 | High quality; maximum colors and smoothest motion; largest file size but best visual fidelity |

Each profile uses FFMpeg palettegen/paletteuse with the listed dithering and Gifsicle `-O3` with mild lossy quantization.

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
