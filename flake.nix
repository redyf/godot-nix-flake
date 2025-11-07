{
  description = "Godot Engine dev builds";

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
        }:
        let
          runtimeLibs = with pkgs; [
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
          ];
        in
        pkgs.stdenv.mkDerivation {
          pname = "godot-dev";
          inherit version;

          src = pkgs.fetchzip {
            url = "https://downloads.godotengine.org/?version=${version}&flavor=${flavor}&slug=linux.x86_64.zip&platform=linux.64";
            inherit sha256;
            stripRoot = false;
            extension = "zip";
          };

          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            makeWrapper
          ];

          buildInputs = runtimeLibs;

          installPhase = ''
            mkdir -p $out/bin $out/lib
            cp -r ./* $out/lib/

            godot_bin=$(find $out/lib -name "Godot_*" -type f -executable | head -n 1)

            if [ -n "$godot_bin" ]; then
              makeWrapper "$godot_bin" $out/bin/godot \
                --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath runtimeLibs}"
            fi
          '';

          meta = with pkgs.lib; {
            description = "Godot Engine ${version} ${flavor}";
            homepage = "https://godotengine.org";
            platforms = [ "x86_64-linux" ];
          };
        };

    in
    {
      packages.${system} = {
        godot-4_6-dev3 = mkGodotDev {
          version = "4.6";
          flavor = "dev3";
          sha256 = "sha256-Fgvlt6TaKX/5N9GO6mGqYTMYjaBzME7Hs9CUEaboPyk=";
        };

        default = self.packages.${system}.godot-4_6-dev3;
      };
    };
}
