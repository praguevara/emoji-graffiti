{
  description = "A flake for building development environment of Phoenix project.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      with pkgs;
      {
        devShells.default = mkShell {
          buildInputs =
            [
              beam.packages.erlang_24.elixir_1_16

              elixir-ls
              tailwindcss-language-server
              vscode-langservers-extracted
              nodePackages.typescript-language-server
              pkgs.nodePackages.prettier
              tailwindcss

              nodejs

              docker-compose
              flyctl
            ]
            ++ lib.optionals stdenv.isLinux [
              # For ExUnit Notifier on Linux.
              libnotify

              # For file_system on Linux.
              inotify-tools
            ]
            ++ lib.optionals stdenv.isDarwin ([
              # For ExUnit Notifier on macOS.
              terminal-notifier

              # For file_system on macOS.
              darwin.apple_sdk.frameworks.CoreFoundation
              darwin.apple_sdk.frameworks.CoreServices
            ]);
        };
      }
    );
}
