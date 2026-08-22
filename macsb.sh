#!/bin/bash
set -e

echo "=================================================="
echo " Godot Master - C# Android ARM64 Debug Build"
echo "=================================================="

# ==================================================
# 1. DOWNLOAD ANDROID COMMAND-LINE TOOLS FIRST
# ==================================================

echo
echo "=== 1. Downloading Android command-line tools ==="

cd /tmp

wget -q \
    "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
    -O android-cmdline-tools.zip

# ==================================================
# 2. CREATE DIRECTORIES
# ==================================================

echo
echo "=== 2. Creating Android SDK directories ==="

ANDROID_HOME="$HOME/android-sdk"

mkdir -p "$ANDROID_HOME/cmdline-tools"

unzip -q android-cmdline-tools.zip \
    -d "$ANDROID_HOME/cmdline-tools"

mv \
    "$ANDROID_HOME/cmdline-tools/cmdline-tools" \
    "$ANDROID_HOME/cmdline-tools/latest"

rm -f android-cmdline-tools.zip

# ==================================================
# 3. DEFINE PATHS
# ==================================================

echo
echo "=== 3. Defining paths ==="

export ANDROID_HOME="$HOME/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

GODOT_DIR="/workspaces/godot"
OUTPUT_DIR="$GODOT_DIR/bin"
OUTPUT_APK="$OUTPUT_DIR/android-debug.apk"
NUGET_DIR="$HOME/MyLocalNugetSource"

echo "Godot:       $GODOT_DIR"
echo "Android SDK: $ANDROID_HOME"
echo "Output APK:  $OUTPUT_APK"

# ==================================================
# 4. INSTALL SYSTEM BUILD DEPENDENCIES
# ==================================================

echo
echo "=== 4. Installing build dependencies ==="

sudo apt-get update

sudo apt-get install -y \
    build-essential \
    scons \
    pkg-config \
    libx11-dev \
    libxcursor-dev \
    libxinerama-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libasound2-dev \
    libpulse-dev \
    libudev-dev \
    libxi-dev \
    libxrandr-dev \
    openjdk-17-jdk \
    unzip \
    wget \
    dotnet-sdk-8.0

# ==================================================
# 5. INSTALL ANDROID SDK COMPONENTS
# ==================================================

echo
echo "=== 5. Installing Android SDK components ==="

yes | sdkmanager --licenses >/dev/null

sdkmanager \
    "platform-tools" \
    "build-tools;36.1.0" \
    "platforms;android-36"

# Godot master will automatically request:
# NDK 29.0.14206865
#
# when SCons detects that it is missing.

# ==================================================
# 6. ENTER GODOT SOURCE
# ==================================================

echo
echo "=== 6. Entering Godot source ==="

cd "$GODOT_DIR"

# ==================================================
# 7. BUILD HOST C# EDITOR
# ==================================================

echo
echo "=== 7. Building host C# editor ==="

scons \
    platform=linuxbsd \
    target=editor \
    module_mono_enabled=yes \
    -j"$(nproc)"

# ==================================================
# 8. GENERATE C# GLUE
# ==================================================

echo
echo "=== 8. Generating C# glue ==="

./bin/godot.linuxbsd.editor.mono \
    --generate-mono-glue \
    ./modules/mono/glue

# ==================================================
# 9. BUILD C# ASSEMBLIES / NUGET PACKAGES
# ==================================================

echo
echo "=== 9. Building C# assemblies ==="

mkdir -p "$NUGET_DIR"

dotnet nuget add source \
    "$NUGET_DIR" \
    --name MyLocalNugetSource 2>/dev/null || true

./modules/mono/build_scripts/build_assemblies.py \
    --godot-output-dir "$OUTPUT_DIR" \
    --push-nupkgs-local "$NUGET_DIR"

# ==================================================
# 10. BUILD ANDROID ARM64 DEBUG TEMPLATE
# ==================================================

echo
echo "=== 10. Building Android ARM64 C# debug template ==="

scons \
    platform=android \
    target=template_debug \
    module_mono_enabled=yes \
    arch=arm64 \
    generate_android_binaries=yes \
    -j"$(nproc)"

# ==================================================
# 11. VERIFY AND COPY FINAL APK
# ==================================================

echo
echo "=== 11. Preparing final APK ==="

SOURCE_APK="$OUTPUT_DIR/android_debug.apk"

if [ ! -f "$SOURCE_APK" ]; then
    echo
    echo "ERROR: android_debug.apk was not generated!"
    echo
    echo "Available Android artifacts:"
    find "$OUTPUT_DIR" -maxdepth 1 -type f \
        \( -name "android_*.apk" -o -name "android_*.aab" -o -name "android_*.zip" \) \
        -printf "  %f\n" | sort

    exit 1
fi

cp "$SOURCE_APK" "$OUTPUT_APK"

# ==================================================
# 12. FINAL RESULT
# ==================================================

echo
echo "=================================================="
echo " BUILD COMPLETE"
echo "=================================================="
echo
echo "Android ARM64 C# Debug APK:"
echo
echo "  $OUTPUT_APK"
echo
echo "Original Godot artifact:"
echo
echo "  $SOURCE_APK"
echo
echo "C# NuGet packages:"
echo
echo "  $NUGET_DIR"
echo
echo "=================================================="
