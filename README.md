# 🌀 Godot Dev Flake

**Godot Engine development builds (Standard & Mono) packaged as a Nix flake.**  
Run the latest Godot dev versions on Nix/NixOS — reproducible, sandboxed, and ready to use.

---

## 🚀 Usage

### Run directly
You can run Godot without installing it:

```bash
nix run github:redyf/godot-dev-flake
```

Or run the Mono version explicitly:

```bash
nix run github:redyf/godot-dev-flake#4_6-dev3-mono
```

Build manually

If you prefer to build it locally and keep the binaries:

```bash
nix build .#4_6-dev3
nix build .#4_6-dev3-mono
```

Then run from the result:

```bash
./result/bin/godot
./result/bin/godot-mono
```

🧩 Features

    ✅ Standard and Mono variants

    🔒 Reproducible builds with Nix flakes

    🧰 Bundled with all required runtime libraries and .NET SDK

    🧱 Works on Wayland, X11, and NVIDIA setups

    🐧 Runs perfectly on NixOS or any Nix-enabled Linux distribution

## 📦 Available Versions

| Package name      | Godot version | Type     | Status |
|------------------|---------------|---------|--------|
| 4_6-dev3         | 4.6 dev3      | Standard | ✅     |
| 4_6-dev3-mono    | 4.6 dev3      | Mono     | ✅     |


You can easily add more versions in the godotVersions section inside the flake.

🔧 Example: Using Godot Mono with C#

```bash
nix run github:redyf/godot-dev-flake#4_6-dev3-mono
```

The dotnet-sdk_8 and runtime are already bundled — no additional setup needed.
You can immediately open or create C# Godot projects.

🪄 Using in another flake

If you want to depend on this flake inside your own:

```nix
inputs.godot-dev-flake.url = "github:redyf/godot-dev-flake";
````

Then expose it in your packages or devShell:
```nix
{
  packages.x86_64-linux.godot = inputs.godot-dev-flake.packages.x86_64-linux."4_6-dev3";
}
```
Now you can run it with:

```bash
nix run .#godot
```

🧠 Notes

    Uses Nixpkgs unstable for access to latest dependencies

    Automatically sets up PATH, DOTNET_ROOT, and LD_LIBRARY_PATH for the Mono build

    Fully sandboxed — no global installation needed

    Works even on systems without dotnet preinstalled

💡 Contributing

Pull requests and version updates are welcome!
To add a new Godot version, simply edit the godotVersions attribute set in the flake and provide the new download sha256.

Licensed under the [MIT License](./LICENSE).
