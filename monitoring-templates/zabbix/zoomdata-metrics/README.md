# Copyright (C) Zoomdata, Inc. 2012-2018. All rights reserved.

## Zabbix template and supporting script to monitor Zoomdata instance

Zabbix mechanism of external checks was used
https://www.zabbix.com/documentation/3.0/manual/config/items/itemtypes/external

## Installation guide:
1. Make sure you have requests python module installed on zabbix server host (use `pip install requests`) and make sure `/tmp` folder is writtable to user running Zabbix server.
2. Put `zoomdata-metrics-collector.py` script to zabbix externalscripts folder (usualy `/usr/lib/zabbix/externalscripts`)
3. Import `zoomdata-zabbix-template.xml` template to your Zabbix server.
4. Add host running Zoomdata server to your Zabbix system and attach `Template App Zoomdata Service` to this host.
5. There are 2 triggers for monitoring HTTP/HTTPS redirects (80 --> 8080, 443 --> 8443) which can be easily disabled if you're using Zoomdata by native ports (8080/8443). 
