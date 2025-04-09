let cfg = config_constructor();
cfg.sysrepos("Main one", "https://gitlab.com/MatuushOS/pm.git");
cfg.sysdeps("user:operatingsystem/pm");
cfg.use_git(true);
cfg.run();