#!/bin/bash
# shellcheck disable=SC2086,SC2046
 set -eux -o pipefail
# shellcheck source=settings
source settings
pre_setup() {
    mkdir -p $proj_dir/cfg
    echo -n "
        set(CMAKE_SYSTEM_NAME Linux)
        set(CMAKE_SYSROOT \"$1\")
        set(CMAKE_C_COMPILER_TARGET $TARGET)
        set(CMAKE_CXX_COMPILER_TARGET $TARGET)
        set(CMAKE_C_FLAGS_INIT \"$CFLAGS\")
        set(CMAKE_CXX_FLAGS_INIT \"$CFLAGS\")
        set(CMAKE_LINKER_TYPE LLD)
        set(CMAKE_C_COMPILER clang)
        set(CMAKE_CXX_COMPILER clang++)
        set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
        set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
        set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
        set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)" >> $proj_dir/cfg/$TARGET.cmake
}
llvm_stage1() {
    pre_setup $1
    mkdir -p $llvm_build_dir
    $wget https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-20.1.8.tar.gz -O /tmp/llvm.tar.gz
    bsdtar -xvf /tmp/llvm.tar.gz -C $llvm_build_dir
    cd $llvm_build_dir/llvm* || exit
    cmake -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_PROJECTS="lld;clang;libc" \
      -DLLVM_ENABLE_RUNTIMES="compiler-rt"\
      -DCMAKE_TOOLCHAIN_FILE=$proj_dir/cfg/$TARGET.cmake \
      -DLLVM_HOST_TRIPLE=$TARGET \
      -DCMAKE_INSTALL_PREFIX=$proj_dir/bin \
      -S llvm \
      -B build/$TARGET
    cmake --build build/$TARGET --target=install
}
musl_stage1() {
    mkdir -p /tmp/$musl_bdir
    $wget http://musl.libc.org/releases/musl-1.2.5.tar.gz -O /tmp/musl.tar.gz
    bsdtar -xvf /tmp/musl.tar.gz -C /tmp/$musl_bdir
    cd /tmp/$musl_bdir
    CC="clang -static" $(find . -name configure) --prefix=$1
    make TARGET=$(arch)-mtos-linux-musl-llvm install
}
main() {
    git submodule init recenv
    git submodule sync
    git submodule 
	$rustup target add $target
	mkdir -p $out_dir
	for dir in "${mtos_dirs[@]}"; do
		mkdir -p "$out_dir/$dir"
	done
	for dir in $(seq 0 "${#dirs[@]}"); do
		ln -sf $out_dir/${mtos_dirs[dir]} $out_dir/${dirs[dir]} || break
	done
	musl_stage1 $out_dir
	llvm_stage1 $out_dir
	$wget https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/x86_64/alpine-minirootfs-3.22.0_rc1-x86_64.tar.gz -O alpine-rootfs.tar.gz
	tar -xvf alpine-rootfs.tar.gz -C $workdir
	cp --dereference /etc/resolv.conf $workdir/etc
	for cmd in "${alpine_cmds[@]}"; do
		arch-chroot $workdir $cmd
	done
	cp $workdir/bin/busybox.static $out_dir/sbin/busybox
	$out_dir/bin/busybox --install $out_dir/bin
    ./recenv/tarball2img.sh $out_dir
}
rm -rf /tmp/{musl,llvm}_bd $proj_dir/cfg/$TARGET.cmake /tmp/tmp.*
main
# if [[ $(id -u) != 0 ]]; then
# 	providers=(sudo doas run0)
# 	for escalation in "${providers[@]}"; do
# 		if [[ -f $(command -v $escalation) ]]; then
# 			$escalation $(command -v bash) $0
# 			break
# 		else
# 			continue
# 		fi
# 	done
# else
# 	if [[ -z $(command -v rustup) ]]; then
# 		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# 	fi
# 	main
# fi