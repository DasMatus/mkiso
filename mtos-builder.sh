#!/bin/bash
# shellcheck disable=SC2086,SC2046
set -eux -o pipefail
# shellcheck source=settings
source settings
proj_dir=$(pwd)
wget=$(command -v wget || command -v wget2)
USE=""
gentoo_cmds=("emerge-webrsync"
	"emerge --oneshot sys-apps/portage"
	"emerge -u eselect linux-firmware grub display-manager-init"
)
main() {
	rm -rf /tmp/tmp.* /tmp/gentoo-snapshot.tar.xz
	mkdir -p $bdir
	for flag in "${flags[@]}"; do
		if [[ -n "$(curl https://www.gentoo.org/support/use-flags/ | grep -i "use-flag" | grep $flag | sort | uniq)" ]]; then
			USE+="$flag "
			continue
		else
			exit 1
		fi
	done
	USE+="$desktop "
	$wget $mirror/$version -O /tmp/gentoo-snapshot.tar.xz || echo "Snapshot exists, continuing"
	tar -xpvf /tmp/gentoo-snapshot.tar.xz -C $bdir || true
	cp /etc/resolv.conf $bdir/etc
	for cmd in "${gentoo_cmds[@]}"; do
		USE=$USE arch-chroot $bdir $cmd
	done
	install -d $bdir/etc/runlevels/$name
	# Fix some issues with the desktop
	USE="minimal" arch-chroot $bdir emerge --oneshot libsndfile
	# Merge the desktop
	case "$desktop" in
		gnome)
			echo "DISPLAYMANAGER=gdm" | tee $bdir/etc/conf.d/display-manager
			USE="$USE -X" arch-chroot $bdir emerge -v gnome-light gnome-software
			;;
		kde)
			echo "DISPLAYMANAGER=sddm" | tee $bdir/etc/conf.d/display-manager
			USE="$USE -X sddm display-manager " arch-chroot $bdir emerge -v
			;;
	esac
	for overlay in "${overlays[@]}"; do
		arch-chroot $bdir eselect repository enable $overlay || continue
		arch-chroot $bdir emaint -r $overlay sync || continue
	done
	for pkg in "${pkgs[@]}"; do
		USE=$USE arch-chroot $bdir emerge -v $pkg || continue
	done
	for svc in "${svcs[@]}"; do
		arch-chroot $bdir rc-update add $svc
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
