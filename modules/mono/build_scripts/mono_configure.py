def is_desktop(platform):
    return platform in ["windows", "macos", "linuxbsd"]


def is_unix_like(platform):
    return platform in ["macos", "linuxbsd", "android", "ios"]


def module_supports_tools_on(platform):
    return is_desktop(platform) or platform == "android"


def configure(env, env_mono):
    if env.editor_build:
        if not module_supports_tools_on(env["platform"]):
            raise RuntimeError("This module does not currently support building for this platform for editor builds.")
        env_mono.Append(CPPDEFINES=["GD_MONO_HOT_RELOAD"])

    # Android uses Microsoft's NativeAOT toolchain instead of a JIT runtime.
    # The host compiler runs on the build machine; the Android runtime is linked
    # statically into the Godot native library by modules/mono/SCsub.
    if env["platform"] == "android":
        ilc_path = env.Dir("#modules/mono/dotnet/ilcompiler/ilc").abspath
        if not env.File(ilc_path).exists():
            raise RuntimeError("Android .NET NativeAOT compiler not found: " + ilc_path)

        env["DOTNET_ILC"] = ilc_path
        env["DOTNET_ILCOMPILER_PATH"] = env.Dir("#modules/mono/dotnet/ilcompiler").abspath
        env_mono.Append(CPPDEFINES=["GODOT_MONO_NATIVE_AOT"])
