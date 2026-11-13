Personal DarkShadowShell desktop based on upstream V4.35, with a matching SDDM login screen, German defaults, XWayland/login scaling and optional Legion hardware settings.

Includes Wi-Fi/Quickshell crash recovery, the Qt GC workaround, quiet successful config reloads, and clipboard restoration fixes for text and images. Private clipboard history, pins, Wi-Fi profiles, credentials and application sessions are excluded.

Choose **generic** for preferred display settings or **legion** for the original Intel/NVIDIA laptop (2560 × 1600, 240 Hz, 160% scale). This is an installation preview.

### Download and assemble

Download all three `.iso.part-*` files for your chosen profile, its `PARTSUMS-*` and `SHA256SUMS-*`, and the matching `assemble-*.sh` script into one directory. Run `bash assemble-generic.sh` or `bash assemble-legion.sh`. The script checks every part, joins the ISO and verifies its complete SHA-256. Write that image to USB and boot in UEFI mode.

### Installation

Open **Install my-darkshadow** from the live desktop launcher, or run `sudo darkshadow-install`. The installer erases one selected disk after typed confirmation; it creates GPT, EFI, ext4 and systemd-boot. Internet is needed for missing packages. Dual boot, encryption and custom partitioning are not offered by the guided installer.

Existing NixOS users can use `personal/bootstrap.sh --system` instead. See [GUIDE.md](https://github.com/0Inexis0/my-darkshadow/blob/main/GUIDE.md) for installation, backups and rollback.

Validation: 28 Python checks and 10 QML login/scaling checks; ShellCheck; NixOS module evaluation; successful generic/Legion image builds; GitHub CI; redacted secret scans. Unicode/newline and PNG clipboard restoration were checked on the live Wayland clipboard with synthetic data, preserving existing history.
