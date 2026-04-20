#!/system/bin/sh
BASEPATH=`getprop debug.log.base.path`

LAST_COREDUMP_PATH=$BASEPATH/coredump_last
COREDUMP_PATH=$BASEPATH/coredump_current

mkdir -p $LAST_COREDUMP_PATH
chown system.system $LAST_COREDUMP_PATH
chmod 0700 $LAST_COREDUMP_PATH

if [ "$(ls -a $COREDUMP_PATH)" ]; then
     rm -rf $LAST_COREDUMP_PATH/*
     mv $COREDUMP_PATH/* $LAST_COREDUMP_PATH/
else
     mkdir -p $COREDUMP_PATH
     chown system.system $COREDUMP_PATH
     chmod 0777 $COREDUMP_PATH
fi

FILE_last="$LAST_COREDUMP_PATH/*"

for f_last in $FILE_last
do
        gz_f_last=`echo $f_last | grep '\.gz$'`
                if [ "$gz_f_last" = "" ]; then
                        echo "gzip $f_last"
                        gzip "$f_last"
                else
                        echo "Ignore $f_last"
                fi
done

while ((1));do
        FILE="$COREDUMP_PATH/*"

        for f in $FILE
        do
                gz_f=`echo $f | grep '\.gz$'`
                if [ "$gz_f" = "" ]; then
                        echo "gzip $f"
                        gzip "$f"
                else
                        echo "Ignore $f"
                fi
        done
        sleep 60
done

