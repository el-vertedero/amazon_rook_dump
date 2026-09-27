#!/system/bin/sh
if ! applypatch -c EMMC:/dev/block/platform/mtk-msdc.0/by-name/recovery:8415232:fc0864ed56dcbc62bdf320400f2184ed06813e26; then
  applypatch -b /system/etc/recovery-resource.dat EMMC:/dev/block/platform/mtk-msdc.0/by-name/boot:7862272:26f9307ddf6aa1edbe86e971ed358d9d4626b992 EMMC:/dev/block/platform/mtk-msdc.0/by-name/recovery fc0864ed56dcbc62bdf320400f2184ed06813e26 8415232 26f9307ddf6aa1edbe86e971ed358d9d4626b992:/system/recovery-from-boot.p && echo "
Installing new recovery image: succeeded
" >> /cache/recovery/log || echo "
Installing new recovery image: failed
" >> /cache/recovery/log
else
  log -t recovery "Recovery image already installed"
fi
