#!/system/bin/sh

HALO_PATH=/vendor/bin
VETC_PATH=/vendor/etc/halo_config
DETC_PATH=/mnt/halo/etc

[ -f ${HALO_PATH}/halo_common_lib.sh ] && . ${HALO_PATH}/halo_common_lib.sh

LOG_TAG="sidewalk-services"

# update boot reason
if [ "$#" -eq "0" ]; then
    if [ -e ${HALO_BOOT_RSN} ]; then
        # reboot_reason file is already exist, this is a reboot
        echo "normal_reboot" > ${HALO_BOOT_RSN}
    else
        # create reboot_reason file and put initial boot reason
        touch ${HALO_BOOT_RSN}
        echo "initial_boot" > ${HALO_BOOT_RSN}
    fi
fi

ORI_FILE=$DETC_PATH/halo_logr.conf.d/82_uploader.conf
SAVE_FILE=$DETC_PATH/halo_logr.conf.d/82_uploader_saved.conf

update_metrics_config() {
    device_id="$(getprop ro.serialno)"
    device_kind="$(getprop ro.product.config.type)"
    sdk_version="$(getprop vendor.halo.version)"
    firmware_version="$(getprop ro.build.version.number)"

    SAVED_IFS=$IFS

    while read -r line; do
        IFS==
        tokens=($line)

        if [ ${tokens[0]} == "sdk_version " ]; then
            echo "sdk_version = \"${sdk_version}\"" >> "$SAVE_FILE"
        elif [ ${tokens[0]} == "firmware_version " ]; then
            echo "firmware_version = \"${firmware_version}\"" >> "$SAVE_FILE"
        elif [ ${tokens[0]} == "device_id " ]; then
            echo "device_id = \"${device_id}\"" >> "$SAVE_FILE"
        elif [ ${tokens[0]} == "}" ]; then
            echo "device_kind = \"${device_kind}\"" >> "$SAVE_FILE"
            echo "firmware_version = \"${firmware_version}\"" >> "$SAVE_FILE"
            echo $line >> "$SAVE_FILE"
        else
            IFS=$SAVED_IFS
            echo $line >> "$SAVE_FILE"
        fi
    done < "$ORI_FILE"

    cp -f $SAVE_FILE $ORI_FILE
    rm $SAVE_FILE
}

halo_log_info $LOG_TAG  "*** >>> Sidewalk Services Start <<< ***"

cp -aRfP $VETC_PATH/* $DETC_PATH/.

echo $(getprop ro.product.config.type) > $MFG/gateway_device_type;

sync /mnt/halo
update_metrics_config

if [ "$(ls $DETC_PATH/hub-core.conf.d/*.conf)" != "" ]; then
    setprop vendor.halo.hubcore.config true
fi

halo_log_info $LOG_TAG  "*** >>> Sidewalk Services Exit <<< ***"
