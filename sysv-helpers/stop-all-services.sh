#!/bin/bash 

for init in /etc/init.d/zoomdata-edc-* ; do
        service $(basename "${init}") stop 
done
service zoomdata-spark-proxy stop
service zoomdata-scheduler stop
service zoomdata stop

