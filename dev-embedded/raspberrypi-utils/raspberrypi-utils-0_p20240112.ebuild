# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit bash-completion-r1 cmake

COMMIT="193e6e34b40807cbeedee2e4abc3ef5165e14ae2"

DESCRIPTION="Raspberry Pi userspace utilities"
HOMEPAGE="https://github.com/raspberrypi/utils"
SRC_URI="https://github.com/raspberrypi/utils/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~arm ~arm64"

RDEPEND="
	!media-libs/raspberrypi-userland
	!media-libs/raspberrypi-userland-bin
"

S="${WORKDIR}/utils-${COMMIT}"

src_configure() {
	local mycmakeargs=( -DBUILD_SHARED_LIBS=OFF )
	cmake_src_configure
}

src_install() {
	cmake_src_install

	local SRC
	rm -r "${ED}"/usr/share/bash-completion/ || die
	for SRC in */*-completion.bash; do
		local DEST=${SRC%-completion.bash}
		newbashcomp "${SRC}" "${DEST##*/}"
	done
}
