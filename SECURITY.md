# Security

DarkShadow's Shell is a desktop shell: the installer copies scripts into `~/.local/bin`, they run at login, and a
few steps ask for sudo (packages, the input group, SDDM). This file says what is checked, what is a choice, and
what it does not protect against.

## Reporting a problem

Open a private security advisory on this repository (Security > Report a vulnerability). Please do not open a
public issue for something that runs code or exposes data.

## What the code checks

- **Downloads are verified before use.** Everything the installer unpacks or runs is pinned to a release tag and
  its SHA-256 is in `install/checksums.txt` (`install/lib/secure.sh`). A file with an unpinned name is not
  downloaded at all, a hash mismatch is deleted and reported.
- **Archives cannot write outside their folder.** `extract_verified` refuses absolute paths, `../` and links
  pointing out of the destination.
- **Updates only come from this project.** The origin must be `github.com/<owner>/DarkShadowShell`.
- **A changed installer is not started on its own.** An update that brings a new `install.sh` shows the diffstat
  and asks in a terminal; an update started from Settings (no terminal) is refused and points to `rice-update`.
  `RICE_TRUST_UPDATE=1` is the explicit opt-out.
- **The input group is opt-in.** Infinite Desktop reads `/dev/input`, so it needs it, but that permission lets
  every program you run read every keyboard on the machine. `./install.sh --input-group` (or Settings > Desktop >
  Infinite Desktop > Allow) enables it after saying so.

## What is a choice, not a default

- **Weather**: `rice-weather place "Warsaw"` is required before any request; otherwise wttr.in would geolocate your
  IP. Until then the widgets show the cached answer or nothing.
- **Lyrics**: `rice-lyrics on` allows asking lrclib.net about the current song (artist and title). Cached lyrics
  are used either way.
- **Update checks**: on by default, once a day (`rice-update every N`), off with `rice-update watch off`.

## Known limits

- **The upstream repository is not GPG-signed.** The guards above stop a foreign remote and a silent installer
  swap, but whoever controls the account you pull from can still change the code. If that matters to you, run from
  your own fork and review what the update changes before answering "y".
- **`rice-security` integrity baseline is tamper-evident, not tamper-proof.** It is a hash list in your own
  `~/.config`, so it notices accidental or casual changes; a process running as you can rewrite it.
- **Other downloads are data, not code.** `rice-cursor` pins Bibata to a release and checks its SHA-256, and every
  archive it opens is path-checked; the other cursor packs and the fonts `rice-fonts` downloads come over HTTPS
  from GitHub but are not hash-pinned here.
- **Local code is trusted.** The shell runs what is in `~/.config/quickshell` and `~/.config/hypr` at login. The
  checks above cover the path *into* your machine, not someone who can already write there.

## Checks

`tests/secure.sh` and `tests/update.sh` run on any machine (no Linux needed) and in CI on every push.
