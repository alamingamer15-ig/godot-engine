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

# .NET 9
curl -L https://builds.dotnet.microsoft.com/dotnet/scripts/v1/dotnet-install.sh \
    -o dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 9.0 --install-dir "$HOME/.dotnet"

export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$DOTNET_ROOT:$PATH"

# Android
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
    "platforms;android-35" \
    "build-tools;35.0.1" \
    "ndk;28.1.13356709" \
    "cmake;3.10.2.4988404"
