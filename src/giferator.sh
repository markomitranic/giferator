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
OUTPUT_DIR="$(dirname "${1}")/giferated"
OUTPUT_FILENAME="$(basename "${1}")"
OUTPUT_FILE_PATH="${OUTPUT_DIR}/${OUTPUT_FILENAME}"

FPS="15"
SIZE_PIXELS="154"

rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR
$ffmpeg -y -i "$1" -vf fps=$FPS,scale=$SIZE_PIXELS:-1:flags=lanczos,palettegen $TEMP_DIR/palette.png
$ffmpeg -i "$1" -i $TEMP_DIR/palette.png -filter_complex "fps=$FPS,scale=$SIZE_PIXELS:-1:flags=lanczos[x];[x][1:v] paletteuse=" $TEMP_DIR/ffmpeg.gif
$gifsicle -O3 $TEMP_DIR/ffmpeg.gif -o $TEMP_DIR/gifsicle.gif
$imageoptim $TEMP_DIR/gifsicle.gif

# Output resulting file
mkdir -p $OUTPUT_DIR
cp $TEMP_DIR/gifsicle.gif $OUTPUT_FILE_PATH

# Open the folder in Finder and select the file, bring Finder to the front
osascript -e "tell application \"Finder\" to reveal POSIX file \"$OUTPUT_FILE_PATH\""
osascript -e "tell application \"Finder\" to activate"
