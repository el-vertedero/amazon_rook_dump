#!/system/bin/sh

FW_CRASH_LOGS_DIR=/data/local/wifi_fw_crash
INTERFACE_NAME=wlan0
DHD_TOOL=dhd
PROP_COLLECT_FW_LOGS=lab126.wifi.collect.fwlogs
VAL_COLLECT_FW_LOGS_DONE=completed
MKDIR=mkdir
WL=wl

# Create the parent directory to store firmware crash logs
${MKDIR} -p ${FW_CRASH_LOGS_DIR}

# Construct the file name from current UTC time and date to store crash logs
FW_CRASH_FILE=${FW_CRASH_LOGS_DIR}/crash_`date -u +%Y%m%d:%H%M%S`

${DHD_TOOL} -i ${INTERFACE_NAME} upload ${FW_CRASH_FILE}

echo "" >> ${FW_CRASH_FILE}
echo `${WL} ver` >> ${FW_CRASH_FILE}

setprop ${PROP_COLLECT_FW_LOGS} ${VAL_COLLECT_FW_LOGS_DONE}
