#!/usr/bin/env bash
# shellcheck disable=SC2046,SC2086
set -Eeux -o pipefail
source recovery_settings
source settings
img_size=2.2G
limine_url=https://codeberg.org/Limine/Limine
limine_version=v9.x-binary
install_limine() {
    [[ -d /tmp/limine ]]; rm -rf /tmp/limine 
    $(command -v git) clone $limine_url --branch $limine_version /tmp/limine
    cp /tmp/limine/BOOT*.efi $1
}
main() {
    mkdir -p $bdir
    bash $(pwd)/mtos-builder.sh
    fallocate -l $img_size /tmp/bl_stage0.img
    printf "g\nn\n\n\n\nt\n1\nw\n" | fdisk /tmp/bl_stage0.img
    mkfs.fat -F32 /tmp/bl_stage0.img
    mount /tmp/bl_stage0.img $bdir
    mkdir -p $bdir/EFI/BOOT
    install_limine $bdir/EFI/BOOT

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