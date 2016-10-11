#!/bin/bash 

for init in /etc/init.d/zoomdata-edc-* ; do
        service $(basename "${init}") start 
done
service zoomdata-spark-proxy start
service zoomdata-scheduler start
service zoomdata start

