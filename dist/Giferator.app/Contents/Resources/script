#!/bin/sh

# Exit on error, error on undefined variables
set -eu

# If no arguments are supplied
if [ $# -eq 0 ]; then
	echo "No arguments supplied!"
	exit
fi

# If supplied file does not exist
if [ ! -f "$1" ]; then
	echo "File not found!"
	exit
fi

ffmpeg=./vendor/ffmpeg
gifsicle=./vendor/gifsicle
imageoptim=./vendor/ImageOptim.app/Contents/MacOS/ImageOptim
TEMP_DIR="./tmp"
rm -rf "$TEMP_DIR" | true
mkdir -p "$TEMP_DIR"
INPUT_FILE_PATH=$(realpath "${1}")
OUTPUT_DIR="$(dirname "${INPUT_FILE_PATH}")/giferated"
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILENAME="$(basename "${INPUT_FILE_PATH}")"
touch "${OUTPUT_DIR}/${OUTPUT_FILENAME}"
OUTPUT_FILE_PATH=$(realpath "${OUTPUT_DIR}/${OUTPUT_FILENAME}")

FPS="15"
SIZE_PIXELS="308"

$ffmpeg -y -i "$INPUT_FILE_PATH" -vf fps=$FPS,scale=$SIZE_PIXELS:-1:flags=lanczos,palettegen "$TEMP_DIR/palette.png"
$ffmpeg -i "$INPUT_FILE_PATH" -i "$TEMP_DIR/palette.png" -filter_complex "fps=$FPS,scale=$SIZE_PIXELS:-1:flags=lanczos[x];[x][1:v] paletteuse=" "$TEMP_DIR/ffmpeg.gif"
$gifsicle -O3 "$TEMP_DIR/ffmpeg.gif" -o "$TEMP_DIR/gifsicle.gif"
$imageoptim "$TEMP_DIR/gifsicle.gif"

# Output resulting file
cp "$TEMP_DIR/gifsicle.gif" "$OUTPUT_FILE_PATH"

# Open the folder in Finder and select the file, bring Finder to the front
osascript -e "tell application \"Finder\" to reveal POSIX file \"$OUTPUT_FILE_PATH\""
osascript -e "tell application \"Finder\" to activate"

# Pretty-print debug information
printf "\n***************
Gifsicle: $($gifsicle --version | head -n 1)
FFMpeg: $($ffmpeg -version | head -n 1)
ImageOptim: $(defaults read $(realpath $imageoptim/../../Info.plist) CFBundleVersion)

Configuration:
	Input Arguments: $1
	Input File Path: $INPUT_FILE_PATH
	Output Dir: $OUTPUT_DIR
	Output Filename: $OUTPUT_FILENAME
	Output File Path: $OUTPUT_FILE_PATH
	Quality: $SIZE_PIXELS x $SIZE_PIXELS @ $FPS
\n***************\n"
