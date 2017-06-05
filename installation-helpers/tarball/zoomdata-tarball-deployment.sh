#!/usr/bin/env bash
################################################################################
## ZOOMDATA 2.3+ TARBALL DEPLOYMENT ##
# Prerequisites:
# - Java 1.8 installed on host
# - Max open file limit has been set for user: http://docs.zoomdata.com/installation-prerequisites
# - Setup the Zoomdata account and databases in Postgres: http://docs.zoomdata.com/install-and-set-up-zoomdata-metadata-store
# - [OPTIONAL] Install Firefox to enable screenshotting of Zoomdata dashboards/visualizations: http://docs.zoomdata.com/post-installation-options

# Begin
# Set script variables here for convenience
INSTALL_DIR=${INSTALL_DIR:-"$(dirname $0)"}  # Installation directory of Zoomdata; place all Zoomdata related tarballs here this script should be placed here as well
PG_HOST=${PG_HOST:-"localhost"}  # PostgreSQL Host
PG_PORT=${PG_PORT:-"5432"}  # PostgreSQL Port
PG_USER=${PG_USER:-"zoomdata"}  # PostgreSQL connection user name
PG_PASSWORD=${PG_PASSWORD:-"password"}  # PostgreSQL connection user password
PG_ZOOMDATA_DB=${PG_ZOOMDATA_DB:-"zoomdata"}  # Zoomdata metadata schema in PostgreSQL
PG_SCHEDULER_DB=${PG_SCHEDULER_DB:-"zoomdata-scheduler"}  # Zoomdata-scheduler metadata schema in PostgreSQL
ZOOMDATA_CONF=${INSTALL_DIR}/zoomdata/conf/zoomdata.properties
SCHEDULER_CONF=${INSTALL_DIR}/zoomdata/conf/scheduler.properties

pushd $INSTALL_DIR

# Create folder for zoomdata files
mkdir zoomdata

# Unpack tarballs
for tarball in zoomdata*.tar.gz
do
    tar -xzf $tarball --strip-components=1 -C zoomdata
done

#the following line is necessary to account for relative paths in EDC services scripts
cd $INSTALL_DIR/zoomdata

# Set start scripts to be executable
chmod +x $INSTALL_DIR/zoomdata/bin/*

#Set Zoomdata Postgres configuration
printf "spring.datasource.url=jdbc:postgresql://$PG_HOST:$PG_PORT/$PG_ZOOMDATA_DB\nspring.datasource.username=$PG_USER\nspring.datasource.password=$PG_PASSWORD\n" >> $ZOOMDATA_CONF

#Set Zoomdata-Scheduler Postgres configuration
printf "spring.datasource.url=jdbc:postgresql://$PG_HOST:$PG_PORT/$PG_SCHEDULER_DB\nspring.datasource.username=$PG_USER\nspring.datasource.password=$PG_PASSWORD\n" >> $SCHEDULER_CONF

# Start consul
$INSTALL_DIR/zoomdata/bin/consul agent -client=127.0.0.1 -bind=127.0.0.1 -bootstrap -server -data-dir=$INSTALL_DIR/zoomdata/data/consul &

# Start EDC services
for edc in $INSTALL_DIR/zoomdata/bin/zoomdata-edc* ; do
    $edc &
done

# Start the Zoomdata-Scheduler
$INSTALL_DIR/zoomdata/bin/zoomdata-scheduler &
# Start the Zoomdata Spark Proxy (SparkIt)
$INSTALL_DIR/zoomdata/bin/zoomdata-spark-proxy &
# OPTIONAL Start the Screenshot service (XVFB)
$INSTALL_DIR/zoomdata/bin/zoomdata-xvfb &
# Start the Zoomdata web application
$INSTALL_DIR/zoomdata/bin/zoomdata &

popd
