-- Infinite Desktop's Lua config with a fake Hyprland: the two screen modes (Settings > Desktop > Infinite Desktop >
-- Screens), a new window on the second screen, and turning it off. Run by tests/infinite.sh.
local path = arg[1]
local moves, focuses, floatarr, events = {}, {}, {}, {}
local n = 0
local function ok(msg) n = n + 1; print("ok " .. n .. " - " .. msg) end
local function bad(msg) print("not ok " .. (n + 1) .. " - " .. msg); os.exit(1) end
local function check(c, msg) if c then ok(msg) else bad(msg) end end
local function rec(d) if type(d) == "function" then d() else events[#events + 1] = d end end

local function mon(name, x, y)
    return { name = name, x = x, y = y, width = 1920, height = 1080, scale = 1, reserved = { left = 0, top = 0, right = 0, bottom = 0 } }
end
local M1, M2 = mon("DP-1", 0, 0), mon("HDMI-A-1", 1920, 0)

local function win(addr, wsid, m, x, y, w, h)
    return { address = addr, workspace = { id = wsid }, monitor = m, at = { x = x, y = y }, size = { x = w or 400, y = h or 300 },
        mapped = true, hidden = false, floating = true, pinned = false, fullscreen = 0, class = "app" }
end
local W = { win("0xa", 1, M1, 100, 100), win("0xb", 11, M2, 100, 100) }
local active_ws, cursor = 1, { x = 100, y = 100 }
local function at(t, fn) for _, w in ipairs(W) do if "address:" .. w.address == t.window then fn(w) end end end

hl = {
    on = function() end, bind = function() end, unbind = function() end, exec_cmd = function() end,
    get_windows = function() return W end,
    get_active_workspace = function() return { id = active_ws } end,
    get_active_window = function() return W[1] end,
    get_active_monitor = function() return M1 end,
    get_cursor_pos = function() return cursor end,
    get_monitor_at = function(x) return x >= 1920 and M2 or M1 end,
    dispatch = rec,
    dsp = {
        window = {
            move = function(t) return function() moves[#moves + 1] = t; at(t, function(w) w.at.x, w.at.y = t.x, t.y end) end end,
            resize = function(t) return function() at(t, function(w) w.size.x, w.size.y = t.x, t.y end) end end,
            float = function(t) return function() floatarr[#floatarr + 1] = t.action end end,
            close = function() return function() end end,
        },
        focus = function(t) return function() focuses[#focuses + 1] = t; if t.workspace then active_ws = t.workspace end end end,
        exec_cmd = function() return function() end end,
    },
}
assert(loadfile(path))()

-- screens = 1: only the workspace it was turned on
RiceInfinite.cfg.screens = 1
RiceInfinite.set(true)
check(RiceInfinite.on, "it is on")
local before = #moves
RiceInfinite.pan(100, 0)
local a = 0
for i = before + 1, #moves do if moves[i].window == "address:0xa" then a = a + 1 end end
check(a > 0, "screens = 1: the window of the workspace moves")
local b = 0
for i = before + 1, #moves do if moves[i].window == "address:0xb" then b = b + 1 end end
check(b == 0, "screens = 1: the window of the other screen stays")
RiceInfinite.set(false)
check(not RiceInfinite.on, "it is off")

-- screens = 0 (the default): every screen
RiceInfinite.cfg.screens = 0
W = { win("0xa", 1, M1, 100, 100), win("0xb", 11, M2, 1970, 100) }
before = #moves
RiceInfinite.set(true)
check(RiceInfinite.on, "it is on with every screen")
RiceInfinite.pan(100, 0)
a, b = 0, 0
for i = before + 1, #moves do
    if moves[i].window == "address:0xa" then a = a + 1 end
    if moves[i].window == "address:0xb" then b = b + 1 end
end
check(a > 0 and b > 0, "screens = 0: the windows of both screens move")

-- a window that opens on the second screen gets its room there, inside that screen
cursor = { x = 2000, y = 300 }
local fresh = win("0xc", 11, M2, 2000, 300, 700, 500)
fresh.floating = false
W[#W + 1] = fresh
RiceInfinite.opened(fresh)
check(fresh.at.x >= 1920 and fresh.at.x + fresh.size.x <= 3840, "the new window stays on its own screen")

-- off: every screen is put back and tiled again
RiceInfinite.set(false)
check(floatarr[#floatarr] == "unset", "off tiles it again")
check(focuses[#focuses].window == "address:0xc", "the new window was focused")
check(not RiceInfinite.on, "it is off again")
