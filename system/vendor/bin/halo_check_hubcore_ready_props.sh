#!/system/bin/sh

HALO_PATH=/vendor/bin

[ -f ${HALO_PATH}/halo_common_lib.sh ] && . ${HALO_PATH}/halo_common_lib.sh

LOG_TAG="halo-check-props"

prop_hubcore_config=$(getprop vendor.halo.hubcore.config)
prop_protocol_state=$(getprop vendor.halo.protocol.enable)

halo_log_info $LOG_TAG "hubcore.config: ${prop_hubcore_config}, protocol.enable: ${prop_protocol_state}"

if [ "$prop_hubcore_config" = "true" ] && [ "$prop_protocol_state" = "true" ]; then
    setprop vendor.halo.hubcore.ready true
fi
