# Changelog

## V4.06: tray icons are back
- Tray icons (Spotify, Discord, Steam ...) show again: since V4.05 the icons of apps that bring their own icon folder were not found, which left an empty spot in the tray. Their folder is now searched first, then every icon theme, and an app without any icon gets a plain app icon instead of a gap

## V4.05: no more icon crashes
- **Quickshell no longer crashes on app icons** (NixOS with Qt 6.12: the bar, the dock and the widgets went down, also during an update). Every app icon (bar, tray, dock, launcher, notifications, island, hot corner, volume mixer and Settings) used Qt's icon theme engine, which crashed on some icons. Now the icons are found as plain files in the background (Icons.qml) and drawn as pictures, never through that engine

## V4.04: the old black hole is back
- fastfetch shows the black hole of V3.99 again (the straight one, in your wallpaper's colors): the tilted and the full-color ones of V4.00 and V4.02 are gone

## V4.03: crash fix
- **The bar and the widgets no longer crash when you switch windows** (seen on NixOS with Qt 6.12): the app icon next to the window title went through Qt's icon theme engine right as the window changed, and its SVG loader could crash, taking the bar, the dock and the widgets with it. The icon is now found as a file and drawn in the background, a moment after the window changes

## V4.02: a new black hole in fastfetch
- **The black hole in fastfetch, drawn again from scratch**: now in full color with soft light instead of blocky characters. A deep black shadow, a tilted glowing disk crossing in front of it, its far side bent over and under the shadow like Gargantua, a thin photon ring and a soft glow fading into the dark. White-hot inside, then your wallpaper's colors (or Gargantua's warm light when fastfetch uses its own colors)

## V4.01: live wallpaper fix
- A picture now always replaces a live (video) wallpaper: the video could keep playing over it (mpvpaper missed the stop signal while paused). It is now stopped for sure, also on NixOS

## V4.00: Update Center
- **Update Center** (Settings, next to About): your version, the newest one and what is new in it, and **Update now** right there: no terminal window. Every step shows live as it happens (a spinner while it runs, then a tick), with a progress ring, the time it takes and the full log. You can close Settings, the update keeps going, and Settings comes back to it after it reloads
- The "Update is Available!" notification and the island open the Update Center instead of a terminal. Updates with new system packages (they need your password) still have a button for the terminal
- **A tilted black hole** in fastfetch: the glowing disk crosses the shadow at an angle, with the bright lensed ring arching over and under it, like Gargantua
- Settings > System no longer has a second "System" page: that is in About

## V3.99: two screens
- **Widgets on another screen**: Settings > System > Monitors > pick a screen > Put the widgets here (Edit mode opens there too)
- **The main screen stays the main screen**: with nothing chosen the shell picked "whichever screen came first", which changed from boot to boot. Now it is always the same one, and at the first login with two screens the one in the top left is saved as the main screen
- **Screens keep their places**: two screens that were never arranged in Settings could come up swapped after a reboot. At login their places are saved once (when nothing was saved yet), so the next boot keeps them; arrange them in Settings > Monitors if they are the wrong way round
- Updates never ask for a GitHub login: no login prompt or sign-in window from git, and the old address (shadows-shell) goes to the new one (DarkShadowShell)

## V3.98: Infinite Desktop on niri, your keys, new motion
- **Infinite Desktop on niri**: the windows of the workspace float on a canvas you move: hold your keys and move the mouse, or your keys + arrows; go from window to window with the canvas gliding to it; new windows float too while it is on. (niri cannot make windows smaller, so there is no zoom there.) On / off: SUPER + ALT + F on niri
- **Your keys for Infinite Desktop** (Settings > Desktop > Infinite Desktop > Keys): on / off, what you hold to move the canvas, what goes to the next window, and the zoom key (Hyprland), on Hyprland and niri
- **New motion styles** (Settings > Motion): **Fluid** (Material 3 emphasized curves: a long, soft landing, no bounce) and **Expressive** (Material 3 springs: a soft pop with a hint of overshoot), on Hyprland and niri. Bouncy is gone; if you had it, you get Expressive
- niri: blur behind the desktop widgets works (they use niri's wallpaper blur now, not the experimental kind that did not show under them)

## V3.97: widgets: blur and transparency, the visualizer on niri
- niri: the visualizer at the screen edge shows now (its window was bigger than the screen, niri left it out); every widget's window now stays inside the screen
- Widgets: **Transparency** for all of them (Settings > Widgets, and Quick settings in Edit mode), next to **Blur behind widgets**, on Hyprland and niri
- The widget themes (DarkShadow, Google, Outline) are gone from Settings and Edit mode
- Edit mode: the panel on the left slides away while you drag or resize a widget over it, and comes back when you let go

## V3.96: only the clock
- Settings > Dynamic island > **Dynamic island**: off, the island is only your clock. It grows into nothing (no player on hover, no volume, workspaces, notifications or charger); the volume and notifications pop up as usual, and a click still opens Today
- The project moved to github.com/shadowww-dev/DarkShadowShell: the updater, README, About and the installer use the new address (the old one still leads there)

## V3.95: the title's app icon, left or right
- Settings > DarkShadow bar > App icon by the title: left of the title, right of it, or off

## V3.94: the desktop menu always opens slowly, the app icon next to the title
- Desktop menu: after a few tries the opening ran in 0.17 s (the length of the animation sometimes switched only after it had started). The length is now set right when the animation starts: about 0.9 s every time, 0.17 s to close
- Bar: the window title shows its app's icon at the end

## V3.93: the desktop menu's timing
- Opening: the menu's window is put on the screen first and the animation starts a moment later, so you see all of it every time (before, its first part often ran while the window was not shown yet, so it looked rushed)
- Closing is quick now (about 0.17 s)
- Hyprland: the menu's blur and "no layer animation" rules are added by themselves when they are missing (no new login needed)

## V3.92: the desktop menu in Material 3
- The desktop menu looks and moves like the control center: tonal tiles for the quick switches, tonal rows with a round icon and an arrow for the places in Settings, a filled Settings button in your key color
- Slower, softer motion: it unfolds in about a second on Material 3's emphasized curve, the rows follow one by one; hovering and pressing ease in (shapes morph, colors blend, the arrow and the Settings gear move a little)
- Switches flip smoothly: gaming mode, night light and Do Not Disturb change at once on the click (the shape closes in, the color fills, the icon pops), then the real state is read back

## V3.91: the desktop menu opens nicer, with blur
- The desktop menu unfolds out of the pointer: a small soft pill that grows into the menu with a little spring, its corners settle, then the rows come in one after another from below and the wallpapers slide in from the side. Closing is a quick fade
- Blur behind the desktop menu (Hyprland and niri). Gaming mode and Light mode turn it off, the menu is solid then

## V3.90: the desktop menu, a bar on the side, wallpaper animations
- **Desktop menu**: right-click the desktop. Your wallpapers in a row on top (click one; All opens the rest), quick switches (next wallpaper, night light, Do Not Disturb, gaming mode, lock), then Themes, Wallpaper & colors, Edit widgets, Bar, Dock, Monitors and Settings. It opens where you clicked
- **The bar on the left or right** (Settings > DarkShadow bar > Position): a standing bar with the same modules; the clock as hours over minutes, the workspaces as a column, the tray, volume, Wi-Fi, battery ...
- **Visualizer on the bar** (Bar layout > Visualizer): a few bars that move with your music (they rest while nothing plays)
- **Wallpaper animations** (Settings > Wallpaper > Animation): Ripple (a circle grows out of your pointer), Wave, Wipe, Portal, Fade, Slide, Dissolve, Surprise me or None, and the speed; 120 fps with soft curves
- **Power modes**: Settings reads back the mode the computer really runs and says so when it did not switch; with power-profiles-daemon installed but off there is a Turn on button
- **niri**: your own keys for the shell's actions (Settings > System > Keybinds, the pencil) work on niri too; a key you pick moves the action there, and niri's default on that key gives way (one key twice would stop niri's config). The menus' blur shows the windows behind (xray off) for the desktop menu too. Configs checked with niri 25.05, 25.08, 25.11 and 26.04

## V3.89: colors for black and white wallpapers, the dock keeps its room, profile picture
- **Black, white and grey wallpapers get grey colors**, on everything (the bar, the lock screen, notifications, the game bar). Before, a black wallpaper turned the lock screen blue and a white one could turn pink: the colorfulness is now measured as chroma (HCL), which a few stars or a slight tint no longer fool
- Dynamic bar style: with grey colors the launcher is a dark circle with a light icon, and the workspaces stay grey
- **Dock: Keep room for it** (Settings > Dock, on by default): while the dock stays out, windows end next to it instead of under it, on any edge (bottom, left, right), on Hyprland and niri
- **Game bar: transparency & blur** (Settings > Gaming): how see-through it is, and the blur behind it on or off
- **Profile picture**: click your picture in Settings and pick one of your pictures right there (Pictures, Downloads, Desktop) or Browse; it is cut to a square and saved for the lock screen and login screens too
- **Never an empty desktop**: after installing, and at every login, a wallpaper is put on (the last one, or the black hole) with its colors, if none is shown yet
- Live wallpapers: mpvpaper is installed by the installer now (Arch: from the AUR like Quickshell; Fedora: from the Hyprland COPR; NixOS: with `extras`)

## V3.88: smoother scrolling, no Security page
- **Smooth scrolling** in Settings and in the wallpaper picker (SUPER + W): the page now eases toward where the wheel points, frame by frame, so a run of notches is one soft scroll instead of a jerk at each notch
- The **Security** page is gone from Settings (and its step from the installer)

## V3.87: Monitors, tray menu scrolls, black hole in fastfetch
- Settings > System: the page is now called **Monitors**; a long monitor name (the Name field, the line under the resolution) is cut with "..." instead of running out of the window
- The tray menu (right-click an app's icon in the bar) can be taller now and **scrolls** when the app has many entries; the app's name and Close app stay in place
- fastfetch (Look & Feel > Logo > Black hole): a new, cleaner black hole: round shadow, the bent light around it and the disk across it, with fading edges

## V3.86: wallpapers fix
- The new space wallpapers now really arrive: the installer never overwrote wallpapers you already had, so the old versions stayed. They have new names now (space-*.jpg), and the old space wallpapers (orbit.jpg and the first generated ones) are removed from your Wallpapers folder, only when the file is exactly the old picture

## V3.85: space wallpapers, Material style
- The 7 space wallpapers are redrawn in the same flat, layered look as the mountains: soft gradient skies, ridges, simple shapes with a glow (two black holes, galaxy, nebula, ringed planet, eclipse, aurora)

## V3.84: space wallpapers
- **7 new wallpapers, space style** (2560x1440): two black holes (warm and blue), a galaxy, a nebula, a ringed planet, an eclipse and deep space. Pick them in Settings > Wallpaper

## V3.83: the black hole
- **New logo: a black hole.** Its glowing disk turns around a black shadow, the light bends over it, bits of matter fall in. In Settings (bigger now), the welcome intro, the tour and on GitHub (animated)
- fastfetch (Settings > Desktop > Look & Feel > Logo): **Black hole** next to Moon
- The bar's launcher button can be the **black hole** (its disk turns) or the **moon** too, in the color you like: default, white, gold, ice, rose, violet or your theme's (Settings > DarkShadow bar > Launcher icon)
- Workspaces: scrolling over the workspaces (and fast or high-resolution mouse wheels) goes one workspace per notch, at most one step every 0.22 s; on slower computers the steps no longer pile up and flicker through the workspaces after you stop
- NixOS: the module has options now: `programs.shadows-shell.user = "you";` joins the input group for Infinite Desktop (SUPER + ALT + mouse); `niri`, `extras` and `enable` switch parts off. A package your nixpkgs does not have is skipped instead of stopping the rebuild (awww falls back to swww)
- Credits: Infinite Desktop is based on hyprland-infinite-desktop-v2 by Sarods2D, and the V3.23 redesign was inspired by his Iridium shell (README, Settings > About, Infinite Desktop)

## V3.80: themes, wallpapers, screens, Polish
- **Themes** (Settings > Appearance > Themes): a whole look in one click: DarkShadow, Terminal (sharp, one monospace font, no bounce), Glass (see-through islands, big corners), Neon (violet outlines), Ember and Frost. Each one sets the colors, corners, shapes, the bar, widgets, notifications, window corners and gaps, motion and the font; every part can still be changed on its own page
- **Your apps take your colors**: VSCodium / VS Code and Discord (Vesktop, Vencord, Equicord, BetterDiscord) follow the desktop's colors and change with every wallpaper or theme. Your own VS Code colors are kept and come back when you turn it off
- **Wallpaper slideshow**: a new wallpaper every 5 minutes to 3 hours, shuffled or by name, from all folders or one (Settings > Wallpaper, and Next now)
- **Live wallpapers**: put videos (.mp4, .webm, .mkv) in a wallpaper folder and pick one; it plays behind everything (mpvpaper), pauses under full-screen apps, and the colors come from a frame of it. Sound on or off
- **More wallpaper folders**: add your own folders, and Waypaper's folder shows up by itself in the wallpaper picker (SUPER + W) and Settings. One switch makes Waypaper change the shell's colors too
- **Colors from the wallpaper work on more systems**: ImageMagick 7 (magick) and older matugen versions are handled, nothing waits for an answer any more, and what went wrong is written to ~/.cache/rice/colors.log. NixOS: matugen, ImageMagick, ffmpeg and mpvpaper are now in the module
- **Screens** (Settings > System > Screen): drag your screens to how they stand on your desk (they snap together), give them names, pick the main screen for the bar, island, widgets and dock, turn a screen 90 / 180 / 270 degrees or switch it off. Every change asks to keep it and goes back by itself after 15 seconds (Hyprland and niri)
- **Polish**: Settings and the desktop (bar, island, control center, menus, widgets, wallpaper picker) are fully in Polish, with Polish days and months. Settings > System > Languages
- Infinite Desktop: SUPER + ALT + mouse tells you the one step it needs when it cannot read the mouse yet, and the installer joins the input group for you (it asks for your password)

## V3.76
- Infinite Desktop remembers your canvas: turn it off (SUPER + F) and on again and every window is back where you put it, at the same zoom and place, for each workspace. After a restart the apps find their places again too (Spotify where Spotify was, Steam where Steam was)
## V3.75
- Infinite Desktop: a window you moved yourself no longer jumps back when you then hold SUPER + ALT (the canvas always starts from where the windows really are)
- SUPER + CTRL + arrows puts the next window exactly in the middle of the screen
- SUPER + drag a window to the edge of the screen and keep going: the other windows come towards it (on again by default; it only reacts when the pointer is at the very edge, so no more sprints)
## V3.71
- Infinite Desktop: letting go of ALT while SUPER is still down (to drag a window) no longer throws the canvas forward: every hold starts from nothing, nothing carries over, and a hiccup is caught up smoothly instead of in one jump
- SUPER + drag a window to the edge pushing the other windows is now a switch, off by default (SUPER + drag just moves the window)
- Settings > Desktop > Infinite Desktop: **SUPER + ALT sensitivity** slider (0.3x to 3x; 1.00x keeps the window under the pointer)
## V3.70
- Infinite Desktop: SUPER + ALT + mouse no longer jumps ahead all of a sudden while you move slowly (the pointer was counted on top of the mouse)
## V3.69: SUPER + ALT moves the canvas, your own keys
- Infinite Desktop: **hold SUPER + ALT and move the mouse**: the canvas moves with it, every time, also at the edge of the screen. It starts with Hyprland and also works with Infinite Desktop off, on the floating windows of the workspace you are on
- By default the windows move exactly with the mouse: the window under the pointer stays under it, like holding the canvas (faster in Settings, or Reversed)
- **SUPER + drag a window to the edge of the screen**: the other windows make room, so you can take it as far as you want
- It reads the mouse and the keyboard directly, which needs the input group: the installer joins it for you (NixOS: it tells you the line for configuration.nix; --no-input-group to skip). Settings > Desktop > Infinite Desktop shows if it is ready, with the one step when it is not; `rice-infinite check` tells what it finds
- ALT + mouse button is gone, SUPER + drag (move a window) works as before
- Settings > System > **Keybinds**: the pencil next to a key gives that action other keys (Hyprland): pick Super / Ctrl / Alt / Shift, press the key, see if the keys are already used, save. It works right away; a dot shows the keys you changed, Default and Reset all bring them back
## V3.65: Infinite Desktop
- New (Hyprland): **Infinite Desktop**. Press SUPER + F (or Settings > Desktop > Infinite Desktop) and the windows of the workspace float on an endless canvas
  - CTRL + mouse wheel zooms out and in around the pointer: the windows get smaller and come together, so you see them all
  - A new window gets its own room next to the window you were in (it never lands on top of the others) and the canvas glides to it, the pointer too
  - SUPER + CTRL + arrows: go to the next window that way, the canvas glides until it is in the middle
  - SUPER + mouse wheel moves the canvas up and down, SUPER + SHIFT + wheel left and right, SUPER + ALT + arrows too, SUPER + ALT + 0 goes back to 100 %
  - Turning it off puts every window back where it was and tiles again the ones that were tiled; CTRL + wheel goes back to your apps
  - Zoom speed, how far it zooms out and the move step are in Settings; it runs inside Hyprland (no extra programs, no input group)
## V3.64: Security
- New: Settings > **Security** (next to About): a virus scan with ClamAV (quick scan or the home folder, a quarantine you can restore from, an optional quick scan every week with a notification only when something is found), a check of your system (firewall, SSH, open ports, disk encryption, screen lock when idle, restart after a kernel update, scheduled jobs, things that start by themselves), and a watch on the shell's own files that shows when something other than an update changed them
- Installing ClamAV and updating its database open a terminal with the command, so you see it and type your password there; nothing runs as root by itself
- Experimental (hidden, press Show): a hardening switch (programs can no longer read each other's memory, kernel details are hidden from them)
- The installer remembers the shell files after every install and update (Security > Shell files)
## V3.63: languages
- New: Settings > System > **Languages**: choose the language of Settings from 20: English, Polski, Português (Brasil), Español, Français, Deutsch, Italiano, Nederlands, Русский, Українська, Türkçe, Čeština, Svenska, Română, Magyar, 日本語, 한국어, 简体中文, Bahasa Indonesia, Tiếng Việt. It changes at once and is remembered
- Translated so far: the menu, the page names and captions, the search box and the first things on Home; the rest stays in English until it is translated (the words are in rice-settings/I18nData.qml: add a line to add or fix a translation)
## V3.62
- niri: the Dynamic island, menus, dock and widgets now blur what is behind them, windows too, not only the wallpaper (xray off for the shell's layers; niri 26.04 and newer)

## V3.61
- Fastfetch (Settings > Desktop > Look & Feel): DarkShadow's moon logo is bigger (as big as the Arch or NixOS logo) with craters and stars in your wallpaper's colors
- Fastfetch: the small logo looks like pfetch now: a short list in lowercase (os, host, kernel, uptime, pkgs, memory, shell, wm)

## V3.60: a new tour and Keybinds
- New tour, in Material 3: a dialog card with a picture, a progress line and Back / Next. It now explains the Dynamic island (and lights it up on your desktop): what it shows, what a left or right click opens, the volume on the wheel. Then it walks through Settings (search, the groups, Bar & launcher, Wallpaper, Desktop with Look & Feel, Keybinds, Gaming) and opens each page as it goes
- New: Settings > System > **Keybinds**: every key worth knowing, in groups (apps and menus, windows, workspaces, screenshots and recording, sound and music, desktop), drawn as keys, with a search; for Hyprland or niri. "Show me around" starts the tour again
- A fresh install starts clean: only the clock, big, in the middle of the screen (no other widgets); add more in Settings > Desktop > Widgets
- Hyprland: Super + R opens the launcher (it pointed at an app the shell does not install)
- Power modes: the installer (also on updates) installs and turns on power-profiles-daemon when it is missing (not when TLP or auto-cpufreq manage power)

## V3.59
- Settings scrolls faster by default, and the scroll speed on Home works again: the "Try it" box no longer stops the page (at its top or bottom the page scrolls on)
- Home: the "Make yourself at home" tips card is gone
- Installer (Arch): no more yes/no question about yay. paru or yay are used when you have one; without one, yay is set up only if the shell needs a package that your Arch has only in the AUR (Quickshell, awww, matugen). The rest is skipped: the Bibata cursor comes from GitHub instead. `--aur` gets yay and everything, `--no-aur` never builds it
- Fix: no mouse cursor after installing without yay: the Bibata cursor is an AUR package, so it was missing and nothing took its place. Now the Adwaita cursor comes from the official repositories as a backup, and the shell downloads Bibata from GitHub by itself whenever it is missing (also at every login)
- Fix: no mouse cursor on PCs where the screen is plugged into an NVIDIA card while the processor's graphics are on too: the installer now looks at which card drives the screens and draws the cursor in software then (log out and back in once after the update)

## V3.58: Look & Feel
- New: Settings > Desktop > **Look & Feel**
  - **Fastfetch**: a live preview of your terminal with fastfetch in it; show it whenever a terminal opens; the logo (your distro's, a small one, DarkShadow's moon or your wallpaper as a picture in kitty, Ghostty and WezTerm), how much it tells, words or icons as labels, and your wallpaper's colors
  - **Shell**: fish, zsh or bash for your terminals (zsh and bash get the same prompt as fish, history and completion); a button makes it your login shell too; Install for the ones you do not have
  - **Terminal**: kitty, foot, Alacritty, Ghostty, WezTerm or Konsole for Super + Return, the Wi-Fi menu and updates (Hyprland and niri). foot, Alacritty and Ghostty get the wallpaper's colors, your monospace font and kitty's see-through background, and change with the wallpaper; your own config files are kept
- Fix: scrolling with a touchpad: pages in Settings jumped back a little while scrolling; now they follow your fingers (the mouse wheel still glides). The launcher, the Wi-Fi and Bluetooth menus follow the fingers too
- Fix: a touchpad swipe over the bar's workspaces went through all of them; now one swipe is one workspace. The volume (bar, island, menus) and the sliders move as far as your fingers do, not 4 % per tiny touchpad step

## V3.57: niri fixes
- niri: no more pale bands and boxes of blur around things: the blur sits exactly behind the menus (sound, Bluetooth, Wi-Fi, power ...), the bar's island (not its sides) and the widgets' cards (widgets drawn as a shape, like the clock and the gauges, get no square behind them), so menus have the same gap under the bar as the island's card
- niri: the island follows workspace switches as quickly as on Hyprland (the bar now reads niri's few events for one switch once, and a window's title changing no longer wakes the whole bar)
- niri: blurred wallpaper around the workspaces in the overview (Win + Tab)
- niri: notifications come from the shell again (Settings > Notifications) instead of niri's plain blue boxes: other notification programs (mako, dunst) that started by themselves are stopped, and D-Bus starts ours from now on
- Settings opens faster (most of all on laptops): only the page you are on is made at first, and a search makes the rest

## V3.56
- Settings opens much faster: pages are made when you go to them (or one after another just after it opens) instead of all at once
- Settings is frosted again: more see-through, so the blur behind it shows (Hyprland), and niri blurs it too
- The tray hides the network and Bluetooth applets when the bar shows Wi-Fi and Bluetooth itself (niri and some distros start them: a second Wi-Fi icon next to the battery)
- niri: no grain in the blur (it looked pixelated), and the bar's blur no longer changes shape on every frame of the island's animations

## V3.55
- Smoother on laptops: the slowly turning shapes of the widgets and the island move in small steps instead of redrawing the screen on every frame, and the widgets' motion (and the visualizer) pauses while windows cover the desktop
- Fix: on laptops with Intel or AMD graphics next to an NVIDIA card the cursor was drawn in software, which made the desktop feel like 60 Hz on a 144 Hz screen; it is only done when NVIDIA alone drives the screens now
- Fix: the launcher could stay on screen after starting an app (and Esc did not close it); menus and panels always go away when closed, even if their animation stalls

## V3.54
- Fix (niri): the wallpaper was grey (it only showed for a moment while switching workspaces): workspaces are see-through now, so the wallpaper shows and stays still, also in the overview
- Fix (niri): screens start at size 100 % like on Hyprland (niri chose 150 % on sharp laptop screens)
- New: Settings > System > Screen: the size of everything, the resolution and the refresh rate of each screen (Hyprland and niri); a change goes back by itself after 15 seconds unless you press Keep
- Fix: the island's card (a click on the clock) closed at once while a window was open, like Settings

## V3.53
- Bug fixes: videos in Brave, Chrome and Discord played sound with a black picture and GIFs did not play (graphics settings an earlier update added for NVIDIA cards broke them; log out and back in once after this update)
- Bug fixes: desktop widgets made the whole desktop stutter on laptops with many of them (each widget covered the whole screen; now each one is only as big as itself)

## V3.52: niri
- **niri support**: the shell runs on niri as well as on Hyprland, on Arch, CachyOS, Fedora and NixOS. The installer asks which one you want (Hyprland, niri or both, picked on the login screen); `--wm=niri` skips the question
- The shell writes niri's config from your settings (`rice-niri`): keys (the same as on Hyprland, plus niri's columns and overview), borders in your wallpaper colors, rounded corners, shadows, blur, gaps, animation styles (calm, lively, bouncy, snappy, minimal) and speed, keyboard layouts, monitors, your own keybinds and autostart, the cursor, gaming mode and Lite mode. It fits your niri version and is checked with `niri validate` before it is used; your own settings go in `~/.config/niri/user.kdl`
- Blur on niri (26.04+): the bar, the island and its cards, the launcher, menus, the control center, the dock, widgets, pop-ups and the terminal get blur exactly where they are see-through
- The bar's workspaces, the island, the game bar and the widgets read niri's workspaces and windows; Settings shows niri where it said Hyprland (window settings, System, About) and hides what only Hyprland has
- Lock screen, idle timers (screens off), log out, the Settings window size and the tour, recording and screenshots work on niri
- `rice-wm`: one command the scripts ask about the window manager (which one runs, workspaces, monitors, screens on / off, log out)
- NixOS: the module turns on niri too (`programs.niri.enable = false;` leaves it out); Fedora gets the newest niri from its author's COPR

## V3.51
- Lock screen: the password shapes are bigger, full and in your accent; they grow in slowly and turn a little as they settle (Material 3 motion), ripple like Google's loader while the password is checked and turn red on a wrong one

## V3.50
- Fix: you could not type your password on the lock screen (and it showed without your wallpaper and settings): the screens of the lock did not reach its state, so the field stayed read-only. They get it through a shared object now

## V3.49
- Fix: the lock screen got the keys but did not type them on some setups: every key is handled by the lock screen itself now (letters and digits even when Qt gives a key without its text)

## V3.48
- Lock screen: the password field keeps asking for the focus until it has it (it could get lost when the lock window appears), the lock window asks Hyprland to be activated, and keys that reach the lock screen but not the field go into the field anyway

## V3.47
- Lock screen: it takes the keyboard again as soon as Hyprland hands it over (Hyprland can do that a moment after the lock)
- Lock screen: if no key reaches it, a button "Keyboard not working?" appears (bottom left): the session stays locked and hyprlock takes over, so you can always type your password
- `rice-lock test`: locks for real but unlocks itself after 30 seconds, to try the lock screen without risk; what happened is in ~/.cache/rice/lockscreen.log

## V3.46
- Fix: the lock screen did not take what you typed on some setups. The password now goes through a real text field (input methods such as fcitx included), which keeps the focus whatever you click, and there is an arrow button next to it
- Fix: the lock screen sat out of place on some screens: everything is one column in the middle now, the clock gets smaller on small screens and the chips wrap instead of running off
- The lock screen writes what happens (keyboard, PAM) to ~/.cache/rice/lockscreen.log, and the preview to lockscreen-preview.log

## V3.45
- A new lock screen, the shell's own, in Material 3 (Settings > Idle & Lockscreen):
  - your wallpaper or what was on the screen, blurred and dimmed, coming in slowly
  - the clock big, stacked, minimal or inside your shape (turning slowly), in your clock font
  - the day, a greeting with your picture in your shape, chips for the weather, the battery, waiting notifications and CPU / RAM in rings
  - the music with the cover in your shape, a wavy line you can drag and its buttons
  - the password shows as small shapes that pop in; a wave runs while it is checked, a wrong one shakes
  - Sleep, Restart and Shut down (red); Restart and Shut down ask for a second click
  - Preview shows it in a window without locking (Esc closes it)
- Safe: it locks with the Wayland session-lock protocol and checks the password with PAM, like hyprlock. If it does not lock within a few seconds, or ever stops while locked, hyprlock takes over, so you are never locked out. hyprlock stays one switch away (Lock screen: hyprlock)
- SUPER + L, the power menu, the hot corner and the idle timer all use it
- NixOS: the module sets up the PAM service for the lock screen

## V3.44
- Fix: Google icons that should be filled showed the wrong picture (a globe instead of info, a broken play arrow, odd gears and checks): Qt mixed up the glyphs of the filled Material Symbols. Icons are drawn as the font draws them now

## V3.43
- Fix (Fedora, CachyOS and others): one Hyprland setting or keybind that a Hyprland build does not know stopped the whole config, so Hyprland fell back to its emergency config (only SUPER + Enter worked, no bar). Such settings are skipped now and the rest works; what was skipped is in ~/.cache/rice/hypr-errors.log, with a notification
- Fix: no cursor when the chosen cursor theme was not installed: a theme that is on the computer is used instead
- NVIDIA: the installer turns on the software cursor (a hardware cursor is often invisible on NVIDIA) and sets the NVIDIA video variables
- The monitor uses its preferred mode instead of 1920x1080 at 144 Hz

## V3.42
- Visualizer: it listens to what your speakers or headphones play (it could pick up the microphone, so it only moved on claps) and follows you when you switch the output; it is livelier (30 frames a second, less smoothing)
- Visualizer: How high they go: Calm, Normal, High or Max (Edit mode > Visualizer)
- Quicker motion: workspaces, the island's faces and width, the card, the modules of the bar and the widgets coming back

## V3.41
- Fix: while the screen was recorded the island could not be clicked open; a click anywhere on the island works now, whatever it shows
- Fix: switching workspace made the bar shake at the end: the island and the notch change their width calmly now, without a bounce
- The island's faces no longer show on top of each other: the old one leaves first, then the new one comes in

## V3.40
- Notch: with the island in it, the island sits exactly in the middle of the screen and the notch reaches as far to both sides
- The weather beside the time (and in Today) is a solid icon, all in your key color

## V3.39
- Bug fixes

## V3.38
- The dashboard is gone for good: the bar's island does its work. Settings > Dashboard became Settings > Dynamic island, with a live picture of the island and new options: weather and date beside the time, the charger as a wave (laptops), which tab a click opens (Today, System, About) and how fast the card closes
- Every workspace has its own color (your key color turned around the color wheel), in the bar and in the island
- Wi-Fi, Bluetooth, notifications and power get a line under them while you point at them, like the volume (red under power)
- The time sits straight between the modules beside it
- Shut down is red in the power menu
- Visualizer (cava): 16, 32, 48 or 64 bars, square, rounded or pill ends, thin, normal or wide spaces, and up to 700 px tall (Edit mode > Visualizer)
- Widgets: wavy rings in Resources, Storage, Battery and Focus, a wavy progress line you can drag in Music, your shape behind the weather icon, today in the calendar, the play button and the ring icons; they come back softly and leave quicker

## V3.37
- The island opens slower and softer when you point at it or click it (and closes a little quicker), its content fades in more gently
- The island and the bar sit on whole pixels: the time is sharp and straight in the notch
- Wallpaper picker: the wheel scrolls faster; cards come in one after another again when you type, a ripple of your key color and a small pop when you pick one, the check grows in, and the cards at the edges shrink and fade a little while you scroll

## V3.36
- The island is the clock now: the Clock module is gone and your old clock became the island. A new install starts with the Dynamic style and the island in the middle
- Bar layout: five ready-made Material 3 layouts (Island, Focus, Everything, Minimal, All in the middle) to start from
- The island's card has an About tab: your system with its logo in your shape, DarkShadow's Shell and its updates (Update now, Check)
- The card is the island growing: size, place and corners morph together with a little bounce; the island gives a small squeeze when something new comes in
- Esc, a click on the desktop or on another window closes the island's card and the tray menu
- Tray: right-click an app for its menu in the shell's look (submenus, checks) with Close app at the bottom, which ends the app in the background
- Wallpaper picker: the wheel scrolls farther and glides, the arrow keys glide too

## V3.35
- Bug fixes

## V3.34
- The dashboard moved into the bar. Click the clock (or press SUPER + ALT + D) and a Material 3 card grows out of the bar:
  - Today: the date, the weather with its icon in your shape, the day as a wavy line, and the month with today in your shape
  - System: CPU, GPU and RAM in wavy rings (with their heat), the disk as a wave, how long the computer has been on
  - Music: the player; tabs slide on a pill of your key color, the card closes a moment after the pointer leaves
  - right-click the clock for System; it works in every bar style, with or without the island
- SUPER + W opens a new wallpaper picker: a sheet with search, shuffle, arrow keys and Enter, the current one with a check in your shape
- SUPER + A opens the control center
- The classic dashboard is off; Settings > Dashboard > Classic dashboard brings it back (and it stays while the bar is Waybar)
- Updates swap the shell's changed files in all at once, so Quickshell never shows a "Config reload failed" in the middle of an update

## V3.33
- The island's player and notifications open as a card just beside the bar (below it, or above a bar at the bottom), so the bar is never covered; the island in the bar keeps showing the time
- Fix: the player card stayed open: it closes a moment after the pointer leaves, a clicked one after a few seconds, and by itself when nothing plays any more
- Tray icons are bigger (18 px) and adjustable: Settings > DarkShadow bar > Tray icon size (12 to 28)

## V3.32
- Fix: the island was cut off when it grew in the notch (and in every style but Dynamic): the bar keeps room for it now
- The island's content comes in once the shape has grown, so a card is never seen cut while it opens or closes
- In the notch, and in a pill with other modules, the island has no darker band of its own at rest
- The island shows workspaces in your workspace style (dots, Pac-Man, letters, numbers), and Dynamic puts the active letter or number in a pill of your key color

## V3.31
- The island is a module now: Settings > Bar layout (or Edit mode > Bar) puts it in any zone, with other modules beside it (workspaces, launcher, clock ...), in every bar style. In the notch it is part of the notch and grows out of it; when it shows the volume it makes room and the modules beside it slide away
- Dynamic without the island in its layout keeps it in the middle, as before
- Settings > DarkShadow bar > Dynamic island shows whenever the island is on the bar

## V3.30
- The Google bar style is gone; Dynamic has its look (a bar that used Google switches to Dynamic)
- Changing the bar style is animated: the old look folds away and the new one settles in
- Bar layout: modules grow in when they appear and fold away when they go, and the others slide to make room (music that pauses or starts, a module you add)
- Notch: transparency and blur work (it was nearly solid before); its shadow stays outside the shape
- Dynamic: the island has no outline any more

## V3.29
- New bar style: Dynamic. The Google look, and in the middle an island that grows out of the clock on springs:
  - point at it (or click it) while music plays: the player, with the cover in your shape, a wavy progress line you can drag and a play button that changes shape while it plays
  - the volume or the microphone changes: a wavy level you can drag (instead of the pop-up at the bottom)
  - you switch workspace: which one you are on
  - a notification comes in: its icon in your shape and a wave that runs out while it stays (urgent ones still pop up)
  - the screen is recorded: the time, the microphone and stop
  - while music plays the clock gets a small cover and an equalizer; scroll on it for the volume, right-click it for the dashboard
- Settings > DarkShadow bar > Dynamic island: music on hover, volume, workspaces and notifications, each on or off
- The idea of an island that grows from the clock comes from hyprdots by fedyaqq34356; ours is written from scratch in the shell's own Material 3 style

## V3.28
- New bar style: Google. Tonal pills in your theme color, the launcher and the active workspace (with its number) in your key color, the time and date in a tinted pill of their own, soft highlights when you point at a module. Settings > DarkShadow bar > Style, or Edit mode > Bar

## V3.27
- Bug fixes

## V3.26
- Bug fixes

## V3.25
- Bug fixes

## V3.24
- Notifications, rebuilt in the Google style: the shell shows them itself now. Pop-ups look like the control center (the app's icon in your shape, the time, pictures, action buttons, a thin line that shows how long it stays), grow in from their side and slide away; pointing at one keeps it, important ones wait until you close them. The update switches to them once; swaync stays one click away (Settings > Notifications > Shown by)
- Control center (SUPER + N or the bell on the bar): switches, sliders, music with a wavy, seekable progress line, and your notifications; smooth Material 3 motion when it opens and between Control and Overview
- Settings > Notifications, cleaned up: a live preview, Send a test, where pop-ups appear, their width, time on screen, six themes for pop-ups and the control center (DarkShadow, Graphite, Black, Slate, Tinted, Light), text size, corners, and transparency and blur for each. The old notification-center style, layout, widgets and colors are gone
- Dock: its own app menu (search, pin your favourite apps with the pin or a right click). Settings > Dock > Pinned apps: add, remove and reorder them; App menu off opens the launcher as before
- Your shape everywhere: the shape you pick in Settings > Appearance > Shapes is used for notification icons, the control center, menus, loaders and the dock
- Edit mode (SUPER + ALT + W) has a new panel on the left: your widgets as chips (how many are active), quick settings (blur, auto-hide, grid, widget style, font), the bar (style, position, auto-hide, modules) and the visualizer (on, top or bottom edge, style, colors, height)
- New desktop widgets: Sky, Now playing, Player, Play button, Lyrics (synced lyrics from LRCLIB), Storage, CPU · GPU · RAM and a water gauge
- Bar: the Notch style holds the whole bar, and recording shows as an island in the notch. Fix: recording no longer stays stuck on red, and the microphone mute works
- Game bar: redesigned with FPS (games started with MangoHud), CPU, GPU, RAM and ping; slower, smoother motion
- Wavy progress lines and rings in the player, lyrics, play button, control center and gauges (Settings > Appearance > Components > Wavy progress)
- Settings: a shape library (36 shapes), Windows, Language & region (language, clock format, Celsius or Fahrenheit), System, keyboard variants, bounce, and smoother page and window motion
- Wi-Fi, Bluetooth, volume and power menus open with softer motion; Bluetooth shows a loader in your shape while it scans
- Soft shadows under the shell's panels

## V3.23
- A new look everywhere, in the spirit of Material 3 / Google: tonal colors made from your theme, round shapes, springy motion and Google icons (Material Symbols)
- Google Sans Flex is the interface font of the whole shell: Settings, the bar, the launcher, notifications, the dashboard, the desktop widgets and the lock screen. Google Sans Code is used for codes and numbers in Settings. Both are open source (SIL Open Font License); the installer and `rice-fonts` download them. The terminal (kitty) keeps JetBrainsMono Nerd Font. Older setups that used JetBrains everywhere move to Google Sans Flex once (`font-set migrate`); a font you picked yourself stays
- Settings, redesigned: a navigation rail with groups and tabs, a bigger window, search, Google icons, new previews and theme tiles
- Settings > Wallpaper: your wallpaper, the colors it gives the shell, and all your wallpapers to pick from
- Settings > Appearance > Colors: every color role (primary, containers, tertiary, error, the surfaces) made from your key color; click one to copy it
- Settings > Appearance > Fonts: typography with a text size, heavier headings, rounded letters (Google Sans Flex has a roundness axis) and the 15 Material 3 type roles in your fonts, with your own sample text
- Settings > Appearance > Components: icons in switches, corner shape (round, soft, square), slider thickness, wavy progress lines and loaders with their thickness, and every kind of button, all with live samples
- Settings > Motion: Hyprland animations moved here, with styles (calm, lively, bouncy, snappy, minimal). New: the spring and easing curves drawn as graphs you can play, the duration tokens, and a shape you can throw that springs back home
- Settings > System > Keyboard: up to four keyboard layouts, the one in use now, a button for the next one, the keys that switch them, and a search over every layout of your computer
- Settings > Gaming hub (gaming mode and what stays on, power mode, your game launchers and tools) and Settings > About
- Game bar: SUPER + G opens a panel over your game with CPU and GPU in soft shapes with wavy rings (and their heat), RAM, ping, screenshot, recording, microphone, power mode, gaming mode, Do Not Disturb, volume and brightness. It reads anything only while it is open
- Desktop widgets: Gauge (CPU, RAM, GPU, CPU heat or battery in a pentagon, cookie, flower, clover, hexagon, sun or circle, with a wavy ring) and Date (today in a flower, cookie, clover ...). Add them in the widget editor (SUPER + ALT + W)
- Bar: a new Notch style (the middle grows out of the screen edge, the sides are islands), Auto-hide (the bar slides away and windows get the space, point at the edge to bring it back) and a soft shadow under it
- Hyprland > Layout: window magnet: floating windows snap to each other and to the screen edges, with how close they must come
- Sounds: the new Pebble click sounds are the default
- `rice-stats` also reports CPU and GPU temperature, and the GPU load of AMD and Intel cards

## V3.22
- Fix: after an update the DarkShadow bar did not show up (with no bar.json yet it counted as off). It is on now when you never chose otherwise, and the installer switches it on once for everyone coming from an older version
- Much less work in the background, most noticeable on laptops: the shell used to start small programs about 30 times a second to check whether the launcher, the menus or the dashboard should open and whether a setting changed. It now watches those files and reads them only when they change
- The visualizer does no drawing while it is silent, and cava runs at 24 frames a second instead of 30
- Launcher: its settings (transparency, blur, theme ...) are read again as soon as you change them in Settings > Launcher
- The dock is rebuilt: on the bottom, left and right edge alike it slides in and out without resizing its window, a thin strip at the edge brings it back, and every setting on the Dock page works on every edge. Icons are drawn directly (the grey effect only when Tint is on)
- Hyprland: outer gaps are 5 by default (the update changes the old default 12 to 5; Settings > Hyprland sets another value)
- The installer no longer installs overskride (Bluetooth has its own menu on the bar) or swayosd (the shell shows the volume itself)
- SUPER + A opens the dashboard on its Control tab (it opened the hot corner, which is gone)

## V3.21
- Bar: the workspace dots are back to the pill that stretches, a bit bigger
- Bar: left click on the volume icon opens the sound menu, right click mutes. Wi-Fi, Bluetooth and power open only their own menus now (the old overskride / nmtui windows and the right-click lock are gone)
- Dashboard: a Settings card in the Control tab opens the Settings app right on the page you want (Settings, Bar, Launcher, Theme, Notifications, Dock). `rice-settings PAGE` does the same. An older saved Control layout is reset once so the card shows up
- Dashboard: the colors stand out on the blurred glass: the accent is made light enough even when the wallpaper is dark, and the cards, lines and grey text are a little brighter
- Notifications: no outlines around popups and the panel any more (Settings > Notifications > Border brings them back)
- Hot corners are gone: the page left Settings and the hot corner no longer runs

## V3.20
- Bar: switching workspaces stays smooth even when the desktop widgets come back on an empty workspace. The workspaces keep one width each and a single marker slides to the active one; the sliding runs on the graphics thread now (Pac-Man too)
- Bar: the launcher button looks like before V3.19 again

## V3.19
- Rofi is gone: the DarkShadow Launcher is the only launcher. The Settings page Rofi is called Launcher (same themes, styles and options), rofi is no longer installed, and the old Rofi theme is taken out of rofi's config. Questions like "Log out?" use a small zenity window instead of rofi
- Sound menu: right click the volume icon on the bar for a menu under it (like a small pavucontrol): volume, where the sound goes (speakers, headphones ...), the microphone and the volume of every app that plays. Left click still mutes
- Volume pop-up: whenever the volume changes (keys, headphones, the bar) a small pill near the bottom shows how loud it is, and the microphone shows when you mute it
- Volume keys: laptop and keyboard volume keys, headphone buttons (XF86AudioRaiseVolume / LowerVolume / Mute / MicMute) work now, as do SUPER + F10 / F11 / F12 and ALT + [ / ]. The update adds them to your hyprland.lua (a copy is kept)
- Bar: the Wi-Fi, Bluetooth, power and sound menus are more see-through with a light blur
- Bar: workspaces react to clicks again (Hyprland's Lua config needs a different command), the dots are bigger and white, and clicking them makes no sound
- Bar: in the Pills style the launcher logo and the other icons sit in round pills
- Dock: fixed on the left and right edge (it no longer gets stuck half outside the screen). The top edge is gone, it belongs to the bar; a dock at the top moves to the bottom
- Settings: the live previews at the top of some pages are off; Home > Settings > Previews turns them on

## V3.18
- Power button of the bar opens a small power menu: Lock, Sleep, Log out, Restart and Shut down (the last three need a second click). Lock uses hyprlock and never logs you out; right click locks at once
- Launcher icon: pick the logo on the bar in Settings > DarkShadow bar > Launcher icon: Auto (the logo of your system), Arch, Gentoo, Fedora, Debian, Ubuntu, NixOS, CachyOS, EndeavourOS, Manjaro, Mint, openSUSE, Void, Alpine, Pop!_OS and more, or the app grid
- Workspaces: new style Numbers (1 2 3 4 5), bigger dots, and Pac-Man is white and only runs (chomping) to the workspace you switch to instead of chewing all the time
- DarkShadow Launcher uses the same font and text size as Rofi

## V3.17
- **DarkShadow bar**, a new bar made in Quickshell, replaces Waybar. Workspaces as dots, **Pac-Man** or letters, the title of the window, a clock that shows the date when you point at it, music, tray, volume (scroll to change, click to mute), Bluetooth, Wi-Fi, battery, notifications and power (click locks the screen, right click opens the log out menu). Four styles: Flat, Island, **Islands** (an island for each side, the new default) and **Pills** (a pill for every module). Top or bottom, size, transparency and blur. Settings > DarkShadow bar and Bar layout (drag the modules between left, center and right)
- The Wi-Fi and Bluetooth icons of the bar open a menu under them: networks with their signal, connect (it asks for the password), disconnect, forget, Wi-Fi / Bluetooth on and off, and your Bluetooth devices with their battery, pairing a new one. Right click opens the old menus
- **DarkShadow Launcher**, a new app launcher built into the shell, instead of Rofi: it searches your apps (the ones you use most come first), calculates ("2+2", Enter copies the result) and can search the web. Smooth scrolling and a quiet animation as you type. It uses the same settings as Rofi (Settings > Rofi): theme, list, grid, bar or the new **Split** style (wallpaper on the left, the apps you use most as round buttons), position, width, corners, transparency, icons. Alt + Space, the dock and the hot corner open it. The Split style is in Rofi too. Settings > Rofi > Launcher > Engine brings Rofi back
- The update switches the autostart of Hyprland to the new bar and the new launcher (a copy of hyprland.lua is kept as hyprland.lua.bak-bar). `rice-bar off` goes back to Waybar

## V3.16
- The installer copies files that are new on your computer first and the changed ones after them, so Quickshell no longer shows "Config reload failed: X is not a type" for a moment while an update that adds new files is installed

## V3.15
- Two new Dashboard tabs fill the column: **Control** (switches for Wi-Fi, Bluetooth, Do not disturb, Night light, Sound, Microphone, Stay awake and Airplane, volume and brightness sliders, power mode, screenshot and recording buttons, lock / sleep / log out / restart / shut down) and **Tasks** (focus timer that keeps running while the dashboard is closed, to-do list with typing, and the note). Switch them on or off in Settings > Dashboard > Tabs (they are switched on once by this update). Keys 1-9 switch tabs
- The Dashboard tab is new, a day board: big time with a line for the day that has passed, weather, round switches, the week you are in, music as a turning record, a Pulse card with bars for CPU, GPU, RAM and disk (and the battery), and your first tasks to tick. The older cards (You, Clock, Calendar, Usage, Music) can still be added in edit mode. An old saved Dashboard layout is reset once
- Every card of the new tabs can be moved and resized in edit mode, like the rest

## V3.14
- Dashboard at the left or right is a smaller panel now, floating in the middle of the screen edge, with no empty space below the cards (it does not run the whole screen height any more)
- Dashboard at the left or right: the tabs are back in one compact pill like the bar at the bottom, no lines and no gaps, with the edit pencil right under it
- About tab can be edited now: move, remove and add cards, and pull the handles to resize them into empty places (it has two rows now, the tall panel has as many as fit)
- About: two new cards to add, Software (kernel, packages, WM, shell, Quickshell) and Session (uptime, display)
- Music card: in a narrow card the cover sits on top and the buttons stay inside the card

## V3.12
- Dashboard at the left or right: the tab column has no empty gap any more, the four tabs share its whole height with thin lines between them, and the edit pencil sits at the bottom of it
- Dock: new switch Now playing text (Settings > Dock): the song title and artist are written in the dock while something plays; Media player keeps the cover and the play button. On a left or right dock the text sits under the cover
- The Settings page Interface is called Dock now (it only had the dock)

## V3.11
- Dashboard on the left or right edge is a tall panel now, top to bottom of the screen (like the notification center): a narrow column of tabs on its left side (Dashboard and the edit pencil at the top, Wallpaper, Performance and About at the bottom) and the cards next to it
- The cards have their own tall layouts for the side positions (Dashboard, Performance, About), and Reset restores them. Wallpapers scroll up and down in the tall panel
- At the bottom and top nothing changed

## V3.10
- Dashboard opens from any edge (Settings > Dashboard > Position: Bottom, Top, Left, Right), like the notification center. On the left and right the tabs (Dashboard, Wallpaper, Performance, About) are a column on the left side of the panel and the cards are on the right of it
- Dock: Settings > Interface > Dock > Position puts it on the bottom, top, left or right edge. On the sides it becomes a column (the song shows only the cover and the play button)

## V3.09
- Notification center (Deck) can open from any edge: Settings > Notifications > Side is Left, Right, Top or Bottom (top and bottom use the Height setting)
- Dashboard can open from the left edge: Settings > Dashboard > Position is Bottom or Left. On the left it floats in the middle of the screen edge and slides in from it; touching the left edge opens it

## V3.08
- Home > Settings > Profiles: Performance, Balanced and Power saver as three cards at the top of Settings; click one to switch, the current one is lit. Only the modes your computer has are shown, and a hint appears when power-profiles-daemon is not running. Works on laptops and desktop PCs
- The power modes are gone from the notification center (they were too big there)

## V3.07
- Home > Settings > Window size: a live preview, a small screen with a small window that grows and shrinks while you drag the slider (with the size in pixels)
- The Settings window really changes size now: new helper rice-settings-size asks Hyprland for the size, checks that it worked and centers the window (the log is in ~/.cache/rice/settings-size.log)

## V3.06
- Home > Settings > Window size: a slider (75 % to 150 %) makes the Settings window smaller or bigger, and it remembers the size

## V3.05
- The Settings window is smaller again: under half of a 1080p screen (about 880 x 630), still never bigger than your screen

## V3.04
- Update card (dashboard About tab) and the update notification: long lines of "What's new" wrap to a second line instead of ending in "..."

## V3.03
- Settings has a tidy sidebar now: Home, then five groups with an arrow (Appearance, Desktop, Bar & launcher, Sound & alerts, System). Touch an arrow to open the pages inside. The group of the page you are on opens by itself
- Home: "Bar & Screen" is now "Settings": Bar transparency, Window blur and Animations on or off, Settings scroll speed with a box to try it, and Mouse & touchpad (mouse wheel speed, touchpad scroll speed, natural scrolling, tap to click, pointer speed)
- hypr-set knows the input options above (hypr-set set input.scroll_factor 1.5)

## V3.02
- Notification center styles (Settings > Notifications): DarkShadow Shell (frosted glass), Dark (no blur, no transparency) and Google (soft tonal surfaces in your Theme color, big round corners, pill buttons). Pick one with the three preview tiles
- Notifications no longer pile on top of each other: they are one flat list now, and every card is solid, so the text of one card never shows through another
- New widget sounds: the calendar has its own page-turn sound (one for next month, another for the previous one), To-do has an add sound and a remove sound. All 7 sound packs have them (Settings > Sfx & sounds)
- The widget editor no longer plays a "ding" when you finish moving or resizing a widget: only the pick and the snapping sounds are left
- Click the desktop (or anywhere outside) to leave typing in To-do and Note, the keyboard goes back to your windows. Esc works too
- Focus timer: the buttons sit a little higher, with more room above the session dots

## V3.01
- Widgets are clicked, not dragged: the calendar arrows, the Focus timer, the To-do list and the Note now take your clicks on the desktop. Moving and resizing happen in the widget editor only (SUPER + ALT + W)
- Sounds in the widgets (Settings > Sfx & sounds): a click on every button and arrow, a switch sound when you tick or untick a task or start and pause the timer, typing sounds in To-do and Note, and a chime when a task is added or a Focus session ends
- Visualizer bars look like cava in a terminal (straight bars, one soft fade from the base to the tip)
- Fix: "TodoWidget is not a type" after an update. The installer and apply.sh copy shell.qml last now, so Quickshell never reloads a config that points to widget files that are not there yet. If you still see the message once: rice-desktop restart

## V3.00
- Widgets turn light or dark with your wallpaper: behind each widget the wallpaper is measured, and on a light part you get dark text on a light card, on a dark part light text on a dark card (the clock, the calendar with its dates of other months, every widget). Settings > Widgets > Adapt to the wallpaper turns it off
- Widget styles (Settings > Widgets > Theme): DarkShadow (frosted glass, black and white), Google (soft cards in your Theme color, round corners) and Outline (no fill, a thin line)
- The visualizer bars look like cava in a terminal: straight thin bars with one soft fade from the base to the tip (Bars and Mirror). Colors: your Theme color, Gradient, Rainbow, or white (black on a light wallpaper). Pick them in the widget editor or in Settings > Widgets > Visualizer
- The clock widget has the lock screen clock fonts (Bebas Neue, Orbitron, Outfit, Space Grotesk, Unbounded, Big Shoulders; they download when you pick them) and a new Line style, with the date
- New widgets: To-do (tick tasks, add them on the desktop, in Settings or with rice-todo), Focus timer (work and break with a notification) and Note
- To-do and Note take the keyboard when you click them

## V2.98
- New Recorder page in Settings (after Hyprland): resolution (Native, 1440p, 1080p, 720p), frame rate (30 or 60 fps), quality (Best, High, Balanced, Small), encoder (CPU or GPU with VAAPI), sound and microphone, a preview with the size per minute, and your recent recordings with a picture (click to play). Recordings were soft before because wf-recorder's own defaults were used; the new default is High quality at 60 fps. If wf-recorder does not take the new settings, it records with its own defaults and tells you
- Settings: "Desktop" is now "Widgets", and the window is a little smaller
- Home: Auto-hide widgets next to Light mode (same switch as in Widgets)
- Record sound and Record microphone moved from Hot corners to Recorder

## V2.97
- Screen recording never fails because of sound: if wf-recorder stops right away with the chosen sound, it tries the default input, then records without sound, and tells you. What happened is in ~/.cache/rice/record.log

## V2.96
- Screen recordings (SUPER + SHIFT + R, the hot corner) have sound: the sound of your computer is on by default. Before, sound was off, and when on it took the microphone instead of games and videos. Settings > Hot corners: Record sound, Record microphone

## V2.95
- Fix: swaync (0.12) crashed a few moments after every notification and came back empty, so clicked notifications, the dot on the bell and the notification center were all gone. It crashes when a script it runs keeps its output open (our notification sound did). The sound and the "keep clicked notifications" scripts now let go of it at once

## V2.94
- Light mode keeps the animations (windows, workspaces, the falling stars in Settings); it still turns off blur, transparency and shadows, stops the visualizer and rests the widgets while a window covers them

## V2.93
- Notifications you click stay in the notification center again, and Clear all clears them. swaync can start with a short PATH (D-Bus or systemd, often on NixOS), so the script that keeps them did not run; it now goes through rice-run, and posts the copy with notify-send, busctl or gdbus, whichever is there. Run rice-notify doctor if a clicked notification is still gone
- Interface sounds play on the first click: a sound still loading (right after you pick a pack) is played another way, and every sound wakes the audio output once when it loads
- Sounds in more places: clicks on Waybar, the dock and the widget editor, and soft ticks while you drag or resize a widget
- Settings: bigger window that fits your screen (no fixed 900x640 size from Hyprland any more), no separator lines, and the falling stars go across the whole window. Turn them off on Home (Falling stars)
- Light mode lives on Home now; Services no longer has the Performance section

## V2.92
- Light mode, right on Home (also in Services): one switch for slower computers. No blur, transparency, animations or shadows; the visualizer stops and the desktop widgets rest while a window covers them. Search finds it with "light", "slow", "lag" or "performance"
- Desktop widgets no longer hide when only floating windows are open (Settings, pop-ups, a floating-only layout); only tiled windows hide them with "Auto-hide widgets"

## V2.91
- Sounds stay quiet when "Sounds of your desktop" is off (also right after opening Settings or the hot corner)
- No more sound when Settings, the dashboard or the hot corner open and close
- Four new sound packs: Tap (crisp, modern), Pluck (a small harp), Keys (a mechanical keyboard) and Retro (8-bit), next to Soft, Crystal and Bubble; Tap is the new default
- Four new notification sounds: Ping, Harp, Keys and Ripple
- New music for the welcome intro and the tour (soft electric piano and a little music box) and new intro sounds; every step of the tour has a soft ping

## V2.90
- New page Sfx & sounds (right after Home): soft interface sounds in the shell's own parts (clicks, switches, sliders, typing, opening and closing panels), three sound packs (Soft, Crystal, Bubble), volume, every sound on or off; the notification sound moved here
- Quiet, friendly music during the welcome intro and the Settings tour, plus sounds for the intro
- Search in Settings: "Search anything!" under your profile finds every setting by its name, section or page ("bar position", "blur", "clock font") and jumps right to it
- The tour darkens the whole screen (wallpaper, Waybar, widgets), not only Settings, and everything comes back after it; it now shows the search and Sfx & sounds too
- Notifications stay in the notification center when you click them (Discord too); turn it off in Notifications
- Hot corner and dashboard: moving the pointer along the screen edge no longer closes and opens them over and over
- install.sh asks "Reboot now?" at the end of a new install; the welcome intro and the tour start when you log in

## V2.80
- New welcome intro: night falls over the desktop, a few words rise letter by letter, the moon logo draws itself in, "Take a look" opens the desktop up again from the moon
- Settings tour after the intro: one part lights up at a time with a short explanation (Next, Skip, Done); `rice-welcome tour` plays it again
- Settings Home: the moon logo, moving (it floats, the stars twinkle, a shooting star now and then); change your picture by clicking it in the sidebar
- Notifications: no more red bell for new notifications, a white bell with a small badge; DarkShadow's Shell notifications stay in the notification center when clicked
- Screenshots are saved faster, and the dashboard and hot corner stay open while you take one (so they can be in the picture)
- Hot corner: an even outline that follows the rounded corners, cards inside are concentric with the panel
- Fedora: Quickshell from the COPR its docs recommend, rofi on Fedora 43, matugen from GitHub when Fedora has no package

## V2.70
- CachyOS support: detected by the installer (its repositories and paru are used), CachyOS logo in the bar, dashboard, welcome window and Settings
- Fedora and Nobara logos everywhere the distro logo shows
- The installer warns at the end when Hyprland is older than 0.55 (the Lua config needs it) and tells you how to update it
- Manjaro: a note that its Hyprland can be too old
- rice-fonts downloads newer Nerd Font icons when your icon font has no CachyOS logo
- New README, banner (crescent moon logo, stars, supported distros) and social preview

## V2.60
- Fedora support: the installer sets up COPR (Hyprland, Quickshell, awww), installs the packages with dnf and downloads Nerd Font icons and the Bibata cursor
- Fedora Atomic (Bazzite, Silverblue): the rpm-ostree commands are shown

## V2.52
- Notification center: switches that are on have a white icon

## V2.51
- Notification center: full screen height (floating keeps its gap) and a bit wider, no more scrolling

## V2.50
- New notification center "Deck": switches on top, power modes (Power saver, Balanced, Performance), notifications, volume and brightness, power buttons at the bottom
- Floating or flat against the edge, left or right, resizable, blur and transparency; popups left, middle or right; live preview in Settings > Notifications
- Desktop: Auto-hide widgets while windows are open (lighter on the computer)
- Settings follows "Turn off all blur & transparency" too (the stars stay); bigger profile card in the sidebar
- Wallpaper preview always shows the wallpaper you are on, and the widgets stay visible while you pick

## V2.40
- Dashboard takes its colors from your wallpaper, like the hot corner
- Desktop widgets: frosted glass with the blurred wallpaper behind them (Settings > Desktop > Blur behind widgets)
- Settings > Services > Performance: turn off all blur & transparency at once (Hyprland, kitty, Waybar, rofi, notifications, dashboard, hot corner, dock, widgets)
- Gaming mode turns off blur & transparency too, with options: keep blur, animations, shadows or gaps, Do Not Disturb, dashboard at the bottom edge
- Lock screen: six new clock fonts (Bebas Neue, Orbitron, Outfit, Space Grotesk, Unbounded, Big Shoulders), white hours and grey minutes
- Your Settings choices (Waybar look, dashboard, widgets, hot corner, lock screen...) are saved by sync.sh and installed on your other computers
- install.sh: new Update entry in the menu

## V2.32
- Push the pointer against the bottom edge of the screen to open the dashboard (Settings > Dashboard)
- The dashboard keeps one size on every tab
- Edit mode: drag cards to any empty spot, hold an edge or corner to resize, click + in a gap to put a card there
- Falling stars behind every Settings page

## V2.31
- Dashboard always slides up from the bottom, smooth and without flying around
- Wallpaper tab: arrow down/up moves right/left, Enter sets it, live preview on the desktop (Esc brings the old one back)
- Falling stars on the Settings home page
- Cleaner Settings sidebar; About lives only in the dashboard now

## V2.30
- Dashboard grows out of the bar (Morph animation) and changes size with each tab
- Edit mode: remove, add, resize and move the cards of Dashboard, Performance and About
- New looks: Shadow, Graphite, Aurora and Frost; transparency, blur and animation settings
- Bigger wallpaper picker; Rubik and Material Symbols fonts; smoother Settings
- The dashboard and the hot corner stay open while the pointer rests on the bar or in the corner

## V2.20
- Dashboard: SUPER + ALT + D for Dashboard, Wallpaper, Performance and About
- SUPER + W opens the new Wallpaper tab: search, random, folder and color schemes
- Three dashboard looks: End4, Caelestia and DarkShadow Shell (Settings > Dashboard)
- Smoother page animations in Settings

## V2.10
- Hyprcursor support: Rose Pine cursor made for Hyprland, sharp at any size
- New cursor packs: Catppuccin Mocha Dark and Mauve, Phinger (Settings > Cursors > Get more cursors)
- Update notification shows up within a minute when a new version is out

## V2.04
- Services: switches for Wi-Fi, Bluetooth, sound, microphone, airplane mode, night light and more
- Hot corner: color schemes section
- Battery widget shows wireless devices too, Bar layout fits every module
- Widget editor closes when you switch workspace, widgets stay clickable over the visualizer

## V2.03
- Widget editor: add, move, resize and style desktop widgets
- Audio visualizer at the bottom of the screen, see-through
- Bar layout page: drag Waybar modules around, Battery module
- Hot corner panel size, borders keep their color after reloads

## V2.02
- Update notifications and version in Settings > About
- Six notification sounds
