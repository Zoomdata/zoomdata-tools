# Copyright (C) Zoomdata, Inc. 2012-2017. All rights reserved.

## Zabbix template and supporting script to monitor Impalad mestrics and etalon table

Zabbix mechanism of external checks was used
https://www.zabbix.com/documentation/3.0/manual/config/items/itemtypes/external

## Installation guide:
1. Make sure you have requests python module installed on zabbix server host (use `pip install requests`) and make sure `/tmp` folder is writtable to user running Zabbix server.
2. Put `impala-metrics-collector.py` and `check_impala` scripts to zabbix externalscripts folder (usualy `/usr/lib/zabbix/externalscripts`)
3. Import `impala-metrics-zabbix-template.xml` template to your Zabbix server.
4. Add host running Impala daemon to your Zabbix system and attach `Template App Impala Daemon` to this host.
5. There are trigger to warn if more than 80% of max sessions limit is reached.
6. Make sure you've uploaded `auto_data` table to Imdata.
