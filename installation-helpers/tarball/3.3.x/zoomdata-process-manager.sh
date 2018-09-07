#!/usr/bin/env bash
################################################################################
## ZOOMDATA 2.6 TARBALL DEPLOYMENT ##
# Prerequisites:
# - Java 1.8 installed on host
# - RabbitMQ installed on host (used to support Zoomdata Upload API and CSV Upload)
# - Max open file limit has been set for user: http://docs.zoomdata.com/2.6/installation-prerequisites
# - Setup the Zoomdata account and databases in Postgres: http://docs.zoomdata.com/2.6/install-and-set-up-zoomdata-metadata-store
# - [OPTIONAL] Install Firefox to enable screenshotting of Zoomdata dashboards/visualizations: http://docs.zoomdata.com/2.6/post-installation-options


# Begin
# Set script variables here for convenience
#INSTALL_DIR="/home/drice/drtest/"  # Installation directory of Zoomdata; place this script and all Zoomdata related tarballs here
INSTALL_DIR=`pwd`
#echo "THIS IS INSTALL DIR " + $INSTALL_DIR
#exit
PG_HOST=${PG_HOST:-"localhost"}  # PostgreSQL Host
PG_PORT=${PG_PORT:-"5432"}  # PostgreSQL Port
PG_USER=${PG_USER:-"zoomdata"}  # PostgreSQL connection user name
PG_PASSWORD=${PG_PASSWORD:-"zoomdata"}  # PostgreSQL connection user password
PG_ZOOMDATA_DB=${PG_ZOOMDATA_DB:-"zoomdata"}  # Zoomdata metadata schema in PostgreSQL
PG_SCHEDULER_DB=${PG_SCHEDULER_DB:-"zoomdata-scheduler"}  # Zoomdata-scheduler metadata schema in PostgreSQL
PG_SCHEDULER_DB=${PG_SCHEDULER_DB:-"zoomdata-keysets"}  # Zoomdata-keysets metadata schema in PostgreSQL
ZOOMDATA_CONF=${INSTALL_DIR}/zoomdata/conf/zoomdata.properties
SCHEDULER_CONF=${INSTALL_DIR}/zoomdata/conf/scheduler.properties

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

helper(){
    NAME=$2
    DAEMONOPTS=$1
    pushd $INSTALL_DIR/zoomdata/bin
    printf "%-50s" "$DAEMONOPTS $NAME..."
    if [ "$NAME" = "consul" ]; then
        case "$1" in
        start)
            ./consul agent -client=127.0.0.1 -bind=127.0.0.1 -bootstrap -server -data-dir=$INSTALL_DIR/zoomdata/data/consul > $INSTALL_DIR/zoomdata/logs/consul.out 2>&1 &
            printf "%s\n" "Ok"
        ;;
        status)
            ./consul info
        ;;
        stop)
            ./consul leave > $INSTALL_DIR/zoomdata/logs/consul.out 2>&1 &
            printf "%s\n" "Ok"
        ;;
         
        restart)
            $0 stop
            $0 start
        ;;
        *)
            echo "Usage: $0 {status|start|stop|restart}"
            exit 1
        esac
    else
        ./$NAME $DAEMONOPTS
    fi
    popd
}

deploy(){
    pushd $INSTALL_DIR
    # Create folder for zoomdata files
    mkdir -p zoomdata/run

    # Unpack tarballs
    for tarball in zoomdata*.tar*
    do
        #echo "THIS IS TARBALL = $tarball"
        tar -xzf $tarball --strip-components=1 -C zoomdata
        #echo "THIS TARBALL FINSIH = $tarball"
    done

    # Set start scripts to be executable
    chmod +x $INSTALL_DIR/zoomdata/bin/*

    #Set Zoomdata Postgres configuration
    printf "spring.datasource.url=jdbc:postgresql://$PG_HOST:$PG_PORT/$PG_ZOOMDATA_DB\nspring.datasource.username=$PG_USER\nspring.datasource.password=$PG_PASSWORD\n" >> $ZOOMDATA_CONF

    #Set Zoomdata-Scheduler Postgres configuration
    printf "spring.datasource.url=jdbc:postgresql://$PG_HOST:$PG_PORT/$PG_SCHEDULER_DB\nspring.datasource.username=$PG_USER\nspring.datasource.password=$PG_PASSWORD\n" >> $SCHEDULER_CONF

    #Deploy client
    mkdir -p zoomdata/client
    #unzip -q client*.zip -d zoomdata/client
    tar -xf client-3.3.0-2.tar.gz 

    #Deploy Consul
    #curl -qL -o zoomdata-consul.zip https://releases.hashicorp.com/consul/0.7.5/consul_0.7.5_linux_amd64.zip
    mkdir -p zoomdata/{bin,data,logs,temp}
    mkdir -p zoomdata/data/consul
    mkdir -p zoomdata/conf/consul.conf.d
    #unzip -q zoomdata-consul.zip -d zoomdata/bin/
    tar -xf consul.tar.gz
    mv $INSTALL_DIR/zoomdata/bin/consul $INSTALL_DIR/zoomdata/
    cp $INSTALL_DIR/zoomdata/bin/zoomdata-consul-3.3.1-1/bin/zoomdata-consul $INSTALL_DIR/zoomdata/bin/consul 
    #mv $INSTALL_DIR/zoomdata/bin/consul/ $INSTALL_DIR/zoomdata/
    #cp $INSTALL_DIR/zoomdata/bin/zoomdata-consul-3.3.1-1/bin/zoomdata-consul $INSTALL_DIR/zoomdata/bin/consul
}

all(){
    pushd $INSTALL_DIR/zoomdata/bin

    # Consul
    helper $1 consul

    # connectors
    for edc in zoomdata-edc* ; do
        helper $1 $edc
    done

    # Zoomdata Query Engine
    helper $1 zoomdata-query-engine
    # Zoomdata-Scheduler
    helper $1 zoomdata-scheduler
    # Zoomdata Upload API services
    helper $1 zoomdata-stream-writer
    helper $1 zoomdata-upload-service
    # Zoomdata web application
    helper $1 zoomdata
    # OPTIONAL Screenshot service (XVFB)
    helper $1 zoomdata-xvfb

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
