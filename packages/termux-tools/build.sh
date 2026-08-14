TERMUX_PKG_HOMEPAGE=https://termux.dev/
TERMUX_PKG_DESCRIPTION="Basic system tools for Termux"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.46.0+really1.45.0"
TERMUX_PKG_REVISION=4
TERMUX_PKG_SRCURL=https://github.com/termux/termux-tools/archive/refs/tags/v1.45.0.tar.gz
TERMUX_PKG_SHA256=1ae29b1b875d95cc626dae323b45a2ace759969862d96094b2fa6d13bffe20d2
TERMUX_PKG_ESSENTIAL=true
#TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"
TERMUX_PKG_BREAKS="termux-keyring (<< 1.9)"
TERMUX_PKG_CONFLICTS="procps (<< 3.3.15-2)"
TERMUX_PKG_SUGGESTS="termux-api"

# Some of these packages are not dependencies and used only to ensure
# that core packages are installed after upgrading (we removed busybox
# from essentials).
TERMUX_PKG_DEPENDS="bzip2, coreutils, curl, dash, diffutils, findutils, gawk, grep, gzip, less, procps, psmisc, sed, tar, termux-am (>= 0.8.0), termux-am-socket (>= 1.5.0), termux-core, termux-exec, util-linux, xz-utils, dialog"

# Optional packages that are distributed as part of bootstrap archives.
TERMUX_PKG_RECOMMENDS="ed, dos2unix, inetutils, net-tools, patch, unzip"

termux_step_post_get_source() {
	# Replace the upstream mirror list with a single "default" mirror
	# pointing at the Sanix (io.sanix) repository. The `pkg` command
	# rewrites $PREFIX/etc/apt/sources.list from these files whenever the
	# apt cache is stale; without this, it would rotate back to the
	# official Termux mirrors, whose packages are built for com.termux
	# and cannot be installed on io.sanix. Keep mirrors/Makefile.am so
	# autoreconf can still generate mirrors/Makefile.in.
	rm -rf "$TERMUX_PKG_SRCDIR/mirrors/asia" "$TERMUX_PKG_SRCDIR/mirrors/chinese_mainland" \
		"$TERMUX_PKG_SRCDIR/mirrors/europe" "$TERMUX_PKG_SRCDIR/mirrors/north_america" \
		"$TERMUX_PKG_SRCDIR/mirrors/oceania" "$TERMUX_PKG_SRCDIR/mirrors/russia"
	find "$TERMUX_PKG_SRCDIR/mirrors" -maxdepth 1 -type f ! -name 'Makefile.am' -delete
	mkdir -p "$TERMUX_PKG_SRCDIR/mirrors"
	cat > "$TERMUX_PKG_SRCDIR/mirrors/default" <<- EOF
	# Sanix (io.sanix) repository
	WEIGHT=10
	MAIN="https://fatuhsa.github.io/termux-packages"
	ROOT=""
	X11=""
	EOF
}

termux_step_pre_configure() {
	# Replace the `com.termux` package name in source files, since the
	# `TERMUX_APP_PACKAGE` env var is not exported by the build system
	# and `configure.ac` would otherwise fall back to `com.termux`.
	# `io.sanix` is shorter than `com.termux`, so no path length issues.
	find . -type f -exec sed -i "s|com\.termux|$TERMUX_APP__PACKAGE_NAME|g" {} \;
	autoreconf -vfi
}

termux_step_post_make_install() {
	TERMUX_PKG_CONFFILES="$(cat "$TERMUX_PKG_BUILDDIR/conffiles")"

	# Custom Sanix welcome message (replaces the upstream motd).
	cat > "$TERMUX_PREFIX/etc/motd" <<- EOF
	Welcome to Sanix (io.sanix Termux fork)!

	Docs:       https://github.com/fatuhsa/termux-snx
	Community:  https://github.com/fatuhsa/termux-packages

	Working with packages:
	 - Search:  pkg search <query>
	 - Install: pkg install <package>
	 - Upgrade: pkg upgrade

	Report issues at https://github.com/fatuhsa/termux-packages/issues
	EOF
	# The dynamic motd shown on wide terminals is generated from motd.sh.in;
	# replace its title so it does not claim to be Termux.
	sed -i 's/Welcome to Termux!/Welcome to Sanix!/g' "$TERMUX_PREFIX/etc/motd.sh" 2>/dev/null || true
}

termux_step_create_debscripts() {
	cat <<- EOF > ./preinst
	$(cat "$TERMUX_PKG_BUILDDIR/preinst")
	EOF
}
