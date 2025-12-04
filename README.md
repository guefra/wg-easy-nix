# wg-easy Nix Flake

Nix flake for [wg-easy](https://github.com/wg-easy/wg-easy) - The easiest way to run WireGuard VPN + Web-based Admin UI.

> [!WARNING]
> This flake is experimental and unstable. Future versions may introduce breaking changes.

## Features

- Native NixOS module support
- Systemd service integration
- Uses upstream source from https://github.com/wg-easy/wg-easy

## Usage

### As a Flake Input

Add this flake to your `flake.nix`:

```nix
{
  inputs = {
    wg-easy.url = "github:fnltochka/wg-easy-nix";
  };

  outputs = { self, wg-easy, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      modules = [
        wg-easy.nixosModules.wg-easy
        {
          services.wg-easy = {
            enable = true;
            port = 51821;
            host = "0.0.0.0";
          };
        }
      ];
    };
  };
}
```

### Configuration Options

- `services.wg-easy.enable` - Enable the wg-easy service
- `services.wg-easy.port` - Port for the web UI (default: 51821)
- `services.wg-easy.host` - Host address to bind to (default: "0.0.0.0")
- `services.wg-easy.insecure` - Allow HTTP without TLS (default: false)
- `services.wg-easy.disableIPv6` - Disable IPv6 support (default: false)
- `services.wg-easy.experimentalAwg` - Enable experimental AmneziaWG support (default: false). Requires AmneziaWG kernel module.
- `services.wg-easy.overrideAutoAwg` - Override automatic AmneziaWG detection. Set to `"awg"` to force AmneziaWG, `"wg"` to force standard WireGuard, or `null` for auto-detection (default: null)
- `services.wg-easy.user` - User to run the service as (default: "root")
- `services.wg-easy.group` - Group to run the service as (default: "root")
- `services.wg-easy.environment` - Additional environment variables

## Building

The flake automatically builds wg-easy from the upstream source repository.

## License

This project is licensed under the AGPL-3.0-only License - see the [LICENSE](LICENSE) file for details

This project is not affiliated, associated, authorized, endorsed by, or in any way officially connected with Jason A. Donenfeld, ZX2C4 or Edge Security

"WireGuard" and the "WireGuard" logo are registered trademarks of Jason A. Donenfeld