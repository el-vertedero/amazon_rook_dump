#!/system/bin/sh
PATH=/sbin:/system/sbin:/system/bin:/system/xbin

build_tags=$(getprop ro.build.tags)
ret=none

if [[ $build_tags == *release-keys* ]]; then
    log -t FOSFLAGS "User build"
    ret=closed
fi

if [ $ret == closed ]; then
    log -t FOSFLAGS "Unset adb from persist.sys.usb.config property"
fi

echo $ret
