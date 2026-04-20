#!/system/bin/sh

PATH=/sbin:/system/sbin:/system/bin:/system/xbin

ENABLE=`getprop debug.mdump`
if [ "$ENABLE" != "1" ]; then
    exit;
fi;

if [ ! -e /sys/kernel/mdump/compmsg ]; then
    exit;
fi;

ret=`/system/bin/vdc --wait cryptfs checkpw 70617373776f7264`
arr=(${ret// / }) 
echo ${arr[2]}
if [ "${arr[2]}" -ne 0 ];then
   echo "rebooting"
   reboot
fi
