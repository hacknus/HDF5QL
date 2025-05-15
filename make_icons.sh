#!/bin/bash

INPUT="icon.png"
ICONSET_DIR="AppIcons"

# Check input
if [ ! -f "$INPUT" ]; then
  echo "❌ Error: $INPUT not found."
  exit 1
fi

# Create .iconset folder
mkdir -p "$ICONSET_DIR"

# Declare icon sizes and filenames
declare -a icons=(
  "16 icon_16x16.png"
  "32 icon_16x16@2x.png"
  "32 icon_32x32.png"
  "64 icon_32x32@2x.png"
  "128 icon_128x128.png"
  "256 icon_128x128@2x.png"
  "256 icon_256x256.png"
  "512 icon_256x256@2x.png"
  "512 icon_512x512.png"
  "1024 icon_512x512@2x.png"
)

echo "🔧 Generating iconset PNGs..."

for icon in "${icons[@]}"
do
  set -- $icon
  SIZE=$1
  NAME=$2
  sips -z $SIZE $SIZE "$INPUT" --out "$ICONSET_DIR/$NAME" >/dev/null
  echo "✓ $NAME ($SIZE x $SIZE)"
done

echo "✅ Done! All icons saved in '$ICONSET_DIR'."
echo "🛠️ You can now create an .icns file using:"
echo "iconutil -c icns $ICONSET_DIR"