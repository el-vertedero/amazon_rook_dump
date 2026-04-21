#!/system/bin/sh
if ! applypatch -c EMMC:/dev/block/platform/mtk-msdc.0/by-name/recovery:8415232:43f7b6399da1ef490c9eaab04e1a433de4925d69; then
  applypatch -b /system/etc/recovery-resource.dat EMMC:/dev/block/platform/mtk-msdc.0/by-name/boot:7862272:c6769024393f2f2f7dfbca0c2a54aa4b0d42be41 EMMC:/dev/block/platform/mtk-msdc.0/by-name/recovery 43f7b6399da1ef490c9eaab04e1a433de4925d69 8415232 c6769024393f2f2f7dfbca0c2a54aa4b0d42be41:/system/recovery-from-boot.p && echo "
Installing new recovery image: succeeded
" >> /cache/recovery/log || echo "
Installing new recovery image: failed
" >> /cache/recovery/log
else
  log -t recovery "Recovery image already installed"
fi
