.pragma library

function valid(value) {
    return typeof value === "number" && isFinite(value) && value >= 0.5 && value <= 4;
}

function forScreen(scales, output, nativeScale) {
    if (scales && valid(scales[output])) return scales[output];
    // Xorg and Hyprland sometimes number the same built-in panel differently.
    if (/^(eDP|LVDS|DSI)-/i.test(output)) {
        var values = [];
        for (var name in scales) {
            if (/^(eDP|LVDS|DSI)-/i.test(name) && valid(scales[name]))
                values.push(scales[name]);
        }
        if (values.length && values.every(function(value) { return value === values[0]; }))
            return values[0];
    }
    return nativeScale > 0 ? nativeScale : 1;
}
