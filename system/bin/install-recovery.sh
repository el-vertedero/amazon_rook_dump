#!/system/bin/sh
if ! applypatch -c EMMC:/dev/block/platform/mtk-msdc.0/by-name/recovery:8499200:79de67bec1fa7acddfaefae72a298cfef96030cd; then
  applypatch -b /system/etc/recovery-resource.dat EMMC:/dev/block/platform/mtk-msdc.0/by-name/boot:7979008:b93f345e6f86d99a4dae0d145ec3f79083e9a2d5 EMMC:/dev/block/platform/mtk-msdc.0/by-name/recovery 79de67bec1fa7acddfaefae72a298cfef96030cd 8499200 b93f345e6f86d99a4dae0d145ec3f79083e9a2d5:/system/recovery-from-boot.p && echo "
Installing new recovery image: succeeded
" >> /cache/recovery/log || echo "
Installing new recovery image: failed
" >> /cache/recovery/log
else
  log -t recovery "Recovery image already installed"
fi
