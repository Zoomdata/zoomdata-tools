#!/bin/bash

for i in `systemctl list-unit-files | grep zoom | awk ' {print $1} '`; do systemctl stop $i ; done
yum remove -y zoomdata-*
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

