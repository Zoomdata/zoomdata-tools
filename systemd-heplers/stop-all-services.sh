#!/bin/bash

for init in /lib/systemd/system/zoomdata-edc-*.service ; do
	systemctl stop $(basename "${init}") 
done
systemctl stop zoomdata-spark-proxy.service 
systemctl stop zoomdata-scheduler.service
systemctl stop zoomdata.service

