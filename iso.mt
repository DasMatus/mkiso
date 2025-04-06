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
build.step("Install vagrant-scp plugin", "vagrant", "plugin install vagrant-scp");
build.download_extract("buildroot", "buildroot", "git", "https://gitlab.com/buildroot.org/buildroot.git", "");
build.copy_local("/tmp/cfg-mtos", "./.config");
building.set_var("VAGRANT_VAGRANTFILE", "support/misc/Vagrantfile");
build.step("Bring Vagrant up", "vagrant", "up");
/*
toto bude vyzerat hrozne:
build.step(...);
\
 vagrant ssh -c "...";
*/
build.step("Run the build", "vagrant", "ssh -c 'make'");
build.unset_env("VAGRANT_VAGRANTFILE");
// yolo ig