# Changelog

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
