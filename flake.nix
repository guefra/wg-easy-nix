{
  description = "Nix flake for wg-easy (packaged as github.com/fnltochka/wg-easy-nix)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    systems.url = "github:nix-systems/default";
    wg-easy-src = {
      url = "github:wg-easy/wg-easy";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    wg-easy-src,
    ...
  }: let
    eachSystem = nixpkgs.lib.genAttrs (import systems);
  in {
    packages = eachSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };

      nodeModules =
        pkgs.runCommand "wg-easy-node-modules" {
          src = wg-easy-src;

          nativeBuildInputs = with pkgs; [
            nodejs_20
            pnpm
            jq
          ];

          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          NODE_EXTRA_CA_CERTS = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

          NUXT_TELEMETRY_DISABLED = "1";

          outputHashMode = "nar";
          outputHash = "sha256-hQ2Hh39lIl9jBXiEps1JHLV3FLaY1F8RTEWmi9ayvA4=";
        } ''
          cp -r "$src/src" ./src
          chmod -R u+w ./src
          cd src

          export HOME="$PWD/.nix-pnpm-home"
          export XDG_DATA_HOME="$HOME/.local/share"
          mkdir -p "$XDG_DATA_HOME/pnpm"
          export PNPM_HOME="$XDG_DATA_HOME/pnpm"

          # Safely remove packageManager field using jq
          jq 'del(.packageManager)' package.json > package.json.tmp
          mv package.json.tmp package.json

          ${pkgs.pnpm}/bin/pnpm install --frozen-lockfile --ignore-scripts

          rm -rf .pnpm-store
          mkdir -p "$out"
          cp -r node_modules "$out"/
        '';
    in rec {
      wg-easy = pkgs.stdenv.mkDerivation {
        pname = "wg-easy";
        version = "15.2.0-beta.3";

        src = wg-easy-src + "/src";

        nativeBuildInputs = with pkgs; [
          nodejs_20
          makeWrapper
        ];

        buildPhase = ''
          chmod -R u+w .

          cp -r ${nodeModules}/node_modules ./node_modules
          chmod -R u+w node_modules

          export NUXT_TELEMETRY_DISABLED=1
          export PATH="./node_modules/.bin:$PATH"

          nuxt build
          node cli/build.js
        '';

        installPhase = ''
          mkdir -p "$out/app"

          cp -r .output/. "$out/app/"

          cp -r node_modules "$out/app/node_modules"

          mkdir -p "$out/app/server/database"
          cp -r server/database/migrations "$out/app/server/database/migrations"

          mkdir -p "$out/bin"

          makeWrapper ${pkgs.nodejs_20}/bin/node "$out/bin/wg-easy-server" \
            --chdir "$out/app" \
            --add-flags server/index.mjs

          makeWrapper ${pkgs.nodejs_20}/bin/node "$out/bin/wg-easy-cli" \
            --chdir "$out/app" \
            --add-flags server/cli.mjs
        '';

        meta = with pkgs.lib; {
          description = "The easiest way to run WireGuard VPN + Web-based Admin UI";
          homepage = "https://github.com/wg-easy/wg-easy";
          license = lib.licenses.agpl3Plus;
          maintainers = with lib.maintainers; [
            FnlTochka
          ];
        };
      };

      default = wg-easy;
    });

    nixosModules.wg-easy = {
      config,
      lib,
      pkgs,
      ...
    }:
      import ./nixosModules/wg-easy.nix {
        inherit self config lib pkgs;
      };

    nixosModules.default = self.nixosModules.wg-easy;
  };
}
