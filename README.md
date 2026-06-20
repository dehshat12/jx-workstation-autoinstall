# JX Workstation Reproducible OS Packaging

This directory turns the current JX Sentinel/JX Workstation tree into two reproducible artifacts:

- a local ARM64 Debian package containing Sentinel, Guard, Control Panel, services, config defaults, assets, and branding scripts
- an Ubuntu autoinstall seed that installs Ubuntu 24.04 LTS, installs the package, and applies JX branding on first boot

The package is intentionally the source of truth for `/opt/jx` files and system integration. Do not package VM-local generated backups, test files, or runtime databases.

## Build The Package

From the repository root on Ubuntu 24.04 ARM64:

```bash
sudo apt update
sudo apt install -y build-essential pkg-config libgtk-4-dev libwebkitgtk-6.0-dev libjavascriptcoregtk-6.0-dev fakeroot dpkg-dev
packaging/jx-workstation/build-deb.sh
```

The output lands in:

```text
dist/jx-workstation_0.1.0_arm64.deb
```

Install locally:

```bash
sudo apt install ./dist/jx-workstation_0.1.0_arm64.deb
```

## Autoinstall Flow

Use `autoinstall/user-data` as the base seed. Put the built `.deb` somewhere the installer can fetch it, then update this line:

```yaml
JX_DEB_URL: "http://REPLACE-ME/jx-workstation_0.1.0_arm64.deb"
```

Common options:

- Serve `dist/` over HTTP on your LAN.
- Put the `.deb` in a small apt repository and replace the `late-commands` with apt source setup.
- Bake the `.deb` into a remastered ISO and install it from `/cdrom`.

## Package Responsibilities

The `.deb` installs:

- `/opt/jx/bin`, `/opt/jx/sbin`, `/opt/jx/libexec`, `/opt/jx/lib/jx-sentinel-control`
- `/opt/jx/etc/jx-sentinel/jx-sentinel.conf`
- `/opt/jx/etc/jx-sentinel/guard.conf`
- systemd units for Sentinel and Guard
- desktop entries, autostart entry, user service, and polkit action
- JX branding scripts and logo assets

On install, `postinst`:

- reloads systemd
- enables Sentinel and Guard
- fixes config permissions
- refreshes desktop databases when available
- runs `/opt/jx/bin/jx-apply-branding` if the logo is present

## What Remains In Autoinstall

Autoinstall should own machine identity and site policy:

- disk layout
- initial user
- hostname
- apt mirror
- SSH policy
- whether to start services immediately
- where the `.deb` comes from

The package should own JX behavior.

