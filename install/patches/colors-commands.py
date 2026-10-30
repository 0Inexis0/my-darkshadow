import os,sys
p=sys.argv[1]; s=open(p).read()
if "rice-colors\" scheme" in s or "rice-colors scheme" in s:
    print("commands.sh already patched"); sys.exit(0)
old='''case "$(cat "$HOME/.config/rice/color-mode" 2>/dev/null)" in
  grey) sat=0; lum=50 ;;
  navy) sat=0; lum=0 ;;
esac

if awk "BEGIN{exit !($sat < 12)}"; then
'''
new='''mode="$(cat "$HOME/.config/rice/color-mode" 2>/dev/null)"
scheme=""
case "$mode" in
  grey) sat=0; lum=50 ;;
  navy) sat=0; lum=0 ;;
  ""|auto) ;;
  *) scheme="$("$HOME/.local/bin/rice-colors" scheme "$mode" 2>/dev/null)" ;;
esac

if [ -n "$scheme" ]; then
  # named color scheme from Settings > Home > Colors: "<matugen type> <seed> <workspace marker>"
  read -r stype seed ws <<<"$scheme"
  cmd=(matugen color hex "$seed" --type "$stype" -q)
elif awk "BEGIN{exit !($sat < 12)}"; then
'''
if s.count(old)!=1:
    print("commands.sh differs from the expected text, not patched"); sys.exit(2)
open(p,'w').write(s.replace(old,new))
print("patched")
