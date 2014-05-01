#!/system/bin/sh

case x$SECURE_STORAGE_DIR in x ) echo "Error: no SECURE_STORAGE_DIR envvar defined";; * ) cd $SECURE_STORAGE_DIR/img;; esac

case x$SDCARD in x ) export SDCARD=$EXTERNAL_STORAGE;; esac

SDCARD=`./busybox realpath $SDCARD`

export HOME=/home/$USER
export SHELL=/bin/bash
export LD_LIBRARY_PATH=
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export "LD_PRELOAD=/libdisableselinux.so /libandroid-shmem.so"
./proot -r `pwd` -w / -b /dev -b /proc -b /sys -b /system -b $SDCARD "$@"
