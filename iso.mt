let name = "MatuushOS";
let desc = "MatuushOS ISO in its flesh";
let version = [0, 1, 0];
let build = building_constructor();
build.copy_local("cfg-mtos", "/tmp");
for dep in ["vagrant", "git"] { // this can be subject to change,
    build.step("Check if " + dep + " is installed", "which", dep);                   
}
// rootfs je v `output/images`
// len aby si nezabudol
for mtools in ["pm", "mtinit-v2"] {
    build.download_extract(mtools, mtools, "git", "https://gitlab.com/MatuushOS/" + mtools, "");
    build.step("Build " + mtools, "cargo build --release");
    build.copy_local("target/x86_64-unknown-linux-musl/release/" + mtools, "/tmp");
    build.set_dir("/tmp");
}
build.download_extract("buildroot", "buildroot", "git", "https://gitlab.com/buildroot.org/buildroot.git", "");
build.copy_local("/tmp/cfg-mtos", "./.config");
building.set_var("VAGRANT_VAGRANTFILE", "support/misc/Vagrantfile");
build.step("Bring Vagrant up", "vagrant", "up");
build.step("Run the build", "vagrant", "ssh -c make");

build.unset_env("VAGRANT_VAGRANTFILE");
// yolo ig