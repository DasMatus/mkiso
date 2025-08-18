#!/bin/bash
# shellcheck disable=SC2086,SC2046
set -eux -o pipefail
# shellcheck source=settings
source settings
proj_dir=$(pwd)
wget=$(command -v wget || command -v wget2)
USE="X -previewer -webengine "
cp_dirs=(package.use)
cp_to_etc=(skel os-release)
gentoo_cmds=(
			 "getuto"
			 "emerge -vuDN --with-bdeps=y --changed-use @world"
			 "emerge --depclean"
			 "emerge -v eselect-repository linux-firmware display-manager-init sys-kernel/vanilla-sources"
			 "eselect kernel set 1"
)
main() {
	rm -rf /tmp/tmp.* $bdir /tmp/gentoo-snapshot.tar.xz
	mkdir -p $bdir
	for flag in "${flags[@]}"; do
		if [[ -n "$(curl https://www.gentoo.org/support/use-flags/ | grep "use-flag" | grep $flag | sort | uniq)" ]]; then
			USE+="$flag "
			continue
		else
			exit 1
		fi
	done
	$wget $mirror/$version -O /tmp/gentoo-snapshot.tar.xz || echo "Snapshot exists, continuing"
	tar -xpvf /tmp/gentoo-snapshot.tar.xz -C $bdir || true
	cp /etc/resolv.conf $bdir/etc
	echo "LLVM_TARGETS=\"X86\"" >> $bdir/etc/portage/make.conf
	for dir in "${cp_dirs[@]}"; do
		cp -r $proj_dir/$dir $bdir/etc/portage/$dir
	done
	for dir in "${cp_to_etc[@]}"; do
		cp -r $proj_dir/etc $bdir/etc
	done
	for f in $(arch-chroot $bdir find /etc/portage/package.use); do
		echo u | arch-chroot $bdir dispatch-conf $f
	done
	arch-chroot $bdir emerge-webrsync
	case "$desktop" in
		gnome | kde)
			arch-chroot "$bdir" eselect profile set "$(arch-chroot "$bdir" eselect profile list | grep "$desktop" | awk -F'[][]' 'NR==1 {print $2}')"
			USE+="$desktop "
			;;
		*)
			;;
	esac
	for cmd in "${gentoo_cmds[@]}"; do
		USE=$USE ACCEPT_LICENSE="*" ACCEPT_KEYWORDS="~*" FEATURES="getbinpkg binpkg-request-signature" arch-chroot $bdir $cmd || exit 1
	done
	echo "FEATURES='\${FEATURES} getbinpkg binpkg-request-signature'" >> $bdir/etc/portage/make.conf
	cp -r $proj_dir/etc/* $bdir/etc
	install -d $bdir/etc/runlevels/$name
	# Fix some issues with the desktop
	USE="minimal" ACCEPT_KEYWORDS="~*" FEATURES="getbinpkg binpkg-request-signature" arch-chroot $bdir emerge --oneshot libsndfile
	# Merge the desktop
	case "$desktop" in
		gnome)
			echo "DISPLAYMANAGER=gdm" | tee $bdir/etc/conf.d/display-manager
			USE="$USE -qt" ACCEPT_KEYWORDS="~*" FEATURES="getbinpkg binpkg-request-signature" arch-chroot $bdir emerge -v gnome-light gnome-software 
			;;
		kde)
			echo "DISPLAYMANAGER=sddm" | tee $bdir/etc/conf.d/display-manager
			USE="$USE sddm display-manager -gtk" ACCEPT_KEYWORDS="~*" FEATURES="getbinpkg binpkg-request-signature" arch-chroot $bdir emerge -v kde-plasma/plasma-desktop kde-plasma/powerdevil kde-plasma/systemsettings
			;;
		*)
			;;
	esac
	for overlay in "${overlays[@]}"; do
		arch-chroot $bdir eselect repository enable $overlay || continue
		arch-chroot $bdir emaint -r $overlay sync || continue
	done
	for pkg in "${pkgs[@]}"; do
		(USE=$USE ACCEPT_KEYWORDS="~*" FEATURES="getbinpkg binpkg-request-signature" arch-chroot $bdir emerge -v $pkg &) || continue 
	done
	wait
	for svc in "${svcs[@]}"; do
		arch-chroot $bdir rc-update add $svc $name
	done
	$proj_dir/recenv/tarball2img.sh $bdir $name
}
if [[ $(id -u) != 0 ]]; then
	providers=(sudo doas run0)
	for escalation in "${providers[@]}"; do
		if [[ -f $(command -v $escalation) ]]; then
			$escalation $(command -v bash) $0
			break
		else
			continue
		fi
	done
else
	main
fi
