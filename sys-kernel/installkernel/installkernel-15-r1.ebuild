# Copyright 2019-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Gentoo fork of installkernel script from debianutils"
HOMEPAGE="https://github.com/projg2/installkernel-gentoo"
SRC_URI="https://github.com/projg2/installkernel-gentoo/archive/v${PV}.tar.gz
	-> ${P}.tar.gz"
S="${WORKDIR}/${PN}-gentoo-${PV}"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86 ~x86-linux"
IUSE="+dracut grub systemd uki ukify"

RDEPEND="
	!<=sys-kernel/installkernel-systemd-3
	>=sys-apps/debianutils-4.9-r1
	dracut? ( >=sys-kernel/dracut-059-r4 )
	grub? ( sys-boot/grub )
	systemd? (
		|| (
			sys-apps/systemd[kernel-install(-)]
			sys-apps/systemd-utils[kernel-install(-)]
		)
	)
	ukify? (
		|| (
			sys-apps/systemd[ukify(-)]
			sys-apps/systemd-utils[ukify(-)]
		)
	)
	!=sys-apps/systemd-255.2-r1
	!=sys-apps/systemd-254.8-r0
	!=sys-apps/systemd-254.7-r0
	!=sys-apps/systemd-254.5-r1
" # Block against systemd that still installs dummy install.conf

src_install() {
	keepdir /etc/kernel/postinst.d
	keepdir /etc/kernel/preinst.d

	if use dracut; then
		exeinto /etc/kernel/preinst.d
		doexe hooks/50-dracut.install
	fi

	if use grub; then
		exeinto /etc/kernel/postinst.d
		doexe hooks/91-grub-mkconfig.install
	fi

	if use uki; then
		exeinto /etc/kernel/postinst.d
		doexe hooks/90-uki-copy.install
	fi

	if use ukify; then
		exeinto /etc/kernel/preinst.d
		doexe hooks/60-ukify.install
	fi

	if use systemd; then
		sed -e 's/${SYSTEMD_KERNEL_INSTALL:=0}/${SYSTEMD_KERNEL_INSTALL:=1}/g' -i installkernel ||
			die "enabling systemd's kernel-install failed"
	fi

	# set some default config using the flags we have anyway
	touch "${T}/install.conf" || die
	echo "# This file is managed by ${CATEGORY}/${PN}" >> "${T}/install.conf" || die
	if use uki; then
		echo "layout=uki" >> "${T}/install.conf" || die
	elif use grub; then
		echo "layout=grub" >> "${T}/install.conf" || die
	else
		echo "layout=bls" >> "${T}/install.conf" || die
	fi

	if use dracut; then
		echo "initrd_generator=dracut" >> "${T}/install.conf" || die
		if ! use ukify; then
			echo "uki_generator=dracut" >> "${T}/install.conf" || die
		fi
	else
		echo "initrd_generator=none" >> "${T}/install.conf" || die
	fi

	if use ukify; then
		echo "uki_generator=ukify" >> "${T}/install.conf" || die
	else
		if ! use dracut; then
			echo "uki_generator=none" >> "${T}/install.conf" || die
		fi
	fi

	insinto /usr/lib/kernel
	doins "${T}/install.conf"

	exeinto /usr/lib/kernel/install.d
	doexe hooks/systemd/*.install

	into /
	dosbin installkernel
	doman installkernel.8
}

pkg_postinst() {
	elog "Version 14 and up of ${PN} effectively merges"
	elog "${PN}-gentoo and ${PN}-systemd."
	elog "Switching between the traditional installkernel and systemd's"
	elog "kernel-install is controlled with the systemd USE flag or the"
	elog "SYSTEMD_KERNEL_INSTALL environment variable."
	elog
	elog "See the installkernel wiki page[1] for more details."
	elog
	elog "[1]: https://wiki.gentoo.org/wiki/Installkernel"
}
