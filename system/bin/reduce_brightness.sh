#!/system/bin/sh

# The intention of this script to reduce screen brightness if device time is in quiet hours.
# This script gets called before the surface flinger initialzation is completed.

DND_ENABLED=1
donotdisturb=`getprop persist.sys.ecs.SCREEN_IDLE`
LOG=/system/bin/log
TAG=ScreenBrightnessController

print() {
     $LOG -t $TAG $1
}

if [ "${donotdisturb}" == "${DND_ENABLED}" ] ; then
    echo 30 > sys/devices/platform/leds-mt65xx/leds/lcd-backlight/brightness
    print "Device was in night mode, boot with reduced brightness."
else
    print "Device was not in night mode, boot with default brightness."
fi