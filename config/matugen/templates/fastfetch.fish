function __hex2rgb
    set -l h (string replace '#' '' $argv[1])
    printf '38;2;%d;%d;%d' 0x(string sub -s 1 -l 2 $h) 0x(string sub -s 3 -l 2 $h) 0x(string sub -s 5 -l 2 $h)
end

function fastfetch
    command fastfetch \
        --color-keys (__hex2rgb '{{colors.primary.default.hex}}') \
        --color-title (__hex2rgb '{{colors.tertiary.default.hex}}') \
        --logo-color-1 (__hex2rgb '{{colors.primary.default.hex}}') \
        --logo-color-2 (__hex2rgb '{{colors.secondary.default.hex}}') \
        $argv
end
