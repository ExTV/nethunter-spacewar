#!/system/bin/sh
## [Magisk] [nethunter] service.sh - runs late in boot
## Nothing Phone 1: Set up USB HID gadget via configfs
##
## This phone uses configfs USB gadget (not legacy android_usb).
## We create hid functions, link them into the config, then let
## Android's init re-trigger USB setup to restore ADB.

GADGET=/config/usb_gadget/g1
CONFIG=$GADGET/configs/b.1

## Wait for USB gadget to be fully ready
i=0
while [ ! -e "$GADGET/UDC" ] && [ $i -lt 30 ]; do
  sleep 1
  i=$((i + 1))
done
sleep 5  ## Wait for init to finish USB setup

## Check if already set up
if [ -e /dev/hidg0 ]; then
  chmod 0666 /dev/hidg* 2>/dev/null
  exit 0
fi

## Keyboard HID report descriptor (boot protocol keyboard)
KEYBOARD_DESC='\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02\x95\x01\x75\x08\x81\x03\x95\x05\x75\x01\x05\x08\x19\x01\x29\x05\x91\x02\x95\x01\x75\x03\x91\x03\x95\x06\x75\x08\x15\x00\x25\x65\x05\x07\x19\x00\x29\x65\x81\x00\xc0'

## Mouse HID report descriptor (boot protocol mouse)
MOUSE_DESC='\x05\x01\x09\x02\xa1\x01\x09\x01\xa1\x00\x05\x09\x19\x01\x29\x05\x15\x00\x25\x01\x95\x05\x75\x01\x81\x02\x95\x01\x75\x03\x81\x01\x05\x01\x09\x30\x09\x31\x09\x38\x15\x81\x25\x7f\x75\x08\x95\x03\x81\x06\xc0\xc0'

## Create and configure HID functions
mkdir $GADGET/functions/hid.0 2>/dev/null
echo 1 > $GADGET/functions/hid.0/protocol
echo 1 > $GADGET/functions/hid.0/subclass
echo 8 > $GADGET/functions/hid.0/report_length
printf "$KEYBOARD_DESC" > $GADGET/functions/hid.0/report_desc

mkdir $GADGET/functions/hid.1 2>/dev/null
echo 2 > $GADGET/functions/hid.1/protocol
echo 1 > $GADGET/functions/hid.1/subclass
echo 4 > $GADGET/functions/hid.1/report_length
printf "$MOUSE_DESC" > $GADGET/functions/hid.1/report_desc

## Disable gadget, add HID links, then let init restore it
echo "" > $GADGET/UDC
sleep 1

ln -s $GADGET/functions/hid.0 $CONFIG/hid.0 2>/dev/null
ln -s $GADGET/functions/hid.1 $CONFIG/hid.1 2>/dev/null

## Trigger Android init to re-setup USB with ADB
## This re-creates f1 (ffs.adb) and writes UDC, restoring ADB
setprop sys.usb.config none
sleep 1
setprop sys.usb.config adb

## Wait for hidg devices and fix permissions
sleep 5
chmod 0666 /dev/hidg* 2>/dev/null

## Create /dev/hidg0 symlink if missing (NetHunter app expects hidg0)
## Device numbering may start at 1 if other functions were linked first
if [ ! -e /dev/hidg0 ] && [ -e /dev/hidg1 ]; then
  ln -s /dev/hidg1 /dev/hidg0
  chmod 0666 /dev/hidg0
fi

## Mount cgroup2 into NetHunter chroot so Docker check-config works
## The chroot's sysfs mount doesn't propagate the cgroup2 mount
for CHROOT in /data/local/nhsystem/kali-arm64 /data/local/nhsystem/kalifs; do
  if [ -d "$CHROOT/sys" ] && [ ! -e "$CHROOT/sys/fs/cgroup/cgroup.controllers" ]; then
    mkdir -p "$CHROOT/sys/fs/cgroup"
    mount -o bind /sys/fs/cgroup "$CHROOT/sys/fs/cgroup" 2>/dev/null
  fi
done
