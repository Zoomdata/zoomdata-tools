#!/bin/bash

for i in `systemctl list-unit-files | grep zoom | awk ' {print $1} '`; do systemctl stop $i ; done
yum remove -y zoomdata-*
#yum remove -y zoomdata-consul-2.6.11-77.el7.stable.x86_64.rpm
#yum remove -y zoomdata-query-engine-2.6.11-77.el7.stable.noarch.rpm
#yum remove -y zoomdata-scheduler-2.6.11-77.el7.stable.noarch.rpm
#yum remove -y zoomdata-stream-writer-2.6.8-3.el7.stable.noarch.rpm
#yum remove -y zoomdata-upload-service-2.6.8-3.el7.stable.noarch.rpm
#yum remove -y zoomdata-xvfb-2.6.11-77.el7.stable.noarch.rpm
#yum remove -y zoomdata-zdmanage-1.0.0-stable.noarch.rpm
#yum remove -y zoomdata-edc-cloudera-search-2.6.7-15.el7.stable.noarch.rpm
#yum remove -y zoomdata-edc-impala-2.6.7-15.el7.stable.noarch.rpm
#yum remove -y zoomdata-edc-postgresql-2.6.7-15.el7.stable.noarch.rpm
yum remove -y postgresql95-9*
yum remove -y postgresql95-server-*
yum remove -y postgresql95-libs*
yum remove -y pgdg-redhat95*
yum remove -y rabbitmq*
yum remove -y esl-erlang_*
yum remove -y socat-*

rm -rf var/lib/pgsql/
rm -rf /etc/zoomdata/
rm -rf /etc/zoomdata/
rm -rf /opt/zoomdata/
rm -rf /var/lib/pgsql
rm -rf /opt/zoomdata/
rm -rf /etc/zoomdata
rm -rf /var/lib/pgsql
rm -rf /etc/yum.repos.d/zoom*

