# Remove the directory of legacy davs artifacts

for dir in /data/securedStorageLocation/models /data/securedStorageLocation/aedModels /data/securedStorageLocation/tmpModels;
    do
        if [ -d $dir ]; then
            /system/bin/rm -R $dir
            echo $dir
        fi
    done
