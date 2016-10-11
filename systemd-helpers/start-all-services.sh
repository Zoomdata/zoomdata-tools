#!/bin/bash

for init in /lib/systemd/system/zoomdata-edc-*.service ; do
	systemctl start $(basename "${init}") 
done
systemctl start zoomdata-spark-proxy.service 
systemctl start zoomdata-scheduler.service
systemctl start zoomdata.service

