#!/bin/sh
# gecko installer — puts the CLI on your PATH and installs the skill.
#
#   curl -fsSL https://raw.githubusercontent.com/lucasvidela94/gecko/main/install.sh | sh
#
# Flags:
#   --version vX.Y.Z   install a specific version (default: latest release)
#   --bin DIR          where to put the CLI (default: $HOME/.local/bin)
#   --no-cli           skip the CLI
#   --no-skill         skip the skill
#
# Env: GECKO_VERSION, GECKO_BIN

set -eu

OWNER=lucasvidela94
REPO=gecko
PROG=gecko

VERSION="${GECKO_VERSION:-}"
BIN_DIR="${GECKO_BIN:-$HOME/.local/bin}"
DO_CLI=1
DO_SKILL=1

die() { printf '%s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --version) [ $# -ge 2 ] || die "--version needs a value"; VERSION=$2; shift 2 ;;
    --bin)     [ $# -ge 2 ] || die "--bin needs a value"; BIN_DIR=$2; shift 2 ;;
    --no-cli)   DO_CLI=0; shift ;;
    --no-skill) DO_SKILL=0; shift ;;
    -h|--help)
      cat <<'EOF'
gecko installer
  --version vX.Y.Z   install a specific version (default: latest release)
  --bin DIR          where to put the CLI (default: $HOME/.local/bin)
  --no-cli           skip the CLI
  --no-skill         skip the skill
EOF
      exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

command -v curl >/dev/null 2>&1 || die "curl is required"
[ "$DO_CLI" -eq 1 ] && { command -v git >/dev/null 2>&1 || die "git is required for the CLI"; }

# Resolve the ref: a pinned version, or the latest release tag, or main.
if [ -z "$VERSION" ]; then
  VERSION=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    "https://github.com/$OWNER/$REPO/releases/latest" 2>/dev/null \
    | sed -E 's#.*/tag/##' || true)
  case "$VERSION" in
    v[0-9]*) : ;;
    *) VERSION=main ;;
  esac
fi

base="https://raw.githubusercontent.com/$OWNER/$REPO/$VERSION"

if [ "$DO_CLI" -eq 1 ]; then
  mkdir -p "$BIN_DIR"
  curl -fsSL "$base/skills/gecko/scripts/gecko" -o "$BIN_DIR/$PROG" \
    || die "download failed at $VERSION"
  chmod 755 "$BIN_DIR/$PROG"
  printf 'installed CLI: %s/%s (%s)\n' "$BIN_DIR" "$PROG" "$VERSION"
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
      # shellcheck disable=SC2016  # the $PATH is meant to be printed literally
      printf 'note: %s is not on your PATH. Add:\n  export PATH="%s:$PATH"\n' "$BIN_DIR" "$BIN_DIR"
      ;;
  esac
fi

if [ "$DO_SKILL" -eq 1 ]; then
  if command -v npx >/dev/null 2>&1; then
    npx --yes skills add "$OWNER/$REPO" -g -y \
      || printf 'note: skill install failed. Run manually: npx skills add %s/%s -g -y\n' "$OWNER" "$REPO"
  else
    printf 'note: npx not found. Install the skill with:\n  npx skills add %s/%s -g -y\n' "$OWNER" "$REPO"
  fi
fi

printf 'done.\n'
