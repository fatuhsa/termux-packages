#!/usr/bin/env bash
set -euo pipefail
# Generate the Sanix (io.sanix) apt repository layout from built .deb files.
# Produces ./repo/ with pool/ and dists/ and signs it with the imported GPG key.

TERMUX_SCRIPTDIR=$(cd "$(realpath "$(dirname "$0")")"; cd ..; pwd)
: "${TERMUX_OUTPUT_DIR:="$TERMUX_SCRIPTDIR/output"}"
REPO_DIR="$TERMUX_SCRIPTDIR/repo"
POOL_DIR="$REPO_DIR/pool/main"
DISTS_DIR="$REPO_DIR/dists"
SUITE="stable"

rm -rf "$REPO_DIR"
mkdir -p "$POOL_DIR" "$DISTS_DIR"

# Copy debs into pool/main/<first-letter>/<name>/
for deb in "$TERMUX_OUTPUT_DIR"/*.deb; do
	[ -f "$deb" ] || continue
	name="$(basename "$deb")"
	subdir="${name%%_*}"
	letter="${subdir:0:1}"
	mkdir -p "$POOL_DIR/$letter"
	cp "$deb" "$POOL_DIR/$letter/$name"
	echo "Packed: $name"
done

[ -n "$(find "$POOL_DIR" -name '*.deb' | head -1)" ] || {
	echo "No .deb files found in $TERMUX_OUTPUT_DIR" >&2
	exit 1
}

python3 "$TERMUX_SCRIPTDIR/scripts/sanix-generate-packages.py" "$REPO_DIR" "$POOL_DIR" "$DISTS_DIR"

# Sign Release -> InRelease + Release.gpg
if [ -f "${REPO_GPG_KEY_ID:-}" ]; then
	KEY_ID="$(cat "$REPO_GPG_KEY_ID")"
elif [ -n "${REPO_GPG_KEY_ID_OVERRIDE:-}" ]; then
	KEY_ID="$REPO_GPG_KEY_ID_OVERRIDE"
else
	KEY_ID=""
fi
SIGN_ARGS=()
[ -n "$KEY_ID" ] && SIGN_ARGS+=("-u" "$KEY_ID")

echo "== Signing Release =="
gpg --batch --yes --armor "${SIGN_ARGS[@]}" --detach-sign -o "$DISTS_DIR/$SUITE/Release.gpg" "$DISTS_DIR/$SUITE/Release"
gpg --batch --yes --armor "${SIGN_ARGS[@]}" --clearsign -o "$DISTS_DIR/$SUITE/InRelease" "$DISTS_DIR/$SUITE/Release"

# Export the public key for easy on-device installation
gpg --batch --armor --export > "$REPO_DIR/sanix-repo.gpg" 2>/dev/null || true

echo "== Repository generated at $REPO_DIR =="
find "$REPO_DIR" -type f | sort