#!/bin/bash
# shellcheck disable=SC2086,SC2046
set -eux -o pipefail
# shellcheck source=settings
source settings
proj_dir=$(pwd)
wget=$(command -v wget || command -v wget2)
USE="X -previewer -webengine "
cp_to_etc=(skel os-release)
alpine_cmds=(
	"apk update"
	"apk add linux-firmware"	
)
main() {
	rm -rf /tmp/tmp.* $bdir /tmp/alpine-snapshot.tar.xz
	mkdir -p $bdir
	$wget $mirror -O /tmp/alpine-snapshot.tar.xz || echo "Snapshot exists, continuing"
	tar -xpvf /tmp/alpine-snapshot.tar.xz -C $bdir || true
	cp /etc/resolv.conf $bdir/etc
	for dir in "${cp_to_etc[@]}"; do
		cp -r $proj_dir/etc $bdir/etc
	done
	case "$desktop" in
		kde)
			echo plasma | arch-chroot $bdir setup-desktop
			;;
		gnome | *)
			echo $desktop | arch-chroot $bdir setup-desktop
			;;
	esac
	cp -r $proj_dir/etc/* $bdir/etc
	install -d $bdir/etc/runlevels/$name
	for pkg in "${pkgs[@]}"; do
		USE=$USE ACCEPT_LICENSE="*" ACCEPT_KEYWORDS="~*" FEATURES="getbinpkg binpkg-request-signature" arch-chroot $bdir emerge -v $pkg 
	done
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
