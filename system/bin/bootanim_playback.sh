#!/system/bin/sh

# The intention of this script to play audio during bootanimation.
# This script gets called when the audio flinger initialzation is completed.
# Makes sure that the bootanimation is running and play the audio using stagefright
# Plays a oobe.mp3 audio only if the boot is a OOBE boot and reboot.mp3 auido for all subsequent reboots.

REBOOT_FILE_PATH=/system/media/kni_system_state_boot_up_regular.wav
OOBE_FILE_PATH=/system/media/kni_system_setup_boot_up_oobe_intro.wav
RUNNING="running"
OOBE_RUN=1
DND_ENABLED=1
LOG=/system/bin/log
TAG=BootanimPlayback
bootanimstate=`getprop init.svc.bootanim`
oobestate=`getprop persist.boot.oobe`
knightfingerprint=`getprop ro.build.fingerprint`
donotdisturb=`getprop persist.sys.ecs.SCREEN_IDLE`

print() {
     $LOG -t $TAG $1
}
if [ "${bootanimstate}" == "${RUNNING}" ] && [ "${donotdisturb}" -ne "${DND_ENABLED}" ] ; then

        if [ "${oobestate}" -ne "${OOBE_RUN}" ]; then
                print "Play bootanim oobe audio"
                setprop persist.boot.oobe 1
                setprop persist.knight.fingerprint ""
                bootsound -ao $OOBE_FILE_PATH
        else
                print "Play bootanim reboot audio"
                bootsound -ao $REBOOT_FILE_PATH
        fi
else
        print "bootanim not running/ DND mode is enabled. Do not play the audio"
        setprop persist.knight.fingerprint $knightfingerprint
fi
