TERMUX_PKG_HOMEPAGE=https://github.com/fatuhsa/termux-snx
TERMUX_PKG_DESCRIPTION="Hello world package for the io.sanix (Sanix) repository"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@fatuhsa"
TERMUX_PKG_VERSION=1.0.0
TERMUX_PKG_REVISION=0
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_SKIP_SRC_EXTRACT=true
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_make() {
	:
}

termux_step_make_install() {
	install -Dm755 "$TERMUX_PKG_BUILDER_DIR/sanix-hello" "$TERMUX_PREFIX/bin/sanix-hello"
}
