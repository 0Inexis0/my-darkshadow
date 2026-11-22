# Changelog

## V4.96: a much lighter shell (less memory, almost nothing in the background)
- **The bar, the side bar and the dock** ask for Wi-Fi, Bluetooth and Do not disturb with two small asks every 10 seconds. Before, they asked for everything the control center shows every 8 seconds: about 18 programs each time (nmcli three times, bluetoothctl, wpctl twice, systemctl six times ...)
- **Auto-hide and the widgets' pausing** (rice-busy) ask Hyprland over its own socket. Before, they started hyprctl twice for every window change and every 4 seconds, all day
- **Settings from desktop.json, the Lite and flat switches and the theme color** are read inside the shell. Before, a bash, a cat and a sed were started every 10 seconds
- **A memory leak is fixed**: the cover of every song you played stayed in memory (all day long with music on). The Music app kept every cover too
- **The wallpaper** (33 MB for a 4K picture, 130 MB for 8K) no longer stays in memory after the shell measures how bright it is
- **Made only when needed**: the widget editor and its side panel (only in Edit mode), the side bar (only when the bar is on the left or right) and the icons of the dock's app menu (only while it is open)
- **While windows cover the desktop**: no music position ticks and no visualizer (cava) for the widgets behind them. The island asks for the music position only while its card is open
- The drawn waves (Gauge, wavy progress lines) move at 20 frames a second instead of 30. Infinite Desktop's listener runs only while Infinite Desktop is on. The check for another notification program runs once a minute instead of every 15 seconds. The wallpaper safety check runs every 3 minutes instead of every 30 seconds

## V4.95: widgets work again, three new widgets, menus above the dock, sounds every time, a lighter shell
- Fixed: **widgets of Music, Weather, System and Date could not be added** (and adding one could crash the shell): a widget whose name is also the name of its family called itself without end. Gauge, Progress and the rest come back too
- **New widgets** (Edit mode > Widgets): **Analog**, a new clock style (a soft cookie face, round hands that spring to the minute, a dot that runs round the rim with the seconds), **Weather > Pills** (the weather as a stack of pills: the temperature big in your theme color, the sky and the place, wind, humidity, high and low) and **Progress** (how much of the day, the week, the month and the year is gone, as thick pills that fill)
- **A widget is always all on the screen**: one saved near an edge that got bigger (another style, the stacked clock) or a smaller screen was cut off at the top or the side
- Fixed: **Settings > Dock > Pinned at startup** did nothing until the next start; it pins or unpins the dock at once now
- **Settings is in the launcher** (DarkShadow Settings, with its own icon in your colors), so it can be pinned to the dock like any app
- Fixed: **Settings > Home > Power modes > Turn on** often did nothing: it unmasks power-profiles-daemon, starts a password prompt when none runs, waits until the modes are there, and says why not when tlp, auto-cpufreq or tuned control the power. The modes are read over D-Bus, so tuned-ppd and a broken powerprofilesctl work too
- **The dock's Session, Wi-Fi, Bluetooth and Volume menus open above the dock** (they opened at the top, by the bar)
- Fixed: **click sounds played once or twice and then never again** on some systems (a sound that still said "playing" was never played again; if this way of playing fails, they play another way). The control center and the notifications click too now
- **Lighter**: the fonts file is watched instead of starting a program every 1.5 seconds for as long as the shell runs; the To-do widget reads its list when it changes (it started Python every 2.5 seconds); the clock wakes once a minute (it woke every second); CPU, RAM and GPU are not sampled while windows cover the widgets, and nvidia-smi is asked a third as often; the slow turning shapes move at 30 frames a second by default (Settings > Widgets > Frame rate)
- Thanks to Sarods2D for the ideas; the designs and the code are our own

## V4.94: the dock in your order, typing a Wi-Fi password works, the shell comes back after a crash, rice-doctor
- **The dock in your order** (Edit mode > Dock): the pin, your apps, the song, every module and the all-apps button (the 9 dots) are parts of one row. Order: ← → move a part, and past your apps it goes to their other side, so modules can sit on the left, on the right or on both ends. The pin and the all-apps button are modules now: take them off like any other. A part that comes grows in with a little spring, the others slide aside (`desktop-set dock mods clock,pin,apps,music,launcher`)
- Fixed: **typing a Wi-Fi password was impossible**: the list of networks was made again every 5 seconds, which emptied the field while you typed. The list is only made again when it really changed, never while you type a password, and what you typed is kept. The Bluetooth menu flashed its rows in every 4 seconds for the same reason
- **The shell comes back by itself after a crash** (at most 4 times in 2 minutes; a stop or a restart does not bring it back). What it says goes to `~/.cache/rice/desktop.log`; after too many crashes a notification points to rice-doctor
- **rice-doctor**: what is wrong with this computer, in plain words: the graphics card and its driver (NVIDIA: kernel mode setting, its framebuffer, egl-wayland, a driver that does not match its programs, nouveau), Hyprland, Quickshell, its last crash and the last lines of the shell's log. `rice-doctor nvidia-fix` sets what Hyprland needs on NVIDIA (asks first, needs your password, then a restart)

## V4.93: a new clock, fewer and clearer widgets, a smaller desktop menu with shortcuts, Music and Files that move
- **The clock is new** (Material 3 Expressive), in three styles: Expressive (hours and minutes side by side, big and heavy, the hours in a light tone of your theme color, the date under them), Stacked (the hours over the minutes, the date on a pill) and Shape (the time in a big cookie that turns slowly). A digit that changes rolls up into the new one. The old styles (Digital, Line, Cookie, Pixel) became these
- **Widgets that were nearly the same are one widget with styles**: Music (Card, Big card, Ring, Player, Button: it was Music, Music card, Now playing, Player and Play button), Weather (Card, Sky, Forecast), System (Bars, Rings: CPU & RAM and CPU · GPU · RAM), Date (its shapes and Pill: Date and Date & time). 15 widgets instead of 23; picking a style swaps the widget in place. Edit mode shows them as tiles with icons, three in a row
- **The desktop menu** (right click on the desktop) is smaller, and its rows of Settings pages became **Shortcuts**: Files, Terminal, Browser, Music, Photos, a screenshot, Edit widgets and Settings
- **Files**: a folder you open slides in (deeper from the right, back up from the left) and its files pop in one after another; a file lifts a little under the pointer
- **Music**: a new page (a tab, an album, an artist) comes in from below, its songs slide in and its covers pop in one after another; a cover lifts under the pointer; a new song makes the cover spring in (Now playing and the small player)
- Thanks to Sarods2D for the ideas; the designs and the code are our own

## V4.92: icon packs that work, modules and magnifying on the dock, colors at once, no more toolbox
- **Icon packs** (Edit mode > Icons > Icon pack) now really change the icons: an app's own PNG icon (hicolor) always beat the pack you chose when the pack has SVG icons, which is most of them (Papirus, Tela ...). The pack comes first now
- **Dock modules** (Edit mode > Dock > Modules), like the icons of a phone's status bar: Music, Clock, Battery, Volume (scroll to change it, right click mutes), Wi-Fi, Bluetooth, Weather, CPU & RAM, App search, Notifications (right click: do not disturb), Control center and Session. They sit on small pills after your apps, in the order you pick them (a number shows it); on a dock at the side they stand upright (`desktop-set dock mods clock,battery,...`)
- **Magnify under the pointer** (Edit mode > Dock, 0 % = off): the apps near the pointer grow out of the dock, the closer the bigger, on a soft curve, like the dock of macOS; how much is up to you. The dock keeps its size while they grow, and only the dock takes clicks (`desktop-set dock magnify 0-100`)
- **The colors of a new wallpaper come at once** and flow in over the old ones: the shell read them only every 10 seconds; the wallpaper changes while the colors are made (it waited for them before), and the picture is measured in one go
- **The launcher** glides to the row you move to with the arrows (it jumped) and scrolls on Material's curve; rows and icons that scroll into view come in at once (they waited their turn)
- **The toolbox is gone** (SUPER + X, Settings > Desktop > Toolbox): its panels, its program, its key, its Settings page and its settings, the chat's address and key too. The launcher's file search and currency rates live in `rice-find` now

## V4.91: the launcher opens out of its search bar, three new styles
- **Opening**: the launcher unfolds downward out of its search bar on Material's emphasized curve, the search bar widens a touch, and what is in it comes in after the card, one row after another; closing folds it back up, faster. It starts once its window is on the screen, so no frames are lost
- **New styles** (Settings > Launcher > Style, and the gear in the launcher): **Drawer** (big icons of the apps you use most, filter chips, all apps A to Z), **Spotlight** (only the search bar and a list under it that grows and shrinks with what it finds; its bar stays put) and **Side sheet** (the drawer as a tall panel that slides in from the left edge). The old List, Grid, Bar, Split and Classic are gone (any of them becomes the Drawer)
- Settings > Launcher: the Rofi theme, corner and font size are gone (the launcher takes your theme's colors and font); the width, rows, see-through and blur stay
- Fixed: "Search the web for" was always in English; the see-through setting did nothing below 86 %; old layout code that could still run in the background is removed

## V4.90: a new launcher (Material 3)
- **The launcher** (ALT + Space, SUPER + R) is new, in Material 3 Expressive and your theme's colors. A big round search bar that stretches out as it opens; before you type, your favorites and most used apps as big icons on shapes, filter chips (All, Favorites, Internet, Media, Games, Development, Graphics, Office, System, Utilities: only those you have apps for; Ctrl + Tab goes through them) and all your apps A to Z in a grid you move through with the arrows. While you type: what it found in groups (Result, Apps, Files, The web), the chosen one on a tonal pill with its buttons (favorite, pin to the dock, Open). Sums show big, Enter copies them. The keys are written at its bottom
- The app icons follow Edit mode > Icons (Themed, Filled, Mono ... and the shape)
- It is the List style of Settings > Launcher (now called Material); the old list is Classic there and in the gear's quick settings; Grid, Bar and Split stay as they were
- Thanks to Sarods2D for the idea; the design and the code are our own

## V4.89: the dock and its icons in Edit mode, a menu that opens where you click
- **The dock's menu** (right click on the dock) opens right above the dock (beside it on the left or right edge), where you clicked; before, it could end up in the top left corner. It grows out of the dock, its rows coming in one after another
- **Edit mode > Dock**: the dock's own window is gone; its settings are a tab of Edit mode now, with the dock in sight while you change it: on or off, where it is and its style (a little screen for each), Always or when the pointer comes, sliders for the icon size, the space between apps and how see-through it is (the dock follows while you drag), the song, the pin and the apps button, your pinned apps (move them, take them off) and Add apps (search and pin with +). Right click on the dock > Edit dock or Add apps opens it there
- **Edit mode > Icons**: how app icons look, on the dock and in its app menu. Styles: Original, Wallpaper (a shade of your wallpaper), Themed (one plain sign in your theme's colors on a soft shape, like the themed icons of Android: Firefox, Chrome, Discord, Spotify, Steam, VS Code, the terminal, Files and many more get their own sign; others, like Brave, keep their picture in your colors), Filled (the sign on your theme color), Mono and Grey. Shapes: none, a soft square, a circle, a cookie, a flower, a clover, a sun ... Icon pack: the icon themes on this computer, each with four of its icons (Papirus, Tela ... once installed)
- The shape an app sits on takes the icon's own room: the dock no longer grows when you pick one, and there is no empty ring around the icons
- Settings > Interface: Dock and Icons buttons open Edit mode on those tabs (`desktop-set edit on dock|icons`, `desktop-set icons look|shape|theme`)
- Thanks to Sarods2D for the idea; the design and the code are our own

## V4.88: Settings look new again
- The rail shows only icons now (their names come up beside them under the pointer), in groups with thin lines between
- The header: a back arrow (the pages you came through), where you are (HOME > SYSTEM, a click on Home goes there), a bigger title, and Expressive / Standard motion right next to the search
- Every section starts with a symbol for it in a tonal circle, a bigger name and a line under it
- Thanks to Sarods2D for the idea; the design and the code are our own

## V4.87: Account in Settings, a Home for Music, a dock you edit right on it, launcher quick settings
- **Settings > System > Account**: your picture cut to your shape (click it or drop a picture on it), your name, your password (the current one, the new one twice, how strong it is), and the accounts of this computer: make one an administrator, remove one (with or without its files), make a new one. "Copy my desktop" (recommended) gives the new account this whole desktop: the shell, its bar, widgets, colors, keys and the settings of its apps; your files, wallpapers, recordings and screenshots stay yours. Changes to accounts ask for an administrator password; passwords never go through a command line (`rice-account`)
- **Music > Home** (where Music opens now): a greeting with your music in numbers and the covers you play most cut to our shapes, Shuffle and Play all, Listen again (the albums you played last), On repeat (your most played songs), Recently added and your artists, each in a shape of its own. What you play is remembered on this computer only
- **The dock**: right click on it for its menu: pin, unpin and move apps, open or close them, Add apps, Edit dock. The editor sits beside the dock and changes it while you watch: where it is (with a little screen for each choice), its style (Floating, Pills: every app on a tile of its own, Full: the whole edge), Always or Auto-hide, the icon size, the space between apps, how see-through it is and a shape every app sits on (a soft square, a circle, a cookie, a flower, a clover ...). The dock takes your theme's colors now. Settings > Dock has the style too (`desktop-set dock style|iconSize|gap|iconShape`)
- **The launcher**: the gear next to the search opens its quick settings (layout, position, icons, rows, width, see-through, all its settings); a right click on an app: open, favorite, pin to the dock or unpin it
- Thanks to Sarods2D: IridiumShell gave the idea for these; the designs and the code here are our own

## V4.86: a new look for Settings (Material 3)
- **Settings** looks like the settings of a new Android phone (Material 3 Expressive): the pages sit on a large rounded pane beside the rail; the tabs of a group are pills, the open one filled, and they scroll sideways when they do not fit (a narrow window, Polish names); settings that follow each other join into one group, round at its two ends with small corners and a thin gap inside; section names are in your theme's color
- Home: Light mode, Auto-hide widgets and Falling stars are one group of switches with icons; the icon fills with your color while it is on
- The cards of Settings are a touch lighter, so they stand out from the pane

## V4.85: our own apps: Files, Photos, Music and Videos, with their own icons
- **Icons**: Files, Photos, Music and Videos have their own Material 3 icons (a soft square, a flower, a cookie and a clover), in your wallpaper's colors: they change with the wallpaper (`rice-app icons`)
- **Files** (SUPER + E, `rice-app files`): a file manager in Material 3 and your wallpaper's colors. Your folders, bookmarks, drives (how full they are) and the trash on the left; where you are as pieces you can click (Ctrl + L to type a path); a grid with pictures of your photos, videos and PDFs, or a list with columns; drag a box to choose files, drag files into folders or into other apps; cut, copy and paste (also with other file managers), rename, the trash with Undo, compress and extract, starred files, "Open with" (and the default app), Quick look (Space), the details of a file (camera, size of a picture ...), a terminal here. Typing filters the folder, Enter searches inside it too. Settings > Desktop > Look & Feel > File manager > Files (the first one now); picked, the old file manager (Nautilus ...) leaves the app menu, and comes back when you pick it again (`rice-app hide-old on|off`)
- **Photos** (`rice-app photos`): your pictures and screen recordings by day (or month, smaller), albums from their folders, favorites, videos. Choose several (the circle, Ctrl + click or a long press) to favorite, copy or move them to the trash. The viewer: zoom where the pointer is, drag a zoomed picture, a strip of the others, a slideshow, turn it, the details (camera, exposure), set as wallpaper, edit (satty, swappy, GIMP ...)
- **Music** and **Videos** (`rice-app music`, `rice-app videos`: one player): your music from the tags (songs, albums, artists) and your videos. A queue (play next, add to it, take out), shuffle and repeat, a wavy line while it plays, the album cover's colors over the whole app, it starts where you stopped. Videos fill the window (F). The bar, the island, the lock screen and the media keys see it and control it (MPRIS, `rice-player-mpris`)
- Settings > Desktop > Look & Feel: "Our Photos, Music and Videos for your files" opens pictures, music and videos in them (off: the apps you had before; `rice-app defaults on|off`)
- The dock, the bar's window title and Task view show them with their own icons and names (not as Quickshell)
- Fixed: the shell could crash when the launcher opened after the app list changed (an app installed or removed): it kept apps that were already gone
- `rice-perf` shows them by name
- Thanks to Sarods2D: IridiumShell's own apps gave the idea; the designs and the code here are our own

## V4.84: much lighter and quicker; minimize and stack windows; your own keys; a gentler volume; login screen clocks
- **Performance**
  - Task view: closed, it lets every window picture go. Before, after the first SUPER + Tab every window was captured live, every frame, behind everything until the shell restarted: lag and a lot of memory
  - Waves (progress lines, the timer, gauges, the game bar) are drawn about 30 times a second, not once every frame of the screen (240 times a second on a 240 Hz screen, by the processor)
  - The black hole and moon logos on the bar move while the pointer is on them (Settings > Bar > "The logo moves all the time" for the old way)
  - Infinite Desktop's moving wallpaper exists only while Infinite Desktop is on (a whole-screen surface and a big picture sat in memory all the time)
  - The launcher is made when you first open it and let go after 10 minutes closed
  - Settings no longer waits in the background by default (about 300 MB): it starts when you open it and quits a minute after you close it (Settings > Desktop > Performance > Keep Settings ready, for the old way)
  - Fewer wake-ups: the files the shell watches are re-read every 5 seconds as a safety net (inotify does the real work), the desktop's settings every 10
  - `rice-perf`: how much memory and processor each part of the shell uses right now, and what would make it lighter
- **Windows**: minimize (SUPER + H) and bring back (SUPER + SHIFT + H); stack windows into tabs (SUPER + T), the next / previous one of the stack (SUPER + CTRL + Right / Left), put a window into the stack beside it (SUPER + CTRL + SHIFT + Left / Right). All of them can get other keys in Settings > System > Keybinds. `rice-win`
- **Your own keys**: Settings > System > Keybinds > "Turn a key off" takes any key of the window manager away (then give it something of your own); ready-made actions for your own keys (minimize, fullscreen, close, float, pin, screenshot ...)
- **Launcher favorites**: right click an app (or Ctrl + D) and it comes first, with a star
- **Volume**: the sliders, keys and the bar's wheel use a gentler curve (below 35 % it was nearly silent) and the top can be louder than 100 % (Settings > Sound > Volume: Low volumes, Loudest; `rice-sound`)
- **Login screen clocks**: classic, stacked, center, pill and shapes (Settings > Desktop > Idle & Lockscreen > Login screen; `rice-sddm clock STYLE`)
- **niri**: at the last column, Super + Left / Right (and the wheel) go on to the next monitor, Super + Ctrl + Left / Right take the window with them
- Settings: with Hyprland's blur off the window is nearly solid, so the desktop widgets no longer show through it

## V4.83: smoother Edge bar, a see-through toolbox, a launcher in your wallpaper's colors
- Edge bar: its parts no longer lag and swing when something changes (another workspace, the island growing for a notification or a recording): they follow the zones and the island in the same frame. New: Settings > Bar > "Frame along the edge" (off: only the pills stay, without the dark parts behind them)
- Blur: the bar and the island are blurred on every install now (the rule only came with Settings > Launcher before), and the bar's Transparency is its own (it was made more solid on top, so the blur could hardly be seen)
- Toolbox: Transparency and blur work (its cards were solid and covered most of the sheet; the default is 80% now). It opens like the control center: the title, then every part of the page one after another, then the tabs pop in; a tab you go to plays its parts in again
- Launcher: a new "Wallpaper" look, the default: the wallpaper's colors instead of black with a white selection (it was "Shadow"; you can still pick that one in Settings > Launcher)
- Also in this release: everything from V4.77 to V4.82 below (screenshot text / translate / color, the record menu, the key sheet, the toolbox, conversions, the Edge bar, files in the launcher, your own themes, live wallpapers on the login screen)

## V4.82: the Edge bar, files in the launcher, your own themes
- **Edge** (Settings > Bar > Bar style, `rice-bar set style edge`): a new bar style. It has the Dynamic style's look and island, but every part is one piece with the screen edge: the left part reaches the screen's left side, the right part its right side, the middle hangs from the edge, each with soft curves where it meets the edge. The modules sit on tonal pills inside. Also in the desktop's edit panel
- **Launcher**: files and folders in your home show after three letters (fd, else locate, else a short search); Enter opens one. A "/" in front shows only files. `rice-tools files TEXT`
- **Your own theme** (Settings > Appearance > Themes): "Save the look I have now" keeps the colors, the wallpaper, corners and shapes, the bar, widgets, notifications, window corners and gaps, motion and the font under a name. It shows with the other themes (marked "Yours"), one click brings all of it back, and the bin on its card takes it away. `rice-theme save NAME`, `rice-theme delete KEY`

## V4.81: the toolbox's blur is on the toolbox only; the island is gone
- Toolbox: with blur on, the whole screen behind the toolbox was blurred and a lighter square showed around the sheet. Now only the sheet itself is blurred (the dim behind it and its shadow stay under the blur rule's threshold)
- Toolbox: the island (folding the sheet into a pill) is taken out again
- Settings > Desktop > Toolbox: the little screen in the preview has round corners all the way (the dim in it was square)

## V4.80: the toolbox as an island, its transparency and blur; live wallpapers on the login screen
- Toolbox: the button next to the X folds it into an **island**, a small pill at its edge with the tab you were on and its one line (the timer's time, what is left to do ...); the windows under the rest of the screen stay usable, a click or SUPER + X opens it again. Settings > Desktop > Toolbox > "Open as an island" makes it start that way
- Toolbox: **Transparency** (0 to 70%) and **Blur behind it** in Settings > Desktop > Toolbox (`rice-tools set opacity 0.7`, `rice-tools set blur off`)
- Toolbox: new tabs at the bottom: the one you are on opens into a pill with its name, the others are round icons; the icon you go to tips over and back
- Infinite Desktop: a new wallpaper fades in over the old one while the canvas is on (before, it changed with no animation at all, because the moving wallpaper covers the real one)
- Login screen (SDDM): a **live wallpaper plays there too**. `rice-sddm sync` brings the video and a frame of that very video (before, the picture could stay the one of the wallpaper before). It needs QtMultimedia for SDDM's Qt (Arch / Artix: `qt6-multimedia qt6-multimedia-ffmpeg`); without it the picture stays. Run `rice-sddm install` once after this update, so the login screen gets its new files

## V4.79: the toolbox opens like the control center, shows temperatures, and has its own settings page
- Toolbox (SUPER + X): it opens the way the control center does: it comes out of its edge and grows the last bit, and the title, the page and the tabs follow one after the other; a soft light in your key color sits behind the title, and every tab says one line about itself under its name (tasks left, the timer's time, the processor's load and temperature ...)
- Toolbox > System, made again: the processor and the graphics card each have a ring and a temperature pill that turns amber and red with the heat (and the processor's speed in GHz); memory, swap and disk show their percent; below them download and upload speed, how long the computer has been on, the load, and the fan and battery when the machine has them
- The processor's temperature is found on more boards (sensors that only name the processor on one of their lines: Tctl, Package id 0, CPUTIN ...)
- **Settings > Desktop > Toolbox** (new): the left or the right edge, the width, dim the screen behind it, close on a click outside, open on the tab you used last, which tabs it has and in what order, and its key (SUPER + X, SUPER + B, SUPER + ALT + T, or any other in Keybinds). `rice-tools state`, `rice-tools set side left`

## V4.78: the toolbox, conversions in the launcher, a livelier key sheet
- **Toolbox** (SUPER + X, `rice-tools toggle [tab]`): a sheet on the right edge with six tabs. Ctrl + 1 ... 6 or Ctrl + Tab changes the tab, Esc closes it
  - **Tasks** and **Note**: the same list and note as the desktop widgets, so they are always in step
  - **Timer**: a focus timer (15 to 60 minutes, then a break) with a wavy ring; it keeps counting while the toolbox is closed and tells you when the time is up
  - **Convert**: length, mass, temperature, volume, speed, data, time and money; or type it whole ("10 km in mi"). A click on the answer copies it. Currency rates are the European Central Bank's, fetched at most twice a day and only when you use money
  - **System**: processor, graphics, memory, swap and disk, measured only while the tab is on the screen
  - **Chat**: talk to an AI model of your choice. By default Ollama on your own computer (nothing leaves it); the gear sets a service with an OpenAI-style API instead (address, model, your key, kept in ~/.config/rice/ai.json, readable only by you). The answer arrives word by word
- Launcher: "10 km in mi", "72 f c", "100 usd pln" convert, like "2+2" calculates (Enter copies)
- The key sheet (SUPER + /): typing folds away what does not match and the rest glides into place, what you typed is marked in your key color, matching keys pop, the groups count their matches, and the groups come up one after the other when it opens

## V4.77: the screenshot tool reads text, translates, finds colors; a record menu; every key on one sheet
- Screenshot tool (Print, SUPER + SHIFT + S), new in the toolbar:
  - **Copy the text** (T): reads the text in the box and copies it (needs `tesseract` and a language, Arch: `sudo pacman -S tesseract tesseract-data-eng tesseract-data-pol`)
  - **Translate** (L): that text in your language, on a small card in the corner (with `trans` from translate-shell when you have it, else Google's translator: the text is sent there, only when you press it)
  - **Search with the picture** (G): copies the crop and opens Google Lens, Ctrl+V there pastes it (nothing is uploaded until you paste)
  - **Color** (4 or C): a loupe follows the pointer, a click copies the color of that pixel (#RRGGBB, the card has rgb() too)
  - The loupe is drawn in a plainer way now (V4.75's could come out empty on some graphics drivers)
- Record menu (SUPER + SHIFT + R): the same toolbar over the live screen. Region, Window or Screen, computer sound and microphone on or off, then Record. Pressing the keys again stops it, as before. Without the shell it is the old selection (slurp)
- Every key on one sheet (SUPER + /): all the shell's keys in groups, the ones you changed in your key color, type to find one. `rice-keymap show`; the key itself can be changed in Settings > System > Keybinds

## V4.76: SUPER + SHIFT + S opens the new screenshot tool
- SUPER + SHIFT + S still opened the old selection (slurp). It opens the new screenshot tool now, the same one as Print (Hyprland and niri). Good for keyboards without a Print key

## V4.75: a new screenshot tool, wallpaper zoom
- Screenshots, redesigned (Print, and the dashboard's screenshot button): the screen freezes the moment you press the key, then a Material 3 toolbar at the bottom lets you pick:
  - **Region**: drag a box, move it by dragging inside, resize it by its corners; its size in real pixels sits above it, and a rounded loupe shows the pixels under the pointer while you drag
  - **Window**: point at a window (it is outlined, with its app name), click to save it (Hyprland)
  - **Screen**: the whole screen
  - Save (Enter, or double-click the box) keeps it in Pictures/Screenshots and copies it (as set in Settings), Copy (Ctrl+C) only copies, Edit (E) opens it in satty or swappy when you have one, Esc or a right click cancels; 1 / 2 / 3 (R / W / S) switch the mode
  - The crop is taken from the frozen picture at full resolution, so menus and hover states are kept. Without the shell it falls back to the old selection (slurp). SHIFT + Print still saves the whole screen at once
- Infinite Desktop: "Wallpaper zoom" in Settings > Desktop > Infinite Desktop (1.05x to 1.5x, `rice-infinite set wallzoom 1.1`). The default is smaller now (1.15x instead of 1.42x), so the moving wallpaper looks much closer to your wallpaper

## V4.74: the wallpaper moves while you hold SUPER + ALT, not only after
- Fix: with SUPER + ALT + mouse the wallpaper (and the bar stepping aside) only reacted after you let go. The live moves went over Quickshell's SocketServer, which delivered nothing on some systems. rice-canvasd now sends them as datagrams to a small listener the shell runs (the way Sarods2D's Iridium Shell feeds its parallax), so the wallpaper moves with the windows while you hold the keys. Moves that arrive together are added up, and the wallpaper glides with an animation made for a target that changes many times a second (smoother)
- An updated rice-canvasd replaces the one still running from before the update, as soon as Infinite Desktop turns on (no logout needed)
- The switch is in Settings > Desktop > Infinite Desktop: "The wallpaper moves with it" (`rice-infinite set wall 0|1`)

## V4.73: the wallpaper follows every move at once
- Fix: after a long trip over the canvas the moving wallpaper stayed at the end of its room, and moving back did nothing until you had come a long way back. It is now counted from the moves themselves: every move the other way moves it back at once, and it moves a little more per pixel (0.3)
- rice-canvasd connects to the shell at the start of every hold, so the first move of a hold already moves the wallpaper

## V4.72: no crash when Infinite Desktop turns on
- Fix: Quickshell crashed right after turning Infinite Desktop on (V4.71, seen on Artix with NVIDIA: QWaylandWindow::calculateExposure). The moving wallpaper's surface was mapped and unmapped together with its picture's loading state, a binding loop that made Qt's Wayland client trip over a window being taken away. The surface now stays (see-through) while the feature is on and only the picture inside it comes and goes

## V4.71: Infinite Desktop: the wallpaper travels with you, the bar steps aside
- Infinite Desktop (Hyprland): the wallpaper moves with the canvas, slower than the windows, as if you travelled over a big picture. Turning Infinite Desktop on grows the wallpaper a little from exactly where it is (room to move), and turning it off brings it back the same way. Live while you hold SUPER + ALT and move the mouse, a smooth glide with the keys, the wheel and SUPER + CTRL + arrows. At the end of the picture it slows down softly instead of stopping
- While you move the canvas with SUPER + ALT + mouse, the bar (with the island) and the dock slide away and come back a moment after you let go
- Both can be turned off: Settings > Desktop > Infinite Desktop ("The wallpaper moves with it", "The bar and the dock step aside while you move"), or `rice-infinite set wall 0`, `rice-infinite set hidebar 0`
- The moving wallpaper and the bar hiding while you pan are inspired by Sarods2D's Iridium Shell

## V4.70: Flatpak on Artix (and other systems without systemd)
- Fix: Flatpak apps (Spotify, Discord ...) did not start or had no tray / portals on Artix: "Unknown or unsupported transport 'disabled'". `dbus-run-session` makes a D-Bus bus with an abstract address, which Flatpak cannot use; systemd would put the bus at `$XDG_RUNTIME_DIR/bus`. The "Hyprland (DarkShadow)" and "niri (DarkShadow)" login sessions now start through `rice-session` (installed in /usr/local/bin), which starts the bus there and stops it with the session. Log out and pick the session again after updating. From a console: `rice-session Hyprland`

## V4.69: Infinite Desktop works right after "Allow", without logging out
- Fix: you join the input group, but the login you are in keeps the groups it started with, so SUPER + ALT + mouse stayed dead until you logged out and in. `rice-infinite daemon` (and Hyprland's start of it) now starts the daemon through `sg input` when you are in the group in /etc/group but this login is not, and a new daemon replaces the old one that cannot read the input devices. Run `rice-infinite daemon` once after updating and it works

## V4.68: Infinite Desktop on Artix, Artix on the README
- Fix: SUPER + ALT + mouse did nothing after joining the input group (seen on Artix). A copy of rice-canvasd from the session before (started without the input group) kept running and held the lock, so the new one never started; whether Hyprland was still there was judged by its folder, which can stay after a logout. Now Hyprland must answer on its socket, and a new copy stops an old one that belongs to another session or cannot read the input devices
- `rice-infinite check` tells more: whether you are in the input group in /etc/group and in this login, and whether the running daemon belongs to this Hyprland and can read the input devices
- README: Artix Linux is listed as supported (badge and table)

## V4.67: Artix system update no longer stops on a package clash
- Fix (installer, Artix): the system update stopped with "geocode-glib-3.26.4-6 and geocode-glib-common-3.26.4-5 are in conflict". With Arch's `[extra]` on, Artix's own build of a package replaces Arch's and the old split-off part has to be removed; `--noconfirm` said no to that. On Artix the update now says yes to removing the conflicting package (`--ask=4`), and if it still fails it tells you what to answer by hand

## V4.66: Files glass really shows up
- Fix: Files did not get the glass look and the blur (Artix, and anywhere Files was already running): Files stays running in the background after its window is closed and keeps the CSS it started with. It is now quit once when the glass / Material 3 look is written, so the next window opens with it

## V4.65: Files glass, no more date module, steadier dock and weather
- Files (Nautilus) in a Material 3 look: pill rows in the sidebar, round buttons and search, the selected item in the wallpaper's secondary-container color, and see-through surfaces so the compositor's blur shows behind it (works the same on Arch and Artix). The old window-wide opacity rule is gone, so the text stays sharp. Settings > Desktop > Look & Feel > "Glass and Material 3 shapes" turns it off (`rice-look files-glass off`). Icons stay Papirus
- The date is part of the Dynamic island now (the island shows the day, the date and the time in a pill); the separate Date module is gone from Bar layout. "Date" in Settings > Dynamic island is on by default
- Fix: a lighter square of blur past the rounded corners of widgets (the soft shadow was just opaque enough for Hyprland to blur it). With blur on, the shadow is kept below that
- Fix: the dock appearing and disappearing again and again while the pointer rests on it (an "entered" event from a dock that is sliding away brought it back). It returns on real pointer movement only, and hides only when the pointer is really away
- Fix: the weather popup and the Forecast widget stayed empty ("Looking outside...", "--") while the island showed the temperature: the long answer of wttr.in is slower and fails more often, so it is tried twice and, if it still fails, the short answer is used
- Weather needs a place (it is not asked from your IP, on purpose): `rice-weather place "Warsaw"` or Settings > Language & region > Online lookups

## V4.64: date in the island, removing the island keeps your bar
- The Dynamic island now shows the date like the bar's Date module: `niedz., 15/11` and the time in a pill in your key color. It appears when "Date" is on in Settings > Dynamic island, or when the Date module is in your bar layout (the separate Date module is then hidden, so it is not shown twice)
- Fix: removing the island (clock) from Bar layout also removed the launcher and everything else in the middle. Now only the island goes; the rest stays. Older layouts that have no island keep working
- Infinite Desktop on Artix and other systems without systemd: SUPER+ALT needs your user in the `input` group (`sudo usermod -aG input $USER`, then log out and in). Settings > Desktop > Infinite Desktop > Allow does it for you

## V4.63: no more "Invalid keyboard layout passed"
- Fix: with a plain US keyboard, an update could save the layout with its quotes and comma (`"us",`, read from the line `kb_layout = "us",` in hyprland.lua) and Hyprland showed "Invalid keyboard layout passed". Values read from config files and from Hyprland are cleaned now, and a broken value saved before is mended by itself
- The installer is not changed in this version

## V4.62: Artix Linux
- The installer supports Artix (OpenRC, runit, s6 and dinit). It is treated as Arch, and what systemd would do is done with your init:
  - Arch's `[extra]` repository is turned on (`artix-archlinux-support`, as the Artix wiki says) when Hyprland is not in Artix's own repositories; a copy of pacman.conf stays as `pacman.conf.bak-darkshadow`
  - Artix's service scripts for your init are installed (`networkmanager-openrc`, `bluez-openrc`, `power-profiles-daemon-openrc`, `sddm-openrc` ...) and D-Bus, elogind, NetworkManager, Bluetooth and power modes are turned on at boot
  - new login sessions "Hyprland (DarkShadow)" and "niri (DarkShadow)" start with their own D-Bus (without it notifications, the tray, portals and Bluetooth do not work); from a console: `dbus-run-session Hyprland`
  - a warning when ConnMan runs the network (NetworkManager is then left off) or when neither elogind nor seatd runs
- `rice-sys service-enable` / `service-has`: turning a system service on with any init. The SDDM login screen and Settings > Home (power modes) use it without systemd
- Fix: an update from Settings that changes the installer opens one terminal at most (once a minute) and that terminal no longer opens another one (the endless terminals of V4.56)

## V4.61: rice-update starts again
- Fix: `rice-update` crashed on start (`name 're' is not defined`) since V4.58. The import was missing. All Python tools were checked for the same kind of mistake
- The installer is not changed in this version

## V4.60: Infinite Desktop leaves app pop-ups alone (Steam notifications)
Reported by R31tr0 (issue #19).
- Steam's notification toasts (`notificationtoasts_*`) no longer move the canvas, get repositioned, or take focus: they stay where Steam puts them, like a pinned window. Before, a toast was taken as a canvas window, so it shifted the screen and the other windows
- The installer is not changed in this version

## V4.59: the Wi-Fi list no longer goes blank, and connecting always works
Reported by a user: the networks sometimes vanish from the Wi-Fi menu and connecting sometimes does nothing, while the internet itself works.
- The list keeps the last networks while NetworkManager is scanning or busy (it answers with an empty list for a moment), instead of showing nothing
- A stuck `nmcli` can no longer freeze the list: every read and every connect has a time limit, and a connect that hangs is stopped, so the next click works
- A saved network whose profile is named differently than the network ("Home 1") now connects by its SSID instead of failing
- A timed-out connect says so
- The installer is not changed in this version

## V4.58: fixes from the V4.55 audit, and the keyboard layout stays after an update
Thanks to notwafel (pull request #18).
- Bar on every screen: the bars share one `rice-services` and one `rice-weather` (BarSvc.qml) instead of each starting its own; the side bar uses it too
- `rice-canvasd` (Infinite Desktop) can no longer run twice at once (a lock instead of only the pid file)
- `rice-update` only fetches from this project (or a fork of it), like the installer
- The unused lock screen engine switch, the example "epic-mouse-v1" device and cmatrix (Nix) are gone; two Polish lock screen texts added
- Fix: an update could put the keyboard back to US. The layout you use is now also found in your config files (hyprland.lua, niri's config) when Hyprland cannot be asked, and niri keeps a layout from a hand-written config too
- The installer itself is not changed in this version (an installer change from Settings sets off the old terminal loop for anyone still on V4.55); its two small fixes from #18 come later

## V4.57: no terminal storm when updating from an older version
- Fix: updating to V4.56 from Settings > Update Center opened terminal after terminal until the computer froze. The installer from before V4.56 runs during that update, and it still had the bug V4.56 fixed; V4.56 itself changed the installer, which set it off. V4.57 leaves the installer files as they were in V4.55, so updating from V4.55 runs on its own again
- The Update Center checks first whether an update changes the installer. If it does, it opens one terminal (at most one a minute, without the background settings) where you answer y, and never starts the old installer for it

## V4.56: Update Center: no more endless terminals
- Fix: an update that changes the installer, started from Settings > Update Center, said "update failed" and opened terminals again and again, each ending in "Press Enter to close". The terminal it opens got the Update Center's "no terminal here" setting, so it opened another one instead of asking. Now that terminal asks "Apply this update? [y/N]" (and for sudo) as it should, and at most one opens per minute
- Thanks to the user who found the cause

## V4.55: the bar on every screen, and ZIP copies that can update
- New: Settings > System > Monitors > **Bar on every screen** (`rice-screens bar-all on`). The same bar on all your screens, with its island, clock, workspaces and tray. The menus it opens and commands from scripts (SUPER + ALT + D, the calendar) still open on the main screen. The desktop widgets stay on one screen (Desktop widgets: Put the widgets here)
- Fix: "it does not update any more, and it went back to V3.60". The newest Release on GitHub was still V3.60, and its ZIP has no git history, so `rice-update` had nothing to pull and installed that old copy again. `rice-update` now sees a ZIP copy, clones the project with git in its place (the old folder is kept, renamed) and updates. Settings > Update Center opens a terminal for it, and the installer says so too. Each new version is now also published as the Latest release on GitHub

## V4.54: the Material 3 lock screen works again, and its Settings page shows it
- Fix: since V4.51 the shell's lock screen did not start and hyprlock (the old one) showed instead. The desktop's music player became a shared singleton, and the lock screen copied it and could not create it. The lock screen has its own player now (`LockPlayer.qml`), and an old copy is removed when you lock
- Settings > Desktop > Idle & Lockscreen: the small picture at the top is the real layout now (Cards: the month, the time, the music and the bar; Classic: one column), in your clock font, 12/24 h and theme. The old hyprlock picture and the DarkShadow/hyprlock switch are gone (hyprlock only steps in if the lock screen ever fails)
- Only the options the chosen style uses are shown. Cards: clock font, 24-hour clock, power buttons, background, music. Classic adds layout, clock style, accent clock, date, greeting, picture, password field and the small lines
- Clock fonts: one you pick that is not installed yet downloads and shows up in Settings within seconds, no restart needed. New Test (30 s) button: a real lock that opens itself after 30 seconds

## V4.53: the lock screen is back
- V4.52 removed the shell's own Material 3 lock screen by mistake. It is back exactly as it was (SUPER + L, power menu, Settings > Desktop > Idle & Lockscreen). Only the hot corners stay removed

## V4.52: hot corners are gone
- The hot corner panel is removed (panel, Settings page, blur rule). `rice-hotcorner` stays as the tool behind Print, SUPER + SHIFT + R and the recording buttons, and an update takes the old hot corner rule out of your Hyprland config

## V4.51: 23 small fixes from a full read of the inherited code
Thanks to notwafel again (pull request #16).
- The hot corner panel finally opens, and the Settings pages for Hot corners and Security are linked again
- Lock screen: waits and retries if the lock is not ready, with a timeout, instead of hanging; `rice-lock` no longer blocks on a second press
- Stats and Player are now single shared services: widgets use one reader each, and Stats only runs while something on screen shows it
- Config files are written atomically with locks (`hypr-set`, `rice-theme`, prefs), so two writers cannot corrupt them
- Polling removed from the wallpaper and hot corners (file watching instead); sounds read through a FileView; `rice-clip` makes each thumbnail once per open
- pid checks compare the command line before killing; `rice-cursor` refuses archive links pointing outside; `secure.sh` guards its own install and library path
- Install: `install.sh` stashes/resets cleanly on update, checksums with spaces in paths work, the install guide uses the right name

## V4.50: 75 Hz (and every other refresh rate) now sticks on niri
- Issue #17 (thanks JapanisuGoburin): niri wants the refresh rate exactly as `niri msg outputs` shows it, down to the third decimal (74.973), and drops a mode that does not match. Settings rounded it to 74.97, so the screen stayed at 60 Hz or went back to it. The rate is now kept exact everywhere (the buttons still say 75 Hz), and a mode saved before this is matched to the nearest real one when niri's config is written
- A screen that your own `user.kdl` sets up (`output "HDMI-A-1" { ... }`) is left alone by Settings, so the two blocks no longer fight over it

## V4.49: CI green again
- The ShellCheck step of CI failed on two notes in the new `install/lib/secure.sh` (V4.48). Both are intended code, now marked as such. Nothing changes for you

## V4.48: security and privacy: verified downloads, guarded updates, opt-in permissions and lookups
Thanks to notwafel, who reviewed the shell and sent all of this (pull request #15).
- Downloads: matugen and the Bibata cursor are pinned to a release tag and checked against `install/checksums.txt` (SHA-256) before they are unpacked or installed. An archive with `../`, absolute paths or links pointing out of its folder is refused (`install/lib/secure.sh`)
- Updates come only from this project (or a fork of it). An update that changes `install.sh` shows what changes and asks before anything is pulled; from Settings > Update Center a terminal opens with that question
- The `input` group (Infinite Desktop, SUPER + ALT + mouse) is no longer granted by the installer: `./install.sh --input-group`, or Settings > Desktop > Infinite Desktop > Allow, which says that any program you run can then read every keyboard. NixOS: `programs.shadows-shell.inputGroup = true`
- Settings > Language & region > Online lookups: what the shell asks other websites, each with its own switch
  - Weather place: weather is asked for that place only (without one, wttr.in looked up where your IP is). If the weather already worked for you, the place it found is kept
  - Song lyrics (lrclib.net learns the artist and the title): off for new installs; on if you already had lyrics. The lyrics cards say when it is off
  - Check for updates: once a day instead of every 15 minutes; off stops the checks at once
- `sync.sh` looks for real key shapes before publishing a config, and stops instead of only warning
- Animations stop while what they draw is hidden (the island's equalizer, the logos, the lock screen's shape, the music popover)
- `SECURITY.md` and `tests/security.sh` (26 checks, in CI)

## V4.47: the bar's shadow no longer costs frames; Settings need not wait in memory
- Performance (thanks to R31tr0, issue #14): the notch's shadow was drawn with a canvas blur that the CPU computes, 70-140 ms every time the notch changed width, and it changes all the time (the island, the music, the clock). The bar dropped to 2-3 fps while moving and games lost frames to it. The shadow is now a few soft outlines: about 1 ms, and it looks the same
- The second `qs` process (about 300 MB) was Settings waiting hidden, so it opens at once. New switch: Settings > Desktop > Performance > "Keep Settings ready in the background". Off: it starts when you open it and quits three minutes after you close it
- (Turning shell shadows off is still Settings > Desktop > Windows > Shell shadows; editing Look.qml by hand is not seen by the switch)

## V4.46: pick your file manager, in the wallpaper's colors; your picture on the login screen
- Settings > Desktop > Look & Feel > File manager: Files (Nautilus), Thunar, Nemo, Dolphin or PCManFM, with an Install button for the ones you do not have. The one you pick opens with SUPER + E (Hyprland and niri) and for every "open folder" from your other apps (xdg-mime)
- Colors from the wallpaper (on by default, a switch turns it off): the file manager and your other GTK apps get the wallpaper's Material colors through ~/.config/gtk-3.0 and gtk-4.0/darkshadow.css (your gtk.css keeps your own CSS and only gets one import line, with a backup), Dolphin and the other KDE apps through a DarkShadow color scheme. It follows every wallpaper change; open the app again to see it
- Login screen: the picture you choose in Settings now shows there too (it used to change only with the next wallpaper change)

## V4.45: smooth CPU / RAM rings, one workspace color from the wallpaper, the RAM icon
- The CPU, RAM and disk rings in the bar blinked out for a moment at every reading (every 3 seconds, very visible while playing): they were made again each time. They now stay, and glide to the new value. The same for the System card of the bar (its bars now slide instead of jumping)
- Workspaces in the bar and in the dynamic island: the one you are on is in your wallpaper's color. It used to turn a little around the color wheel for every workspace, so each had its own color
- Settings > About: Memory had an empty box for its icon (that icon is not in the shell's icon font); it now has the memory chip

## V4.44: window rules put apps on their workspace (Hyprland and niri)
- "Assigning apps to workspaces doesn't work, the gaming workspace neither": on niri a number made a separate named workspace at the top instead of using the workspace at that place, and on Hyprland a rule acts only at the moment a window opens, which misses the many apps that get their name a moment later (Discord, Spotify, games through Proton or Wine). A small watcher (rice-rules watch, started with the shell) now looks at each new window for a few seconds and moves it to its workspace when the rule did not; a window already in place is left alone, and windows that were open before are never moved
- niri: a workspace number is the workspace at that place; a name is still a named workspace
- Task view: moving a window to another workspace focuses it first on a Lua-config Hyprland (its move has no window to name)

## V4.43: Alt + Tab focuses the window on Hyprland 0.55+ (issue #11)
- The Alt + Tab switcher and the Task view moved, closed and focused windows with the old dispatcher names (focuswindow, closewindow, movetoworkspacesilent, workspace), which a Lua-config Hyprland (0.55 and newer) refuses: you could cycle through windows, but letting go of Alt did not focus the one picked. They now use the Lua calls (hl.dsp.focus, hl.dsp.window.close / move) and fall back to the old names on an older Hyprland. Window addresses are checked before they go into a command. Thanks, Fedora 44 reporter, for finding the exact line

## V4.42: foot 1.26 and newer (issue #13)
- foot 1.28 refused ~/.config/foot/darkshadow.ini ("invalid section name"): the shell wrote the old [colors] and [cursor] sections, which foot 1.26 renamed to [colors-dark] (the cursor colors moved into it). rice-look now asks foot for its version and writes the right ones for it (an older foot keeps the old ones). Thanks, Kikurory, for the exact report

## V4.41: the login screen puts the on-screen keyboard away by itself
- The big on-screen keyboard still came back after a reboot for some (SDDM's own config can start it, and a config line is easy to miss). The login screen now hides it as soon as it opens, whatever SDDM's config says. For a touch screen: virtualKeyboard=true in the theme's theme.conf. Put the new theme in with Settings > Idle & Lockscreen > Login screen > Update it, or rice-sddm install

## V4.40: the installer shows the long steps, and can skip the system update
- "It spins for ever": the system update (Arch: pacman -Syu) and the package install ran behind a spinner with their output hidden, so a slow download, a full system update on an old install or another pacman holding the lock looked like a hang (one report: 1100 s). They now print what they do, line by line, with the time at the end (the same for dnf on Fedora)
- ./install.sh --no-upgrade (Arch): skip the full system update and only install what the shell needs
- It says so before it starts when another pacman is running or pacman's lock file (db.lck) was left behind by a stopped update

## V4.39: no big on-screen keyboard on the login screen
- The login screen showed Qt's on-screen keyboard when the password field was clicked (a theme installed before sets InputMethod=qtvirtualkeyboard in /etc/sddm.conf). Use it now turns that off too (the line is kept and Back to SDDM's theme puts it back)

## V4.38: the login screen wins over another SDDM theme
- A theme installed before (sddm-astronaut and others) often sets itself in /etc/sddm.conf, which SDDM reads last, so the shell's login screen never showed. Use it now switches that line off (and keeps it: Back to SDDM's theme puts it back), and Settings shows which theme SDDM really uses

## V4.37: your own window rules, a gaming workspace, the shell's own login screen (SDDM)
- Settings > Desktop > Window rules: rules of your own for any app (where it opens and whether in the background, floating, centered, a size, on every workspace, fullscreen or maximized, see-through). Pick a window that is open now, or type its app id or title. They are kept in ~/.config/rice/rules.json, which no update touches (editing hyprland.lua by hand is lost on update; this is not). Hyprland and niri
- Gaming workspace (Window rules, or Gaming > Gaming workspace): Steam, Proton, Wine, gamescope and Minecraft games open on a workspace of their own (9 by default, or any number or name). Options: go there when a game starts, the launchers (Steam, Heroic, Lutris, Bottles, Prism, RetroArch) there too, games fullscreen, no gaps there
- The shell's own login screen for SDDM, in Material 3: your wallpaper and a big clock; press a key and it blurs, the clock moves up and the login card rises, with your picture in a slowly turning shape, the session and keyboard layout, sleep, restart and shut down. It follows your wallpaper, its colors, the shell's font and language by itself. Settings > Desktop > Idle & Lockscreen > Login screen: Use it (asks for your password once), Preview, Make SDDM start at boot, Back to SDDM's theme. A fresh install asks. NixOS: programs.shadows-shell.sddm = true;

## V4.36: Settings follows the wallpaper's colors, real blur on niri, Settings always opens at once
- Settings took its colors only when it started: change the wallpaper while it was open (or waiting in the background) and it kept the old ones, green on a black wallpaper. It now reads the theme's colors again whenever they change
- niri: Settings blurred only the wallpaper (xray), not the windows behind it (a browser did not show through). Its blur now shows what is really behind it
- Settings opens at once every time: it starts hidden a few seconds after login and waits, and after you close it it waits again instead of quitting (before, it waited three minutes, so most openings were a cold start). While it waits it does nothing (no checks every few seconds). Light mode keeps the old way, to save memory. How each opening went is in ~/.cache/rice/settings-open.log

## V4.35: the whole shell in your language, blur stays, Japanese / Korean / Chinese letters
- Languages for the whole shell, not only Settings: the bar, its cards, the control center, the menus (Wi-Fi, Bluetooth, power, volume), notifications, the launcher, the clipboard, the wallpaper picker, the widgets and the lock screen now come in all 20 languages of Settings > System > Languages (they were only English and Polish). The lock screen's dates, days and months follow the language too
- Settings lost its blur in Polish (and other languages): the window's title was translated, and Hyprland and niri find the Settings window by its title (blur, size, floating). The title now stays the same in every language
- Japanese, Korean and Chinese showed boxes: choosing one of them downloads its font (Noto Sans JP / KR / SC, about 13 MB, no password), then Settings and the shell start again with it. At login the font is fetched too if it is missing

## V4.34: a new wallpaper picker, wallpapers off, Bluetooth headphones, Flatpak apps
- New wallpaper picker (SUPER + W): a Material 3 carousel. The wallpaper in focus is big in the middle (sharp, the picture itself), the ones next to it get narrower the farther they are. Wheel, arrows or a click move it; Enter, a click on the big one or Set as wallpaper sets it. Search, and All / Pictures / Live (Tab), shuffle. It is much lighter: only 15 cards are ever made, they use the small previews, and one mask rounds all of them (the old grid made a card with its own effect for every wallpaper and read the list again every few seconds, which could crash it with many wallpapers)
- Settings > Wallpaper > Wallpaper control: Wallpapers from the shell off = the shell sets no wallpaper at all (no awww, no live wallpaper, no slideshow), for your own wallpaper tool; Wallpaper picker off = SUPER + W does nothing
- Bluetooth headphones that connected for a second and dropped: connecting stops the device search first, trusts the device and checks it stays connected (it tries again). When PipeWire has no Bluetooth audio, the menu says so (Arch: the installer adds pipewire-audio)
- Flatpak apps in the launcher: the shell (and Hyprland's apps) know flatpak's app folders, also when the session did not get them from /etc/profile.d. Nothing to add by hand any more (and no update removes it)
- Settings opens instantly the second time: closed, it waits hidden for three minutes before it quits
- btop: the transparent theme is put in place right away by the update

## V4.33: a transparent btop theme
- btop now looks like the rest of the shell: a see-through theme ("darkshadow", purple accent; the terminal's own background and blur show through), used by default. With wallpaper colors on, btop uses the "matugen" theme, which follows the wallpaper. A theme you picked yourself in btop is left alone (the installer only replaces Default / TTY)

## V4.32: clipboard history, less memory, updates keep your edits
- New: the clipboard (SUPER + V, issue #5). Everything you copy, texts and pictures, newest first (cliphist): search, Enter puts it back and pastes it into the window you were in, Del removes it, Ctrl + P pins a text to the top, Tab goes through All, Text, Pictures and Pinned. It rises from the bottom of the screen. Settings > Desktop > Clipboard: on / off, paste right away, pictures, how many to keep, clear the history. Float / tile a window moved to SUPER + SHIFT + V (Hyprland and niri). The installer adds cliphist and wtype
- Less memory from the start (issue #6): a desktop widget that is off is no longer made at all (it used to sit in memory, hidden); the control center, the wallpaper picker, the game bar and the Wi-Fi, Bluetooth, power and volume menus are only made when you open them, and let go two minutes after they close
- Light mode (Settings > Desktop > Performance, or Home): the control center and the bar's cards open quicker. Light mode already turns off blur, see-through and shadows for slower laptops
- Updates keep your edits (issue: "Updates break custom configs"): a Quickshell file you changed is kept as it is; the new version lands next to it (FILE.rice-update) and the update lists them. Your own Hyprland settings go into ~/.config/hypr/user.lua: loaded last, no update ever touches it (RICE_OVERWRITE=1 ./install.sh --update takes every new file)
- A key that could not be typed (issue: "cant use letter after a", B): anything that binds a plain letter with no modifier is taken off at start, with a notification saying what it was (hypr-set keycheck lists them, ~/.cache/rice/keycheck.log)

## V4.31: no more piling swaync-client processes (issue #10)
- With DarkShadow notifications (not SwayNC), the hot corner panel's state still asked swaync-client for Do Not Disturb every few seconds. Without swaync running, swaync-client waits for it forever; when the caller was stopped, these calls stayed behind (dozens of them, each holding a D-Bus connection), until the user D-Bus ran out of files and the session ended. Thanks to the reporter of issue #10 for tracking it down
- rice-hotcorner reads Do Not Disturb from the shell (cc.json) in DarkShadow mode, and its DND button goes through rice-cc (shell or SwayNC, whichever shows notifications)
- The lock screen's notification count no longer asks swaync in DarkShadow mode
- Every remaining swaync-client call (SwayNC mode) uses --skip-wait and a time limit, so none can hang

## V4.30: no more pale squares on niri, the music card cleans up
- niri: the blur behind cards, menus, the island and the bar showed as pale squares around the rounded corners on some setups. The blur now follows the rounded corners from the inside (in small steps), so nothing shows past the edges
- Music card: the lyrics box has its rounded corners again (its fades were square), and when nothing plays any more the last song's lyrics go away
- Bar: the Music module is as narrow as the other icons while nothing plays (it had extra room around it); a song makes it a small pill with the bars

## V4.29: a new lock screen, a music card on the bar, dock icons in your colors, smoother Task view
- New lock screen (Style: Cards, the default): the month with today in your shape, the time on its own tall card with the seconds going round, your music with the cover and buttons, and a bar at the bottom with the battery, the keyboard layout (click to switch), the password and the power buttons. SUPER + L: the wallpaper zooms and blurs in, the cards rise one after another. Every key drops in a shape with a ring around it; a wrong password shakes and the shapes fall; the right one opens the lock. Settings > Idle & Lockscreen > Style: Cards or Classic (the old one)
- The keyboard layout no longer turns to US after an update: the installer keeps your layout (it is saved in hypr.json once) and writes your Hyprland settings again after copying the files
- New bar module: Music (put on your bar once, on the right). A note with small dancing bars while a song plays; a click opens a music card that grows out of the bar: the cover in a turning halo of your shape, the song, synced lyrics, a wavy progress line you can drag, the buttons and the volume
- Dock: app icons take a shade of your wallpaper's color (Settings > Interface > Dock > Match the wallpaper, on by default)
- Task view: no more lagging label under the window you drag; a window dropped on another workspace moves there at once (with an animation), the workspace under it lights up while you drag

## V4.28: Task view and Alt + Tab on niri, your own keybinds in Keybinds
- niri: SUPER + Tab opens the shell's Task view and ALT + Tab its window switcher (like on Hyprland). niri's own Alt + Tab switcher is turned off (recent-windows off), niri's overview moved to SUPER + O
- Settings > Keybinds: your own keybinds (any app or command on keys you pick) are right on the page now, under the shell's keys (before, the button led to the Windows page and the Keybinds tab was easy to miss). The Task view and the switcher can get other keys there too (the pencil), on niri as well

## V4.27: Task view and Alt + Tab (Hyprland)
- New: the Task view (SUPER + Tab): every workspace as a small screen with its windows where they are, as live pictures (or their icons). Type to find a window (Enter goes to it), arrows pick a workspace, a click goes to a window, drag a window onto another workspace to move it there, middle click or the x closes it, Esc closes the view. The screen behind it is blurred
- New: the window switcher (ALT + Tab): your windows in the order you used them; hold ALT, Tab goes on, SHIFT + Tab back, let go to go to the picked one
- Settings > Desktop > Task view: Super alone opens it (press and let go), live pictures, empty workspaces too, 5 or 10 workspaces. The keys can be changed in Settings > Keybinds (the pencil)
- niri keeps its own overview (Mod + Tab) and switcher (Alt + Tab)

## V4.26: the updater works again, colors follow the wallpaper at once, frame rate for widgets
- Update Center (Settings): when git pull could not go through (files changed in the repo, or a history that went another way), the update carried on with the old files and said it was done, so the version never moved. Now your changes are kept aside (a branch rice-before-update-DATE and a git stash) and the repo takes GitHub's newest version; offline, it says so and changes nothing
- The visualizer kept the previous wallpaper's color until the next change (it read the new color one step too early); it takes the new one at once now
- New: Settings > Desktop > Frame rate for the moving parts of the widgets (turning shapes, the visualizer): 30, 60 (default), 120 or Screen (as fast as your monitor, 144 or 180 Hz). desktop-set widgets-fps
- The island's card and the bar's cards (Weather, System, Date) no longer stay open together: one closes when the other opens
- Void Linux is no longer supported: gone from the installer and the README

## V4.25: the bar's cards grow out of the bar
- The cards of Weather, System and Date open like the Dynamic island: the module's pill stretches out of the bar into the card with a soft overshoot, the corners round off, and the content comes in once there is room; closing folds it back quickly
- Going from one card to another (Weather, then System) cross-fades the content

## V4.24: Weather, System and Date on the bar
- New bar modules (Settings > Bar layout): Weather (the sky and the temperature), System (CPU, RAM and disk in small rings) and Date (the day and the date, the time in a chip of your theme color)
- Each opens a small card under it: Weather the place, the temperature, how it feels, high and low, wet and windy, and the next hours; System a tile for CPU, RAM, disk and swap with a bar and the numbers; Date the month, this week with today, your to-do tasks and how long the computer is up. Esc, a click outside or the module again closes it
- On a side bar they are there too; their cards open at the top, beside the bar
- The System desktop widget from V4.23 is gone (it lives on the bar now); Forecast, Music card and Date & time stay

## V4.23: new widgets, one widget style, Infinite Desktop for Hyprland only
- New widget Forecast: where you are, the temperature in big numbers, the sky in your shape, how it feels, today's high and low and the next hours (rice-weather json, from wttr.in every half hour)
- New widget System: a slim pill with CPU, RAM, disk and swap in small rings; a click opens a card under it with a tile for each (how much is used, a bar, the numbers and the CPU heat)
- New widget Music card: the cover, the song, a wavy line and the buttons (the play button is a cookie that turns); the words button opens it downwards to the lyrics, which run with the song, the line being sung bright in the middle
- New widget Date & time: a slim pill with the day and the date, the time in a chip of your theme color
- One widget style: Google (Material You cards in your theme color); DarkShadow and Outline are gone
- rice-stats also tells swap and disk use
- niri: Infinite Desktop is gone (it stays on Hyprland); its keys are no longer made, Settings no longer lists it there

## V4.22: the shell starts again
- V4.21 did not start on some Qt versions ("Zone is not a type" in VBar.qml): the side bar's zone is declared before it is used now

## V4.21: the bar on the left or right edge, done properly
- The styles work on a side bar too: dynamic and islands give a pill for each zone (top, middle, bottom), pills one for each module, island one pill, flat the whole edge (before, every style was one long joined pill)
- The launcher on a side bar shows your distro's logo again (and the black hole or the moon), like on the top bar
- Wi-Fi, Bluetooth, sound and power open beside a side bar, level with their icon (before, they opened up at the top, far from it)
- The clock on a side bar works: a click opens the island's Today card (calendar, weather) at the top of the screen
- The bar slides in when it moves to another edge and slides out of the old one (Hyprland and niri); top and bottom too
- No second, odd Wi-Fi or Bluetooth icon in the tray of a side bar (nm-applet and blueman are hidden when the bar shows Wi-Fi and Bluetooth itself, as on the top bar)

## V4.20: menus blur sooner, colors in the sound menu, faster scrolling
- niri: the Wi-Fi, Bluetooth, sound and power menus, the control center, the game bar and the wallpaper picker were see-through for half a second after opening and only then turned blurred; the blur now comes in as soon as the menu has nearly arrived
- The sound menu has your theme color: the sliders, their knobs, the chosen output and microphone and the icon (all white before)
- The theme color in the menus (sound, Wi-Fi, Bluetooth) is made bright enough to stand out: a dark wallpaper gave a dark, muddy accent on the switches
- Settings scrolls faster by default (1.8x; Home > Scrolling changes it)
- "Hide while windows are open" is on for the desktop widgets from the start

## V4.19: a lighter visualizer
- One cava for the whole shell: the visualizer on the bar and the visualizer widget used to start one cava each and read every frame twice; now they share one, and it stops when nothing shows the music
- The visualizer widget draws with much less work: the colours of the bars are worked out once (not for every bar 30 times a second), bars of one colour are drawn in one go, and the fade is one gradient over the whole picture instead of one for every bar. Less work also means fewer pauses of the whole shell (the bar included) while music plays
- cava rests after 2 seconds of silence

## V4.18: blur behind the bar in the overview (niri)
- niri: in the overview (Win + Tab) and while workspaces slide, windows pass behind the bar and the island; since V4.15 they showed through it unblurred, like a hole. The bar, the island and the dock blur what is behind them again, windows too (V4.15 had switched them to the shared wallpaper-only blur to save work). The desktop widgets keep the shared blur

## V4.17: no more overlapping in the bar while you switch workspaces
- The Dynamic Island: the workspace face and the recording timer (or any two faces) were on top of each other when the modes changed quickly, e.g. scrolling through workspaces while recording. The old face now goes first and the new one comes after it
- The bar: the window title showed over the buttons next to it (power, notifications ...) while it grew in or folded away when the focus changed. Modules are now cut at their slot while they move

## V4.16: a rounder charger animation
- The charger glow and the light on the bar are round with soft ends (the square edges came from Qt ignoring the corner radius of a gradient); the rings stay inside the island; unplugging shows your level at once instead of counting down from 100

## V4.15: niri blur fixes, smoother niri, charger animation
- **Charger animation** in the Dynamic Island: plug in and a green bolt pops in with two rings spreading out, a glow goes through the island, the bar fills up to your battery level and the number counts up; unplug and the battery icon drops in. It now follows "on battery" from UPower, so it also shows on laptops that keep the battery below full
- niri: the **launcher** (and menus) blur again after the first time they open (the blur was lost when the window was shown again)
- niri: the **cookie clock** gets blur too (a round blur just inside its waves) and a frosted face like the other widgets
- niri runs smoother with a live wallpaper: the bar, the dock and the game bar use the shared blur (worked out once per frame) instead of their own; menus keep the blur that shows windows behind them
- Live wallpapers are lighter: hardware decoding (auto-safe), the fast mpv profile and dropped frames instead of a backlog

## V4.14: Void badge
- The README shows Void Linux next to Arch, CachyOS, Fedora and NixOS

## V4.13: Void fixes from the first test
- The lock screen and idle timers step no longer fails on a system without `pkill` or systemd (found on Void)
- Void: `procps-ng`, `findutils` and `fontconfig` are installed with the rest, so the font check and process tools work on a minimal system

## V4.12: installer as root (containers, VMs), minimal systems
- Run as root on purpose (`SHADOWS_ALLOW_ROOT=1`, a container or a VM): sudo is no longer called, so "sudo: PAM error" does not stop the package step
- A minimal system without `find`, `sort` or `tar` (a Void container): the installer installs them first, or says what is missing instead of copying 0 scripts

## V4.11: Void Linux support
- **Void Linux** (no systemd): `./install.sh` installs everything with xbps. Quickshell, niri, awww, matugen and the tools come from Void's own repositories; Hyprland (with Lua) from the hyprland-void binary repository, which the installer adds (when it cannot, niri is set up instead). glibc and musl, x86_64 and aarch64
- runit services are turned on for you: D-Bus, elogind, Bluetooth, power modes, and NetworkManager only when nothing else manages your network
- PipeWire with WirePlumber and the PulseAudio bridge starts at login without systemd
- New `rice-sys`: sleep, restart, shut down, lock and Keep Awake work with and without systemd (loginctl from elogind), in the power menu, the lock screen, notifications and the idle timers
- Settings > Look & Feel installs shells and terminals with xbps on Void; package count in the system info counts xbps packages

## V4.10: README and installer text cleaned up
- The README and the installer no longer mention the dashboard and the hot corner (both are long gone from the shell)

## V4.09: a shorter update
- The update no longer asks questions (your configs and settings stay) and no longer shows the install plan, the "Next" tips or ten separate lines for dashboard, blur, hot corner and so on: one line "Refreshing your settings"
- Old backups are deleted after each install or update (the first and the newest two stay), so ~/.config stays small and fast

## V4.08: lint fix
- GitHub check (ShellCheck) passes again

## V4.07: no cursor on CachyOS, AUR helper choice, no WM question
- **Cursor fix**: the installer gave the cursor setup only 10 seconds, which cut off the Bibata download, so some computers (CachyOS) had no cursor. It now has 120 seconds, finds the theme under any spelling of its folder name, and falls back to a working theme
- `rice-cursor doctor` (or `./install.sh --doctor`): prints what is installed (themes, yay, paru, session) to paste, and repairs the cursor
- `./install.sh --helper=yay` or `--helper=paru`: choose the AUR helper (paru is used first when you have it; it can be built too)
- The installer no longer asks "Which window manager?": Hyprland is set up (or what you had). niri: `./install.sh --wm=niri` or `--wm=both`

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
