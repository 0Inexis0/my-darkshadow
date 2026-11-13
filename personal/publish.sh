#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
command -v gh >/dev/null || { echo 'Install GitHub CLI and run gh auth login first.' >&2; exit 1; }
[[ "$(gh api user --jq .login)" == 0Inexis0 ]] || { echo 'Log in as 0Inexis0.' >&2; exit 1; }
python3 personal/check-publication.py
[[ -z "$(git status --porcelain)" ]] || { echo 'Commit the reviewed changes first.' >&2; exit 1; }
if ! gh repo view 0Inexis0/my-darkshadow >/dev/null 2>&1; then
  gh repo fork shadowww-dev/DarkShadowShell --fork-name my-darkshadow --default-branch-only --clone=false
fi
[[ "$(gh api repos/0Inexis0/my-darkshadow --jq .parent.full_name)" == shadowww-dev/DarkShadowShell ]] || {
  echo 'The destination is not the expected upstream fork.' >&2; exit 1;
}
gh auth setup-git
git push https://github.com/0Inexis0/my-darkshadow.git HEAD:main
gh repo edit 0Inexis0/my-darkshadow --default-branch main \
  --description 'Personal DarkShadow desktop with SDDM, scaling fixes and a NixOS installation ISO'
echo 'Published https://github.com/0Inexis0/my-darkshadow/tree/main'
