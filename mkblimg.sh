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
    umount /tmp/bl_stage0.img || true
    mkdir -p /tmp/mtos $(pwd)/target
    install_limine
    mkdir -p $bdir
    bash $(pwd)/mtos-builder.sh
    img_size=$(( $(du -l $(pwd)/target/mtos.img | tail --lines 1 | awk '{print $1}') \
        + $(du -l /tmp/limine | tail --lines 1 | awk '{print $1}') \
        + $(( 1024 * 8 )) ))
    fallocate -l $img_size /tmp/bl_stage0.img
    printf "g\nn\n\n\n\nt\n1\nw\n" | fdisk /tmp/bl_stage0.img
    mkfs.fat -F32 /tmp/bl_stage0.img
    mount /tmp/bl_stage0.img /tmp/mtos
    mkdir -p $bdir/EFI/BOOT
    cp /tmp/limine/BOOTX64.efi /tmp/mtos/EFI/BOOT
    cp /boot/vmlinuz-$(uname -r) /tmp/mtos/kernel
    echo -e "/MatuushOS\n$tabs protocol: linux\n$tabs kernel_path: boot():/kernel\n$tabs module_path: boot():/initramfs\n$tabs cmdline: quiet rhgb root=mtos.img ro\n$tabs comment: Boot a better operating system\n//Other operating systems\n/Windows\n$tabs protocol: efi\n$tabs path: boot():/EFI/Microsoft/bootmgfw.efi" >> /tmp/mtos/limine.conf
    mkinitramfs /tmp/mtos
    umount -R /tmp/mtos
    cp /tmp/bl_stage0.img $(pwd)/target
}
mkinitramfs() {
    mkdir -p /tmp/initramfs/bin
    arch-chroot $bdir apk add busybox-static
    cp $(find $bdir -name busybox.static) /tmp/initramfs/bin/busybox
    /tmp/initramfs/bin/busybox --install /tmp/initramfs/bin
    echo -e "#!/bin/busybox sh\nset -Eeux -o pipefail\nmount -t proc none /proc\nmount -t sysfs none /sys\nmount -t devtmpfs none /dev\nmount mtos.img /\nswitch_root / /sbin/init" >> /tmp/initramfs/init
    chmod +x /tmp/initramfs/init
   	find . -print0 | cpio --null --create --verbose --format=newc | gzip --best >/tmp/minitramfs
    cp /tmp/minitramfs $1/initramfs
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
