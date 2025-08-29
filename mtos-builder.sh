#!/bin/bash
# shellcheck disable=SC2086,SC2046
set -Eeux -o pipefail
# shellcheck source=settings
source settings
proj_dir=$(pwd)
wget=$(command -v wget || command -v wget2)
cp_to_etc=(skel os-release)
apk="/sbin/apk"
alpine_cmds=(
	"$apk update"
	"$apk add linux-firmware alpine-conf grub"	
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
	echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> $bdir/etc/apk/repositories
	for cmd in "${alpine_cmds[@]}"; do
		arch-chroot $bdir $cmd
	done
	case "$desktop" in
		kde)
			arch-chroot $bdir setup-desktop plasma
			;;
		*)
			arch-chroot $bdir setup-desktop $desktop
			;;
	esac
	cp -r $proj_dir/etc/* $bdir/etc
	install -d $bdir/etc/runlevels/$name
	for pkg in "${pkgs[@]}"; do
		arch-chroot $bdir apk add $pkg || true
	done
	for svc in "${svcs[@]}"; do
		arch-chroot $bdir rc-update add $svc $name
	done
	for pkg in "${rm_pkg[@]}"; do
		arch-chroot $bdir $apk del $pkg
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
