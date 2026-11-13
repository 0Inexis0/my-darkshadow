# Personal setup

See [the guide](../GUIDE.md) for installation, updates, backups and hardware requirements.

- `bootstrap.sh`: desktop installer with a dry-run option.
- `apply.py`: reviewed file inventory, placeholder rendering, backups and local-edit protection.
- `configure-system.py`: NixOS integration retaining host hardware configuration.
- `install-to-disk.py`: guided whole-disk installer for the live ISO.
- `login/`: SDDM theme, monitor-scale bridge, preview and tests.
- `profiles/legion/`: original laptop's display and NVIDIA cursor configuration.
- `build-iso.sh`: build an image and SHA-256 checksum.
- `check-publication.py`: scan tracked files for credentials and private state.
- `publish.sh`: create the fork and push a reviewed commit using GitHub CLI.
