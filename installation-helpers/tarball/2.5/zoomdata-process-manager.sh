#!/usr/bin/env bash
################################################################################
## ZOOMDATA 2.3-2.5 TARBALL DEPLOYMENT ##
# Prerequisites:
# - Java 1.8 installed on host
# - Max open file limit has been set for user: http://docs.zoomdata.com/2.5/installation-prerequisites
# - Setup the Zoomdata account and databases in Postgres: http://docs.zoomdata.com/2.5/install-and-set-up-zoomdata-metadata-store
# - [OPTIONAL] Install Firefox to enable screenshotting of Zoomdata dashboards/visualizations: http://docs.zoomdata.com/2.5/post-installation-options

# Begin
# Set script variables here for convenience
INSTALL_DIR=${INSTALL_DIR:-"$(pwd)"}  # Installation directory of Zoomdata; place this script and all Zoomdata related tarballs here
PG_HOST=${PG_HOST:-"localhost"}  # PostgreSQL Host
PG_PORT=${PG_PORT:-"5432"}  # PostgreSQL Port
PG_USER=${PG_USER:-"zoomdata"}  # PostgreSQL connection user name
PG_PASSWORD=${PG_PASSWORD:-"password"}  # PostgreSQL connection user password
PG_ZOOMDATA_DB=${PG_ZOOMDATA_DB:-"zoomdata"}  # Zoomdata metadata schema in PostgreSQL
PG_SCHEDULER_DB=${PG_SCHEDULER_DB:-"zoomdata-scheduler"}  # Zoomdata-scheduler metadata schema in PostgreSQL
ZOOMDATA_CONF=${INSTALL_DIR}/zoomdata/conf/zoomdata.properties
SCHEDULER_CONF=${INSTALL_DIR}/zoomdata/conf/scheduler.properties

helper(){
    NAME=$2
    DAEMONOPTS=""
    PIDFILE=$INSTALL_DIR/zoomdata/run/$NAME.pid
    case "$1" in
    start)
        printf "%-50s" "Starting $NAME..."
        pushd $INSTALL_DIR/zoomdata
        if [ "$NAME" = "consul" ]; then
            ./bin/consul agent -client=127.0.0.1 -bind=127.0.0.1 -bootstrap -server -data-dir=$INSTALL_DIR/zoomdata/data/consul > $INSTALL_DIR/zoomdata/logs/consul.out 2>&1 &
        else
            PID=`bin/$NAME $DAEMONOPTS > $INSTALL_DIR/zoomdata/logs/$NAME.out  2>&1 & echo $!`
            #echo "Saving PID" $PID " to " $PIDFILE
                if [ -z $PID ]; then
                    printf "%s\n" "Fail"
                else
                    echo $PID > $PIDFILE
                    printf "%s\n" "Ok"
                fi
        fi
        popd
    ;;
    status)
        printf "%-50s" "Checking $NAME..."
        pushd $INSTALL_DIR/zoomdata/run
        if [ "$NAME" = "consul" ]; then
            ../bin/consul info
        else
            if [ -f $PIDFILE ]; then
                PID=`cat $PIDFILE`
                if [ -z "`ps axf | grep ${PID} | grep -v grep`" ]; then
                    printf "%s\n" "Process dead but pidfile exists"
                else
                    echo "Running"
                fi
            else
                printf "%s\n" "Service not running"
            fi
        fi
        popd
    ;;
    stop)
        printf "%-50s" "Stopping $NAME"
        pushd $INSTALL_DIR/zoomdata/run
        if [ "$NAME" = "consul" ]; then
            ../bin/consul leave > $INSTALL_DIR/zoomdata/logs/consul.out 2>&1 &
        else
            if [ -f $PIDFILE ]; then
                PID=`cat $PIDFILE`      
                kill $PID
                printf "%s\n" "Ok"
                rm -f $PIDFILE
            else
                printf "%s\n" "pidfile not found"
            fi
        fi
        popd
    ;;
     
    restart)
        $0 stop
        $0 start
    ;;
    *)
        echo "Usage: $0 {status|start|stop|restart}"
        exit 1
    esac
}

deploy(){
    pushd $INSTALL_DIR
    # Create folder for zoomdata files
    mkdir -p zoomdata/run

    # Unpack tarballs
    for tarball in zoomdata*.tar.gz
    do
        tar -xzf $tarball --strip-components=1 -C zoomdata
    done

    # Set start scripts to be executable
    chmod +x $INSTALL_DIR/zoomdata/bin/*

    #Set Zoomdata Postgres configuration
    printf "spring.datasource.url=jdbc:postgresql://$PG_HOST:$PG_PORT/$PG_ZOOMDATA_DB\nspring.datasource.username=$PG_USER\nspring.datasource.password=$PG_PASSWORD\n" >> $ZOOMDATA_CONF

    #Set Zoomdata-Scheduler Postgres configuration
    printf "spring.datasource.url=jdbc:postgresql://$PG_HOST:$PG_PORT/$PG_SCHEDULER_DB\nspring.datasource.username=$PG_USER\nspring.datasource.password=$PG_PASSWORD\n" >> $SCHEDULER_CONF

    #Deploy client
    mkdir -p zoomdata/client
    unzip client*.zip -d zoomdata/client
}

all(){
    pushd $INSTALL_DIR/zoomdata/bin

    # Consul
    helper $1 consul

    # connectors
    for edc in zoomdata-edc* ; do
        helper $1 $edc
    done

    # Zoomdata-Scheduler
    helper $1 zoomdata-scheduler
    # Zoomdata Spark Proxy (SparkIt)
    helper $1 zoomdata-spark-proxy
    # OPTIONAL Screenshot service (XVFB)
    helper $1 zoomdata-xvfb
    # Zoomdata web application
    helper $1 zoomdata

    popd
}

case $(echo "$1" | awk '{print tolower($0)}') in
    start)
        if [ -z "$2" ] ; then
            all start
        else
            helper start $2
        fi
    ;;
    stop)
        if [ -z "$2" ] ; then
            all stop
        else
            helper stop $2
        fi
    ;;
    restart)
        if [ -z "$2" ] ; then
            all stop
            all start
        else
            helper stop $2
            helper start $2
        fi
    ;;
    status)
        if [ -z "$2" ] ; then
            all status
        else
            helper status $2
        fi
    ;;
    deploy)
        if [ -d "$INSTALL_DIR/zoomdata" ] ; then
            echo "Directory 'zoomdata' already exists in the INSTALL_DIR"
            exit 1
        else
            deploy
        fi
    ;;
    *)
        echo "Usage: $0 {status|start|stop|restart|deploy}"
        exit 1
esac
