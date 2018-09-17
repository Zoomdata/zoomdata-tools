FROM zabbix/zabbix-appliance:alpine-3.0-latest

RUN apk update \
 && apk add ca-certificates wget \
 && update-ca-certificates \
 && apk add --update py-pip \
 && pip install requests

ADD zoomdata-metrics-collector.py /usr/lib/zabbix/externalscripts/zoomdata-metrics-collector.py
RUN chmod +x /usr/lib/zabbix/externalscripts/zoomdata-metrics-collector.py 