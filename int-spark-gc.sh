#!/bin/bash

set -e

SPARK_TMP_DIR=${1:-/opt/zoomdata/temp}

echo "==> Stopping Zoomdata Application"
service zoomdata stop
sleep 3

echo "==> cleaning files older2 days in ${SPARK_TMP_DIR} directory"
find "${SPARK_TMP_DIR}/" -mtime +2 -exec rm -r {} \;

echo "==> Starting Zoomdata Application"
service zoomdata start

