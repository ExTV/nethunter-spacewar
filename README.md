# Kali NetHunter Magisk Module - Nothing Phone 1 (Spacewar)

Kali NetHunter Magisk module customized for the Nothing Phone 1 (codename: Spacewar).
Locks installation to Spacewar/SpacewarEEA devices only to prevent accidental flashing on other phones.

---

## What This Module Does

Installs the full Kali NetHunter environment as a Magisk module:

- Installs NetHunter, NetHunterTerminal, NetHunterKeX, NetHunterStore APKs
- Installs NetHunter BusyBox to /system/xbin
- Extracts the Kali ARM64 chroot rootfs to /data/local/nhsystem/
- Sets up USB HID gadget (keyboard + mouse) via configfs on boot
- Symlinks vendor kernel modules from /vendor/lib/modules to /system/lib/modules
- Mounts cgroup2 into the NetHunter chroot for Docker/DroidSpaces compatibility
- Copies WiFi adapter firmwares, terminfo, nano highlights, HID keyboard binary
- Sets NetHunter wallpaper at correct screen resolution (1080x2400)

---

## Changes Made to the Original NetHunter Module

### Device lock
Added device and architecture check at the start of installation. Aborts immediately
if the device is not Spacewar/SpacewarEEA or if the CPU ABI is not arm64-v8a.

### Kernel flash removed
The original module flashed a kernel zip using magic-flash.sh and AnyKernel3.
This was removed entirely. The kernel must be flashed separately via fastboot
before installing this module. See the kernel repository for instructions.

### Nothing Phone 1 vendor module symlinks
The Nothing Phone 1 stores kernel modules in /vendor/lib/modules instead of
/system/lib/modules. Added logic to create symlinks so the NetHunter app can
find them. This runs both at install time and at every boot via post-fs-data.sh.

### USB HID via configfs
The Nothing Phone 1 uses the configfs USB gadget framework, not the legacy
android_usb interface. service.sh was written specifically for this device to
create HID keyboard and mouse functions through configfs, then restore ADB.

### DroidSpaces and Docker cgroup2 support
service.sh bind-mounts /sys/fs/cgroup into the NetHunter chroot at boot so
Docker and DroidSpaces can see the cgroup2 hierarchy. Without this, Docker
check-config fails and container runtimes cannot start.

### Bug fixes from the original NetHunter installer
- Replaced bash-only [[ ]] syntax with POSIX [ ] for Android sh compatibility
- Fixed typo: $MODPTH was never set, causing MODPATH to always be overridden
- Fixed addon.d script being copied to the wrong path (/system/ instead of /system/addon.d/)
- Fixed post-fs-data.sh extraction check that was checking the wrong filename
- Fixed OUTFD variable assignment having a stray leading space
- Fixed $BB being unset before install-chroot.sh runs, now explicitly set to
  the installed busybox_nh so tar -xJf (xz decompression) works reliably
- Removed incorrect first cp of addon.d script to system root

---

## What Is Missing From This Repository

The following files are excluded because they exceed GitHub's file size limit
or are too large to distribute via git. They must be added manually before
building the ZIP.

### 1. NetHunter APKs

Place these files in: nh_build/data/app/

    NetHunter.apk
    NetHunterTerminal.apk
    NetHunterKeX.apk
    NetHunterStore.apk
    NetHunterStorePrivilegedExtension.apk

Download from: https://store.nethunter.com

The exact package names to look for:
    com.offsec.nethunter
    com.offsec.nhterm
    com.offsec.nethunter.kex
    com.offsec.nethunter.store
    com.offsec.nethunter.store.privileged

### 2. Kali ARM64 Rootfs

Place this file in: nh_build/

    kalifs-minimal-arm64.tar.xz

Download from the official Kali NetHunter build server. Choose the minimal ARM64
variant. The filename must match the pattern kalifs-minimal-arm64.tar.xz exactly
or the installer will not find it.

---

## Building the ZIP

Once all missing files are in place:

    cd nh_build
    zip -r ../nethunter-spacewar.zip .

The resulting nethunter-spacewar.zip can be installed via Magisk -> Modules ->
Install from storage.

---

## Requirements

- Nothing Phone 1 (Spacewar or SpacewarEEA)
- Magisk v20.4 or newer
- Custom kernel with DroidSpaces/Docker support flashed via fastboot before installing
- At least 4GB free space in /data for the Kali chroot

---

## Kernel

This module is designed to be paired with the DroidSpaces kernel for Nothing Phone 1.
The kernel must be flashed via fastboot boot or fastboot flash boot before installing
this module. The kernel repository contains the build system and full patch list.
