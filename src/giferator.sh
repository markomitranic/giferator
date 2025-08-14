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

gifsicle=./vendor/gifsicle
imageoptim=./vendor/ImageOptim.app/Contents/MacOS/ImageOptim
TEMP_DIR="./tmp"
rm -rf "$TEMP_DIR" | true
mkdir -p "$TEMP_DIR"
INPUT_FILE_PATH=$(realpath "${1}")
OUTPUT_DIR="$(dirname "${INPUT_FILE_PATH}")/giferated"
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILENAME="$(basename "${INPUT_FILE_PATH}")"
BASE_NAME="${OUTPUT_FILENAME%.*}"

# Define output profiles: label|fps|width|max_colors|dither|lossy|denoise
PROFILES="
tiny|6|220|64|bayer|60|0
small|8|260|96|bayer|50|0
medium|12|308|128|bayer|40|0
large|15|400|256|bayer|30|0
floyd-steinberg|12|308|128|floyd_steinberg|40|0
low-motion|8|308|128|bayer|40|0
noise-removal|12|308|128|bayer|40|1
"

PRODUCED_FILES=""
MANIFEST_BODY=""

while IFS='|' read -r label FPS SIZE_PIXELS MAX_COLORS DITHER LOSSY DENOISE_FLAG; do
	[ -z "$label" ] && continue
	PALETTE_FILE="$TEMP_DIR/${label}_palette.png"
	FFMPEG_FILE="$TEMP_DIR/${label}_ffmpeg.gif"
	GIFSICLE_FILE="$TEMP_DIR/${label}_gifsicle.gif"
	OUTPUT_FILE_PATH="${OUTPUT_DIR}/${label}.gif"

	CHAIN="fps=$FPS,scale=$SIZE_PIXELS:-1:flags=lanczos"
	if [ "${DENOISE_FLAG}" = "1" ]; then
		CHAIN="$CHAIN,hqdn3d=1.5:1.5:6:6"
	fi

	ffmpeg -y -i "$INPUT_FILE_PATH" -vf "$CHAIN,palettegen=max_colors=$MAX_COLORS:stats_mode=diff" "$PALETTE_FILE"
	ffmpeg -y -i "$INPUT_FILE_PATH" -i "$PALETTE_FILE" -filter_complex "$CHAIN[x];[x][1:v]paletteuse=dither=${DITHER}" "$FFMPEG_FILE"
	# Use gifsicle with strong optimization and optional lossy quantization if supported
	$gifsicle -O3 --lossy=$LOSSY "$FFMPEG_FILE" -o "$GIFSICLE_FILE" 2>/dev/null || $gifsicle -O3 "$FFMPEG_FILE" -o "$GIFSICLE_FILE"
	$imageoptim "$GIFSICLE_FILE"
	cp "$GIFSICLE_FILE" "$OUTPUT_FILE_PATH"
	PRODUCED_FILES="$PRODUCED_FILES\n$OUTPUT_FILE_PATH"

	# Build manifest row
	if [ "${DENOISE_FLAG}" = "1" ]; then
		DENOISE_TEXT="yes"
	else
		DENOISE_TEXT="no"
	fi
	SPECS="${SIZE_PIXELS}w, ${FPS}fps, ${MAX_COLORS} colors; dither=${DITHER}; lossy=${LOSSY}; denoise=${DENOISE_TEXT}"
	case "$label" in
		tiny)
			EFFECT="Very small footprint; choppier motion and potential banding; good for small UI/icons and low-detail clips" ;;
		small)
			EFFECT="Small file size; mild choppiness; good for small thumbnails" ;;
		medium)
			EFFECT="Balanced default; good quality/size tradeoff" ;;
		large)
			EFFECT="Higher fidelity; smoother motion and more colors; larger size" ;;
		floyd-steinberg)
			EFFECT="Crisper edges via error diffusion; grain-like appearance; preserves detail; size ~ medium" ;;
		low-motion)
			EFFECT="Optimized for low-motion clips; significant size cut with minimal perceptual loss" ;;
		noise-removal)
			EFFECT="Reduces noise/grain crawl; smaller files; can slightly soften textures" ;;
		*)
			EFFECT="Variant tuned for different balance of motion smoothness and color detail" ;;
	esac
    MANIFEST_BODY="$MANIFEST_BODY\n$label\nSpecs: $SPECS\nEffect: $EFFECT\n"
done <<EOF
$PROFILES
EOF

# Reveal output directory in Finder and bring to front
osascript -e "tell application \"Finder\" to reveal POSIX file \"$OUTPUT_DIR\""
osascript -e "tell application \"Finder\" to activate"

# Write manifest TXT to output folder and echo it to terminal
MANIFEST_TEXT_PATH="$OUTPUT_DIR/manifest.txt"
{
	echo "Giferator Profiles"
	echo ""
	echo "The files in this folder are generated variants of your GIF with different tradeoffs."
	echo ""
	echo "$(printf "%b" "$MANIFEST_BODY")"
} > "$MANIFEST_TEXT_PATH"

echo ""
echo "Profiles Manifest"
echo ""
cat "$MANIFEST_TEXT_PATH"

# Pretty-print debug information
printf "\n***************
Gifsicle: $($gifsicle --version | head -n 1)
FFMpeg: $(ffmpeg -version | head -n 1)
ImageOptim: $(defaults read $(realpath $imageoptim/../../Info.plist) CFBundleVersion)

Configuration:
	Input Arguments: $1
	Input File Path: $INPUT_FILE_PATH
	Output Dir: $OUTPUT_DIR
	Output Files: $PRODUCED_FILES
\n***************\n"
