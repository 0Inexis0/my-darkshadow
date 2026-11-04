# Changelog

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
