#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Godot 4.7 Android ARM64 + .NET build
# GitHub Codespaces
# ============================================================

GODOT_DIR="/workspaces/godot-engine"

ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
DOTNET_ROOT="${DOTNET_ROOT:-$HOME/.dotnet}"

export ANDROID_HOME
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export DOTNET_ROOT

export PATH="$DOTNET_ROOT:$HOME/.local/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# Godot 4.7 documented Android versions
ANDROID_PLATFORM="android-35"
ANDROID_BUILD_TOOLS="35.0.1"
ANDROID_NDK="28.1.13356709"
ANDROID_CMAKE="3.10.2.4988404"

# ============================================================
# Helpers
# ============================================================

die() {
    echo
    echo "ERROR: $1"
    exit 1
}

require_file() {
    [ -f "$1" ] || die "Missing file: $1"
}

require_dir() {
    [ -d "$1" ] || die "Missing directory: $1"
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 ||
        die "Missing command: $1"
}

# ============================================================
# 1. Verify Godot source
# ============================================================

echo "==> Verifying Godot source..."

require_dir "$GODOT_DIR"
require_file "$GODOT_DIR/SConstruct"
require_file "$GODOT_DIR/VERSION"
require_dir "$GODOT_DIR/platform/android"

cd "$GODOT_DIR"

echo "Godot source: OK"
echo "Source directory: $GODOT_DIR"

# ============================================================
# 2. System dependencies
# ============================================================

echo
echo "==> Installing system dependencies..."

sudo apt-get update

sudo apt-get install -y \
    python3 \
    python3-pip \
    build-essential \
    pkg-config \
    openjdk-17-jdk \
    git \
    curl \
    wget \
    unzip \
    zip

require_cmd python3
require_cmd gcc
require_cmd g++
require_cmd git
require_cmd curl
require_cmd java

# ============================================================
# 3. SCons
# ============================================================

echo
echo "==> Checking SCons..."

if ! command -v scons >/dev/null 2>&1; then
    python3 -m pip install --user "scons>=4.4"
fi

export PATH="$HOME/.local/bin:$PATH"

require_cmd scons

echo "SCons:"
scons --version | head -n 1

# ============================================================
# 4. .NET 9
# ============================================================

echo
echo "==> Checking .NET 9..."

DOTNET="$DOTNET_ROOT/dotnet"

if [ ! -x "$DOTNET" ] ||
   ! "$DOTNET" --list-sdks 2>/dev/null | grep -q '^9\.'; then

    echo ".NET 9 not found. Installing..."

    DOTNET_INSTALLER="/tmp/dotnet-install.sh"

    curl -fL \
        "https://builds.dotnet.microsoft.com/dotnet/scripts/v1/dotnet-install.sh" \
        -o "$DOTNET_INSTALLER"

    require_file "$DOTNET_INSTALLER"

    chmod +x "$DOTNET_INSTALLER"

    "$DOTNET_INSTALLER" \
        --channel 9.0 \
        --install-dir "$DOTNET_ROOT"

    rm -f "$DOTNET_INSTALLER"
fi

require_file "$DOTNET"

echo ".NET SDK:"
"$DOTNET" --list-sdks | grep '^9\.' || die ".NET 9 SDK not found"

# ============================================================
# 5. Android SDK
# ============================================================

echo
echo "==> Checking Android SDK..."

require_dir "$ANDROID_HOME"

SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

require_file "$SDKMANAGER"

chmod +x "$SDKMANAGER"

echo "sdkmanager:"
"$SDKMANAGER" --version

# ============================================================
# 6. Android components
# ============================================================

echo
echo "==> Installing/verifying Android build components..."

yes | "$SDKMANAGER" --licenses >/dev/null 2>&1 || true

"$SDKMANAGER" \
    "platforms;$ANDROID_PLATFORM" \
    "build-tools;$ANDROID_BUILD_TOOLS" \
    "ndk;$ANDROID_NDK" \
    "cmake;$ANDROID_CMAKE"

# Verify everything exists before wasting time compiling.

require_dir "$ANDROID_HOME/platforms/$ANDROID_PLATFORM"
require_dir "$ANDROID_HOME/build-tools/$ANDROID_BUILD_TOOLS"
require_dir "$ANDROID_HOME/ndk/$ANDROID_NDK"
require_dir "$ANDROID_HOME/cmake/$ANDROID_CMAKE"

require_file \
    "$ANDROID_HOME/cmake/$ANDROID_CMAKE/bin/cmake"

echo "Android platform: OK"
echo "Android build tools: OK"
echo "Android NDK: OK"
echo "CMake: OK"

# ============================================================
# 7. Final environment verification
# ============================================================

echo
echo "==> Final toolchain verification..."

echo
echo "Python:"
python3 --version

echo
echo "Java:"
java -version 2>&1 | head -n 1

echo
echo "SCons:"
scons --version | head -n 1

echo
echo ".NET:"
"$DOTNET" --version

echo
echo "CMake:"
"$ANDROID_HOME/cmake/$ANDROID_CMAKE/bin/cmake" \
    --version | head -n 1

echo
echo "Android NDK:"
echo "$ANDROID_HOME/ndk/$ANDROID_NDK"

# ============================================================
# 8. Build Godot
# ============================================================


echo "==> Building .NET Android ARM64 debug template..."

scons \
    -j"$(nproc)" \
    platform=android \
    arch=arm64 \
    production=yes \
    target=template_debug \
    module_dotnet_enabled=yes \
    generate_android_binaries=yes

echo "==> Generating Android debug APK..."

cd platform/android/java

chmod +x ./gradlew

./gradlew generateGodotMonoTemplates

cd ../../../..

echo
echo "==> Checking output..."

test -f "./bin/android_monoDebug.apk" || {
    echo "ERROR: Debug APK was not generated."
    exit 1
}

echo
echo "=========================================="
echo " DEBUG APK BUILD COMPLETE"
echo "=========================================="
echo
echo "APK:"
echo "./bin/android_monoDebug.apk"
