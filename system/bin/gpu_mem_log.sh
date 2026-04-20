#!/system/bin/sh

sleep 10

ENABLED=`getprop debug.log.gpu_mem.enable`
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

LOGNAME=$BASEPATH/gpu_mem.$LOGTIMESTAMP.log

rm -f $BASEPATH/gpu_mem.*.log

echo "********************* START *********************" > $LOGNAME
chmod 0600 $LOGNAME
chown system.system $LOGNAME

while true; do
    date >> $LOGNAME
    echo "#cat /d/mali0/gpu_memory" >> $LOGNAME
    cat /d/mali0/gpu_memory >> $LOGNAME

    echo "#cat /d/ion/heaps/ion_mm_heap" >> $LOGNAME
    cat /d/ion/heaps/ion_mm_heap >> $LOGNAME
    sleep 10

done

