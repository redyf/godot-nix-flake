{
  description = "Godot Engine dev builds (Standard & Mono)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f:
        builtins.listToAttrs (map (system: {
          name = system;
          value = f nixpkgs.legacyPackages.${system};
        }) supportedSystems);

      # Per-version download metadata.
      #   sha256Linux  = SRI hash of the Linux zip (linux.x86_64 / mono_linux_x86_64)
      #   sha256Darwin = SRI hash of the macOS zip (macos.universal / mono_macos.universal)
      godotVersions = {
        "4_8-dev3" = {
          version = "4.8";
          flavor = "dev3";
          sha256Linux = "sha256-lBMqeOYj8IJD2/gJ48PwxfVRwdT9kiYUJuVR46Lo7F4=";
          sha256Darwin = "sha256-7IULnPKQqfqodVUOHjX4NRKrJWq1WU794YE/kBeNwJ0=";
          mono = false;
        };

        "4_8-dev3-mono" = {
          version = "4.8";
          flavor = "dev3";
          sha256Linux = "sha256-lmG7EjmSeLVibvgywii00i/DkprqwVaQKca7a4ovXIU=";
          sha256Darwin = "sha256-FdE3MhWBJfCK5XDNzl3p2yeAqhwd/jFnBekOgn8+iX0=";
          mono = true;
        };
      };

      # Linux derivation: unpack the Linux build and wrap the binary with all
      # runtime libraries, relying on autoPatchelfHook to fix up ELF binaries.
      mkGodotDevLinux =
        { pkgs, version, flavor, sha256, mono ? false }:
        let
          suffix = if mono then "-mono" else "";
          slug = if mono then "mono_linux_x86_64" else "linux.x86_64";

          runtimeLibs =
            with pkgs;
            [
              xorg.libX11
              xorg.libXcursor
              xorg.libXinerama
              xorg.libXrandr
              xorg.libXi
              xorg.libXext
              libGL
              alsa-lib
              libpulseaudio
              wayland
              systemd
              dbus
              fontconfig
              freetype
              zlib
              stdenv.cc.cc.lib
              libxkbcommon
            ]
            ++ pkgs.lib.optionals mono [
              dotnet-sdk_8
              dotnet-runtime_8
            ];

        in
        pkgs.stdenv.mkDerivation {
          pname = "godot${suffix}";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://downloads.godotengine.org/?version=${version}&flavor=${flavor}&slug=${slug}.zip&platform=linux.64";
            inherit sha256;
            name = "godot${suffix}.zip";
          };

          nativeBuildInputs = with pkgs; [
            unzip
            autoPatchelfHook
            makeWrapper
          ];

          buildInputs = runtimeLibs;

          unpackPhase = ''
            mkdir src
            cd src
            unzip $src
          '';

          configurePhase = ''
            export DOTNET_ROOT="${pkgs.dotnet-sdk_8}"
            export PATH="${pkgs.dotnet-sdk_8}/bin:$PATH"
          '';

          installPhase = ''
            mkdir -p $out/bin $out/lib
            cp -r ./* $out/lib/

            godot_bin=$(find $out/lib -type f -name "Godot_*" | head -n 1)

            makeWrapper "$godot_bin" $out/bin/godot${suffix} \
              --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath runtimeLibs}" \
              --prefix PATH : "${pkgs.lib.makeBinPath (pkgs.lib.optionals mono [ pkgs.dotnet-sdk_8 ])}" \
              --set DOTNET_ROOT "${pkgs.dotnet-sdk_8}"
          '';

          meta = {
            description = "Godot Engine ${version} ${flavor}${suffix}";
            homepage = "https://godotengine.org";
            platforms = [ "x86_64-linux" ];
          };
        };

      # Darwin derivation: unpack the universal macOS build and install the
      # .app bundle into $out/Applications. The Godot binaries are already
      # native (arm64 + x86_64) and signed by the Godot team, so no patching
      # is needed; a small wrapper in $out/bin lets you launch the editor.
      mkGodotDevDarwin =
        { pkgs, version, flavor, sha256, mono ? false }:
        let
          suffix = if mono then "-mono" else "";
          slug = if mono then "mono_macos.universal" else "macos.universal";
          appDir = if mono then "Godot_mono.app" else "Godot.app";
        in
        pkgs.stdenv.mkDerivation {
          pname = "godot${suffix}";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://downloads.godotengine.org/?version=${version}&flavor=${flavor}&slug=${slug}.zip&platform=macos";
            inherit sha256;
            name = "godot${suffix}-macos-${version}-${flavor}.zip";
          };

          nativeBuildInputs = with pkgs; [
            unzip
            makeWrapper
          ];

          buildInputs = pkgs.lib.optionals mono [ pkgs.dotnet-sdk_8 ];

          unpackPhase = ''
            mkdir src
            cd src
            unzip $src
          '';

          installPhase = ''
            mkdir -p $out/Applications $out/bin
            cp -R ${appDir} $out/Applications/

            makeWrapper "$out/Applications/${appDir}/Contents/MacOS/Godot" $out/bin/godot${suffix} \
              ${pkgs.lib.optionalString mono "--set DOTNET_ROOT \"${pkgs.dotnet-sdk_8}\" --prefix PATH : \"${pkgs.dotnet-sdk_8}/bin\""}
          '';

          meta = {
            description = "Godot Engine ${version} ${flavor}${suffix}";
            homepage = "https://godotengine.org";
            platforms = [
              "x86_64-darwin"
              "aarch64-darwin"
            ];
          };
        };

      mkGodotDev =
        { pkgs, version, flavor, mono ? false, sha256Linux, sha256Darwin }:
        if pkgs.stdenv.isDarwin then
          mkGodotDevDarwin {
            inherit pkgs version flavor mono;
            sha256 = sha256Darwin;
          }
        else
          mkGodotDevLinux {
            inherit pkgs version flavor mono;
            sha256 = sha256Linux;
          };
    in
    {
      packages = forAllSystems (pkgs:
        let
          pkgSets = builtins.mapAttrs (_: args: mkGodotDev (args // { inherit pkgs; })) godotVersions;
        in
        pkgSets // {
          default = pkgSets."4_8-dev3";
        });
    };
}
