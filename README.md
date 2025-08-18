# An operating system that doesn't sacrifice on anything.
[![pipeline status](https://gitlab.com/matuushos/mkiso/badges/v2a/pipeline.svg)](https://gitlab.com/matuushos/mkiso/-/commits/v2a) [![Latest Release](https://gitlab.com/matuushos/mkiso/-/badges/release.svg)](https://gitlab.com/matuushos/mkiso/-/releases)

It aims to have as little of C/C++ code as it's physically possible while using the power of Rust to write new and innovative tools for the Linux desktop. Its main features include: 
- Automatic updates using [`recenv`](https://gitlab.com/MatuushOS/recenv), whose frequency you can control
- Animated bootup logo
- Declarative build configuration
- Better Windows support using [WinApps](https://github.com/winapps-org/winapps)
- Steam pre-installed on gaming edition
- Rust-based user interface
And more coming down the road. 

The OS updates itself while you're doing something more interesting.

# Installation
TBD (the [MatuushOS initial installer](https://gitlab.com/MatuushOS/mii) is not finished yet)

# Building
Run `bash mtos-builder.sh`.

# What we need to do now?
- [] Make it build

# What should we do in the future?
- [] Make more image versions
  - [] Gaming edition (will be *only* in the daily and weekly images, because we need up-to-date drivers)
  - [] Paranoia edition (Every channel)
    - SELinux enabled out-of-the-box
    - Secure Boot will be mandated 
  - [-] Developer edition (default as of the time of writing this) (every channel)
    - Full Rust suite, including Clippy, Cargo and much much more
- [] Make MUSL and LLVM images the default
