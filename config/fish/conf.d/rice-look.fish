# DarkShadow's Shell (Settings > Desktop > Look & Feel): fastfetch when a terminal opens
if status is-interactive; and test -e "@HOME@/.config/rice/fetch-on-open"; and test "$TERM_PROGRAM" != vscode; and type -q fastfetch
    fastfetch
end
