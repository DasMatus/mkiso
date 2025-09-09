#!/usr/bin/env bash
# shellcheck disable=SC2046,SC2086
set -Eeux -o pipefail
source recovery_settings
source settings
limine_url=https://codeberg.org/Limine/Limine
limine_version=v9.x-binary
tabs="\t\t"
install_limine() {
    if [[ -d /tmp/limine ]]; then 
        rm -rf /tmp/limine 
    fi
    $(command -v git) clone $limine_url --branch $limine_version /tmp/limine
}
main() {
    install_limine
    mkdir -p $bdir
    bash $(pwd)/mtos-builder.sh
    img_size=$(( $(du -l recenv/target/system.img | tail --lines 1 | awk '{print $1}') \
        + $(du -l /tmp/limine | tail --lines 1 | awk '{print $1}') + $(( 1024 * 8 )) ))
    fallocate -l $img_size /tmp/bl_stage0.img
    printf "g\nn\n\n\n\nt\n1\nw\n" | fdisk /tmp/bl_stage0.img
    mkfs.fat -F32 /tmp/bl_stage0.img
    mount /tmp/bl_stage0.img $bdir
    mkdir -p $bdir/EFI/BOOT
    cp /tmp/limine/BOOT*.efi $bdir/EFI/BOOT
    cp /boot/vmlinuz-$(uname -r) $bdir/kernel
    echo "/MatuushOS\n$tabs protocol: linux\n$tabs kernel_path: boot():/kernel\n$tabs module_path: boot():/initramfs\n$tabs comment: Boot a better operating system\n//Other operating systems\n/Windows\n$tabs protocol: efi\n$tabs path: boot():/EFI/Microsoft/bootmgfw.efi" >> $bdir/limine.conf 
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