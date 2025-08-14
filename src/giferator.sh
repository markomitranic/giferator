#!/bin/sh

# Exit on error, error on undefined variables
set -eu

# If no arguments are supplied
if [ $# -eq 0 ]; then
	echo "No video file supplied! Usage: ./giferator.sh <video_file>"
	echo "Supported formats: MOV, MP4, AVI, WEBM, etc."
	exit
fi

# If supplied file does not exist
if [ ! -f "$1" ]; then
	echo "Video file not found: $1"
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

# Define output profiles: label|fps|width|max_colors|dither|lossy
PROFILES="
1-aggressive-plus|6|288|64|bayer|60
2-aggressive|8|288|96|bayer|50
3-balanced-low-motion|4|288|128|bayer|40
4-balanced|12|288|128|bayer|40
5-balanced-crisp|12|288|128|floyd_steinberg|40
6-quality|15|288|256|bayer|30
"

PRODUCED_FILES=""
MANIFEST_BODY=""

while IFS='|' read -r label FPS SIZE_PIXELS MAX_COLORS DITHER LOSSY; do
	[ -z "$label" ] && continue
	PALETTE_FILE="$TEMP_DIR/${label}_palette.png"
	FFMPEG_FILE="$TEMP_DIR/${label}_ffmpeg.gif"
	GIFSICLE_FILE="$TEMP_DIR/${label}_gifsicle.gif"
	OUTPUT_FILE_PATH="${OUTPUT_DIR}/${label}.gif"

	CHAIN="fps=$FPS,scale=$SIZE_PIXELS:-1:flags=lanczos"

	ffmpeg -y -i "$INPUT_FILE_PATH" -vf "$CHAIN,palettegen=max_colors=$MAX_COLORS:stats_mode=diff" "$PALETTE_FILE"
	ffmpeg -y -i "$INPUT_FILE_PATH" -i "$PALETTE_FILE" -filter_complex "$CHAIN[x];[x][1:v]paletteuse=dither=${DITHER}" "$FFMPEG_FILE"
	# Use gifsicle with strong optimization and optional lossy quantization if supported
	$gifsicle -O3 --lossy=$LOSSY "$FFMPEG_FILE" -o "$GIFSICLE_FILE" 2>/dev/null || $gifsicle -O3 "$FFMPEG_FILE" -o "$GIFSICLE_FILE"
	$imageoptim "$GIFSICLE_FILE"
	cp "$GIFSICLE_FILE" "$OUTPUT_FILE_PATH"
	PRODUCED_FILES="$PRODUCED_FILES\n$OUTPUT_FILE_PATH"

	# Build manifest row
	SPECS="${SIZE_PIXELS}w, ${FPS}fps, ${MAX_COLORS} colors; dither=${DITHER}; lossy=${LOSSY}"
	case "$label" in
		1-aggressive-plus)
			EFFECT="Maximum compression; smallest file size; reduced colors and frame rate; some motion choppiness and color banding" ;;
		2-aggressive)
			EFFECT="High compression; small file size with slightly better colors and motion than aggressive-plus" ;;
		3-balanced-low-motion)
			EFFECT="Balanced quality optimized for static content; ultra-low frame rate with good colors for maximum size savings" ;;
		4-balanced)
			EFFECT="Balanced default; good quality/size tradeoff with moderate colors and smooth motion" ;;
		5-balanced-crisp)
			EFFECT="Balanced quality with alternative dithering; crisper edges and fine detail preservation using Floyd-Steinberg" ;;
		6-quality)
			EFFECT="High quality; maximum colors and smoothest motion; largest file size but best visual fidelity" ;;
		*)
			EFFECT="Custom profile with specific quality/compression balance" ;;
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
	echo "Video to GIF Conversion Results"
	echo ""
	echo "The GIF files in this folder are generated from your video with different quality/compression tradeoffs."
	echo "Each profile offers different balance of file size vs visual quality."
	echo ""
	echo "$(printf "%b" "$MANIFEST_BODY")"
} > "$MANIFEST_TEXT_PATH"

echo ""
echo "Profiles Manifest"
echo ""
cat "$MANIFEST_TEXT_PATH"

# Pretty-print debug information
printf "\n***************
Video to GIF Conversion Complete!

Tools Used:
	Gifsicle: $($gifsicle --version | head -n 1)
	FFMpeg: $(ffmpeg -version | head -n 1)
	ImageOptim: $(defaults read $(realpath $imageoptim/../../Info.plist) CFBundleVersion)

Configuration:
	Input Video: $1
	Input File Path: $INPUT_FILE_PATH
	Output Dir: $OUTPUT_DIR
	GIF Files Created: $PRODUCED_FILES
\n***************\n"
