#!/bin/sh

if [ ! -d "/etc/zoomdata" ]; then
    mkdir -p /etc/zoomdata
    chown zoomdata:zoomdata /etc/zoomdata
fi

/usr/bin/python ./memory-adjuster.py `/usr/bin/cat /proc/meminfo |/bin/grep "MemTotal" | /usr/bin/awk '{print $2}'`

