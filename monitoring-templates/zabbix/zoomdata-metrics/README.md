# Copyright (C) Zoomdata, Inc. 2012-2018. All rights reserved.

## Zabbix template and supporting script to monitor Zoomdata instance

Zabbix external checks mechanism is used
https://www.zabbix.com/documentation/3.0/manual/config/items/itemtypes/external

## Installation Guide
1. Make sure you have requests python module installed on Zabbix server host (use `pip install requests`) and make sure `/tmp` folder is writtable to user running Zabbix server.
2. Put `zoomdata-metrics-collector.py` script to zabbix externalscripts folder (usualy `/usr/lib/zabbix/externalscripts`)
3. Import `zoomdata-zabbix-template.xml` template to your Zabbix server.
4. Add host(s) running Zoomdata server to your Zabbix system and attach `Template App Zoomdata Service` to this host.
5. There are 2 triggers for monitoring HTTP/HTTPS redirects (80 --> 8080, 443 --> 8443) which can be easily disabled if you're using Zoomdata by native ports (8080/8443). 

## Using Zabbix in Docker (Optional)
1. From this directory, build the base image from the included Dockerfile: `docker build -t zoomdata/zabbix-appliance:alpine-3.0 .`
2. Start the container (adjust external ports as needed): `docker run --name zoomdata-zabbix-appliance -p 8081:80 -p 10051:10051 -d zoomdata/zabbix-appliance:alpine-3.0`
3. Access the Zabbix web UI on the external port mapped to port 80 of the container. This is port 8081 in the example in step 2 above. Default `username`:`password` will be `Admin`:`zabbix`.
4. Use the steps in the `Installation Guide` section above to configure your Zoomdata hosts in Zabbix.