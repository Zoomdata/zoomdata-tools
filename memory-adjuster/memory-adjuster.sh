#!/bin/sh

if [ ! -d "/etc/zoomdata" ]; then
    mkdir -p /etc/zoomdata
    chown zoomdata:zoomdata /etc/zoomdata
fi

/usr/bin/env python ./memory-adjuster.py `cat /proc/meminfo | grep "MemTotal" | awk '{print $2}'`

