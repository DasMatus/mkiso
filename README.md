# An operating system that doesn't sacrifice on anything.
It aims to have as little of C/C++ code as it's physically possible while using the power of Rust to write new and innovative tools for the Linux desktop. Its main features include: 
- Automatic updates using [`recenv`](https://gitlab.com/MatuushOS/recenv), whose frequency you can control
- Rust-based user interface
- Animated bootup logo
- Declarative build configuration
And more coming down the road. 

The OS updates itself while you're doing something more interesting.

# Installation
TBD (the [MatuushOS initial installer](https://gitlab.com/MatuushOS/))

# What needs to be done in the future?
- [] Make more image versions
  - [] Gaming edition (will be *only* in the daily and weekly images, because we need up-to-date drivers)
  - [] Paranoia edition (Every channel)
    - SELinux enabled out-of-the-box
    - Secure Boot will be mandated 