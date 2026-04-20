#!/system/bin/sh

# collect dmesg logs for boot.
sleep 30

ENABLED=`getprop debug.log.dmesg.enable`
if [ "$ENABLED" != "y" ]; then
    exit;
fi;

LOGTIMESTAMP=`getprop debug.log.timestamp`
if [ "$LOGTIMESTAMP" == "" ]; then
    LOGTIMESTAMP=$(date +%s)
    setprop debug.log.timestamp $LOGTIMESTAMP
fi;

export BASEPATH=`getprop debug.log.base.path`

data_is_blk=$(mount | grep /data | grep block)
if [ "x$data_is_blk" == "x" ]; then
    BASEPATH="/cache/crypt/$BASEPATH"
fi

LOGNAME=$BASEPATH/dmesg.$LOGTIMESTAMP.log
LASTKMSG=$BASEPATH/last_kmsg.$LOGTIMESTAMP.log

mkdir -p $BASEPATH/archive
rm -f $BASEPATH/archive/*
mv $BASEPATH/*.log $BASEPATH/archive

echo "********************* START *********************" > $LOGNAME
chmod 0600 $LOGNAME
chmod 0600 $LASTKMSG
chown system.system $LOGNAME
chown system.system $LASTKMSG

cat /proc/last_kmsg >> $LASTKMSG
cat /proc/kmsg >> $LOGNAME

# Detection for RO remount of /userdata
if [ $? -ne 0 ]; then
    BASEPATH=/cache/$BASEPATH
    LOGNAME=$BASEPATH/dmesg.$LOGTIMESTAMP.log

    mkdir -p $BASEPATH
    cat /proc/kmsg >> $LOGNAME
fi;
