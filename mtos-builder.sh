#!/bin/bash
# shellcheck disable=SC2086,SC2046
set -eux -o pipefail
# shellcheck source=settings
source settings
wget=$(command -v wget || command -v wget2)
USE=""
gentoo_cmds=("emerge-webrsync" 
			 "emerge -uDN @world"
			 "emerge -u eselect linux-firmware grub"
			 )
main() {
	rm -rf /tmp/tmp.* /tmp/gentoo-snapshot.tar.xz
	mkdir -p $bdir
	for flag in "${flags[@]}"; do
		if [[ -n "$(curl https://www.gentoo.org/support/use-flags/ | grep -i "use-flag" | grep $flag | sort | uniq)" ]]; then
			USE+=$flag
			continue
		else
			exit 1
		fi
	done
	USE+=$desktop
	$wget $mirror/$version -O /tmp/gentoo-snapshot.tar.xz
	tar -xpvf /tmp/gentoo-snapshot.tar.xz -C $bdir || true
	cp /etc/resolv.conf $bdir/etc
	for cmd in "${gentoo_cmds[@]}"; do
		$USE arch-chroot $bdir $cmd
	done
	for overlay in "${overlays[@]}"; do
		arch-chroot $bdir eselect repository enable $overlay
		arch-chroot $bdir emaint -r $overlay sync
	done
	for pkg in "${pkgs[@]}"; do
		$USE arch-chroot $bdir emerge 
	done
	
}
if [[ $(id -u) != 0 ]]; then
    providers=(sudo doas run0)
    for escalation in "${providers[@]}"; do
        if [[ -f $(command -v $escalation) ]]; then
            $escalation $(command -v bash) $0
            break;
        else
            continue
        fi
    done
else
	main
fi