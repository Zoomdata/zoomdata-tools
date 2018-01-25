#!/bin/bash

HELPER_ROOT=${HELPER_ROOT:-"$(dirname "$(dirname "$(pwd)")")"}
ZOOMDATA_INSTALL_ROOT=${ZOOMDATA_INSTALL_ROOT:-"/opt/zoomdata"}

docker run -d --name zoomdata-activity-log-helper \
    -v "$(ZOOMDATA_INSTALL_ROOT)"/logs:/opt/zoomdata/logs \
    -v "$(HELPER_ROOT)"/fluent.conf:/fluentd/etc/fluent.conf \
    -v "$(HELPER_ROOT)"/outputs/mysql:/fluentd/etc/outputs/mysql \
    --env-file "$(HELPER_ROOT)"/outputs/mysql/mysql-env.list \
    zoomdata/activity-log-helper