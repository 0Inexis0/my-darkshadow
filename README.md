![my-darkshadow: A familiar shell. Ready to settle in.](.github/repo-header.svg)

# my-darkshadow

My personal fork of [DarkShadow's Shell](https://github.com/shadowww-dev/DarkShadowShell), with a matching login screen, display scaling fixes and a reproducible NixOS desktop.

[Install & update](GUIDE.md) · [Personal configuration](personal/) · [ISO builds](https://github.com/0Inexis0/my-darkshadow/releases) · [Upstream](https://github.com/shadowww-dev/DarkShadowShell) · [License](LICENSE)

## At a glance

- **Make it yours.** A monochrome desktop, a bottom dock, German defaults and a matching SDDM login screen.
- **A little extra.** Crisp XWayland scaling, monitor-aware login scaling and reliable menus after Quickshell crash recovery.
- **Keep it together.** Reviewed configuration, a pinned NixOS ISO build, hardware profiles and installers that back up local files.

## Get started

For an existing **NixOS** installation, download the bootstrap script and preview its plan:

```sh
curl -fsSL https://raw.githubusercontent.com/0Inexis0/my-darkshadow/main/personal/bootstrap.sh -o /tmp/darkshadow.sh
bash /tmp/darkshadow.sh --dry-run --system
```

Run `bash /tmp/darkshadow.sh --system` to stage the desktop, packages and login screen for your next reboot. Add `--profile legion` for the Intel/NVIDIA, 2560 × 1600, 240 Hz, 160% laptop setup.

For a fresh machine, build the live ISO with `nix build .#iso` or use an ISO from [Releases](https://github.com/0Inexis0/my-darkshadow/releases) when one is available. Boot it in UEFI mode and open **Install my-darkshadow** from the launcher. The guided installer erases one selected disk and asks for confirmation before writing.

> **Personal setup:** The installers change desktop configuration and, with `--system`, NixOS packages. The generic profile uses your display's preferred mode. See the [guide](GUIDE.md) for installation, hardware requirements, backups and rollback. ISO installation needs internet for packages missing from the live store.

Built on [DarkShadow's Shell](https://github.com/shadowww-dev/DarkShadowShell), based on upstream V4.35. Upstream credits and licensing remain in the [original README](docs/UPSTREAM-README.md) and [LICENSE](LICENSE).
