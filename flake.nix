{
  description = "Godot Engine dev builds (Standard & Mono)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      mkGodotDev =
        {
          version,
          flavor,
          sha256,
          mono ? false,
        }:
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

      godotVersions = {
        "4_6-dev3" = {
          version = "4.6";
          flavor = "dev3";
          sha256 = "sha256-2GYLUkW/5UBR4UD3x/gO6zFweW2VlCywuGtFDw2/Wes=";
          mono = false;
        };

        "4_6-dev3-mono" = {
          version = "4.6";
          flavor = "dev3";
          sha256 = "sha256-F4uyzbgaxw+ZUEKEEw6sYABd6aW0dPEDz+ANvpe02AE=";
          mono = true;
        };
      };

    in
    {
      packages.${system} = (builtins.mapAttrs (_: args: mkGodotDev args) godotVersions) // {
        default = self.packages.${system}."4_6-dev3";
      };
    };
}
