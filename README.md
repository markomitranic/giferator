# Giferator

This project was created in 2017 for Catena Media, and later updated in 2023 for NoA Ignite Denmark, as an easy way for designers to resize and optimize Gifs used in products.

I tend to forget how it works, so I wrote an explainer a while ago [Compressing animated gifs in PHP](https://medium.com/homullus/compressing-animated-gifs-with-php-e26e655ec3e0)

## Usage

The application offers no interface and contains hardcoded variables for `FPS` and `SIZE_PIXELS` which can be manually customised.

Once you start the app, you can drag and drop any gif, image or video file, and it will automatically be compressed.

The gif will be output into a new `./giferated` folder, with the same filename. It will automatically overwrite older versions of the file if they exist. Application is dependency free, so it can be directly copied to your Applications folder.

## Compression

Compression algorhythm uses a few steps in order to make image smaller without changing the quality.
Via FFMPEG, static frames are made transparent, a color palette is calculated for each gif separately.
Both Gifsicle level 3 and ImageOptim are used for final compression and metadata removal.

# Building the Application

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
