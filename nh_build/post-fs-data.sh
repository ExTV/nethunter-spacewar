## [Magisk] [nethunter] [This is standalone script, not sourced]
##
## REF: ./nethunter/META-INF/com/google/android/update-recovery:get_bb() & $MAGISKBB
##      ./nethunter/post-fs-data.sh
##      ./nethunter/tools/install-chroot.sh

MODDIR="${0%/*}"
TARGET=$MODDIR/system
BIN=$TARGET/bin

if [ -d /system/xbin ]; then
  XBIN=$TARGET/xbin
else
  XBIN=$TARGET/bin
fi

rm -f $XBIN/busybox_nh
cd $XBIN/
busybox_nh=$( (ls -v busybox_nh-* || ls busybox_nh-*) | tail -n 1 ) # Alt: BB_latest=$( (ls -v busybox_nh-* 2>/dev/null || ls busybox_nh-*) | tail -n 1)
[ -z "$busybox_nh" ] && print "! Failed to find busybox_nh in $XBIN" && return 1
#BB=$XBIN/$busybox_nh # Use NetHunter BusyBox from ./arch/<arch>/tools/ # Alt: export BB=$TMP/$busybox_nh
ln -sf $XBIN/$busybox_nh busybox_nh # Alt: $XBIN/$busybox_nh ln -sf $busybox_nh busybox_nh

## Create symlink for applets
sysbin="$(ls /system/bin)"
existbin="$(ls $BIN 2>/dev/null || true)"
for applet in $($XBIN/busybox_nh --list); do
  case $XBIN in
    */bin)
      if [ "$(echo "$sysbin" | $XBIN/busybox_nh grep "^$applet$")" ]; then
        if [ "$(echo "$existbin" | $XBIN/busybox_nh grep "^$applet$")" ]; then
          $XBIN/busybox_nh ln -sf busybox_nh $applet
        fi
      else
        $XBIN/busybox_nh ln -sf busybox_nh $applet
      fi
      ;;
    *) $XBIN/busybox_nh ln -sf busybox_nh $applet
      ;;
    esac
done

[ -e $XBIN/busybox ] || {
  ln -s $XBIN/busybox_nh $XBIN/busybox # Alt: $XBIN/$busybox_nh ln -sf busybox_nh busybox
}

chmod 755 *
chcon u:object_r:system_file:s0 *

## Nothing Phone 1: Fix /dev/hidg* permissions for NetHunter HID attacks
## The kernel creates hidg devices but with root-only access
chmod 0666 /dev/hidg* 2>/dev/null

## Nothing Phone 1: Ensure vendor modules are symlinked to /system/lib/modules
## NetHunter app expects modules at /system/lib/modules but Nothing Phone
## stores them at /vendor/lib/modules
MODLIB=$MODDIR/system/lib/modules
if [ -d /vendor/lib/modules ] && [ "$(ls /vendor/lib/modules/*.ko 2>/dev/null)" ]; then
  if [ ! -d "$MODLIB" ] || [ "$(ls $MODLIB/*.ko 2>/dev/null | wc -l)" -eq 0 ]; then
    mkdir -p "$MODLIB"
    for mod in /vendor/lib/modules/*.ko; do
      [ -f "$mod" ] && ln -sf "$mod" "$MODLIB/"
    done
    for dir in /vendor/lib/modules/*/; do
      [ -d "$dir" ] && ln -sf "$dir" "$MODLIB/"
    done
  fi
fi
