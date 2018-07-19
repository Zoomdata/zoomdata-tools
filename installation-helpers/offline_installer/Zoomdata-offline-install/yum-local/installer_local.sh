#!/bin/sh

# Bootstrap Zoomdata

# Default installation path
INSTALL_PATH="/opt/zoomdata"

# Start services by default
skip_start="false"

# Dist default variables
dist_arch="unknown"
dist_type="unknown"

# RedHat default variables
redhat_dist="unknown"
redhat_release="unknown"

#REDHAT_PG_REPO_URL='https://download.postgresql.org/pub/repos/yum/9.5/redhat'
#REDHAT_PG_REPO_VERSION='9.5-3'

# Debian default variables
debian_dist="unknown"
debian_codename="unknown"

# Core services list in starting order
SERVICES='zoomdata-consul,zoomdata-query-engine,zoomdata-scheduler,zoomdata-stream-writer,zoomdata-upload-service,zoomdata'

# Services need to be removed
LEGACY_SERVICES='zoomdata-spark-proxy'

# Mandatory packages to install
PACKAGES="$SERVICES,zoomdata-zdmanage,zoomdata-xvfb"

# Connectors list
connectors='apache-solr,cloudera-search,elasticsearch-5.0,elasticsearch-6.0,impala,memsql,mongo,mssql,mysql,oracle,phoenix-4.7-queryserver,postgresql,redshift,rts,tez,sparksql'

# Zoomdata repo
ZOOMDATA_VERSION=${ZOOMDATA_VERSION:-2.6}
ZOOMDATA_REPO_NAME=${ZOOMDATA_REPO_NAME:-zoomdata-${ZOOMDATA_VERSION}}
ZOOMDATA_REPO_URI=${ZOOMDATA_REPO_URI:-file:///tmp/yum-local}
#ZOOMDATA_REPO_KEY=${ZOOMDATA_REPO_KEY:-${ZOOMDATA_REPO_URI}/ZOOMDATA-GPG-KEY.pub}

# Metadata connection details
ZOOMDATA_PG_BASE_URL=${ZOOMDATA_PG_BASE_URL:-jdbc:postgresql://localhost:5432}
ZOOMDATA_PG_USER=${ZOOMDATA_PG_USER:-zoomdata}
# Zoomdata password
zoomdata_pg_password="unknown"

# Toggle interactive dialog
ZOOMDATA_ASK_JAVA_INSTALL=${ZOOMDATA_ASK_JAVA_INSTALL:-false}


__die () {
    echo "$*" >&2
    exit 1
}

__expand_list () {
    echo "${1}" | tr ',' '\n'
}

__check_command_exists() {
    command -v "$1" > /dev/null 2>&1
}

__lsb_get_var () {
    awk 'BEGIN { FS="[ \t]*=[ \t]*" } $1 == "'"$1"'" { print $2; exit }' /etc/lsb-release
}

# Detect DIST and populate vars
detect_distrib () {
    dist_arch="$(uname -m)"
    if [ -r /etc/redhat-release ] ; then
        dist_type="redhat"
        case "$(sed 's: release.*::' /etc/redhat-release)" in
            "CentOS"|"CentOS Linux")
                redhat_dist="centos"
                ;;
            "Red Hat Enterprise Linux Server")
                redhat_dist="redhat"
                ;;
            "Scientific Linux")
                redhat_dist="sl"
                ;;
            *)
                __die "Error: unsupported redhat based distro"
                ;;
        esac
        case "$(sed 's:.*release\ ::' /etc/redhat-release | sed 's:\..*::')" in
            6)
                redhat_release="6"
                ;;
            7)
                redhat_release="7"
                ;;
            *)
                __die "Error: unsupported OS version"
                ;;
        esac
    elif [ -r /etc/lsb-release ] ; then
        case "$(__lsb_get_var DISTRIB_ID)" in
            Ubuntu)
                dist_type="debian"
                debian_dist="ubuntu"
                debian_codename="$(__lsb_get_var DISTRIB_CODENAME)"
                ;;
            *)
                __die "Error: unsupported distro"
                ;;
        esac
    fi
}

install_deps_redhat () {
    echo "Upgrading required packages"
    yum update -y curl ca-certificates >>/tmp/zoomdata-installer.log 2>&1
}

install_deps_debian () {
    echo "Installing required packages"
    apt-get update >>/tmp/zoomdata-installer.log 2>&1
    apt-get install -y apt-transport-https ca-certificates curl >>/tmp/zoomdata-installer.log 2>&1
    case "${debian_codename}" in
        trusty)
            __check_command_exists python || \
                apt-get install -y python >>/tmp/zoomdata-installer.log 2>&1
            ;;
        xenial)
            __check_command_exists python3 || \
                apt-get install -y python3 >>/tmp/zoomdata-installer.log 2>&1
            ;;
        *)
            __die "Error: unsupported OS version"
            ;;
    esac
}

check_permissions () {
    if [ "$(id -u)" != "0" ]; then
        __die "Error: this script must be run as root"
    fi
}

pg_add_repo_redhat () {
    echo "Adding official postgresql repository"
    if [ ! -r /etc/yum.repos.d/pgdg-95-centos.repo ] ; then
        yum install -y \
            ${REDHAT_PG_REPO_URL}/rhel-${redhat_release}-x86_64/pgdg-${redhat_dist}95-${REDHAT_PG_REPO_VERSION}.noarch.rpm \
            >>/tmp/zoomdata-installer.log 2>&1
    fi
}

pg_add_repo_debian () {
    echo "Adding official postgresql repository"
    if [ ! -r /etc/apt/sources.list.d/pgdg.list ] ; then
        echo "deb http://apt.postgresql.org/pub/repos/apt/ ${debian_codename}-pgdg main" > /etc/apt/sources.list.d/pgdg.list
        curl "https://www.postgresql.org/media/keys/ACCC4CF8.asc" 2>/dev/null | apt-key add - >>/tmp/zoomdata-installer.log 2>&1
        apt-get update >>/tmp/zoomdata-installer.log 2>&1
    fi
}

pg_install_redhat () {
    echo "Installing postgresql server"
    yum install --enablerepo=zoomdata-2.6 -y postgresql95-libs  >>/tmp/zoomdata-installer.log 2>&1
    yum install --enablerepo=zoomdata-2.6 -y postgresql95-9*  >>/tmp/zoomdata-installer.log 2>&1
    yum install --enablerepo=zoomdata-2.6 -y postgresql95-server* >>/tmp/zoomdata-installer.log 2>&1
}

pg_install_debian () {
    echo "Installing postgresql server"
    apt-get install -y postgresql-9.5 >>/tmp/zoomdata-installer.log 2>&1
}

pg_configure_redhat () {
    echo "Initializing postgresql database and configuring postgresql server"
    case ${redhat_release} in
        6)
            service postgresql-9.5 initdb >>/tmp/zoomdata-installer.log 2>&1
            ;;
        7)
            /usr/pgsql-9.5/bin/postgresql95-setup initdb >>/tmp/zoomdata-installer.log 2>&1
            ;;
        *)
            __die "Error: unsupported redhat based distro version"
            ;;
    esac
    (
        cd /var/lib/pgsql/9.5/data && \
            sed -i.orig 's:^\(host.*\)ident$:\1md5:g' pg_hba.conf >>/tmp/zoomdata-installer.log 2>&1
    ) || __die "Error: PostgreSQL data directory not found"
}

pg_start_service_redhat () {
    echo "Enabling and starting postgresql server"
    case ${redhat_release} in
        6)
            chkconfig postgresql-9.5 on >>/tmp/zoomdata-installer.log 2>&1
            service postgresql-9.5 start >>/tmp/zoomdata-installer.log 2>&1
            ;;
        7)
            systemctl enable postgresql-9.5.service >>/tmp/zoomdata-installer.log 2>&1
            systemctl start postgresql-9.5.service >>/tmp/zoomdata-installer.log 2>&1
            ;;
        *)
            __die "Error: unsupported redhat based distro version"
            ;;
    esac
}

pg_upload_service_configure () {
    echo "Creating postgresql Zoomdata Upload schema"
    su - postgres -c psql >>/tmp/zoomdata-installer.log 2>&1 <<EOF
CREATE DATABASE "zoomdata-upload" WITH OWNER ${ZOOMDATA_PG_USER}
EOF
}

pg_keyset_configure () {
    echo "Creating postgresql Zoomdata Keyset schema"
    su - postgres -c psql >>/tmp/zoomdata-installer.log 2>&1 <<EOF
CREATE DATABASE "zoomdata-keyset" WITH OWNER ${ZOOMDATA_PG_USER}
EOF
}

pg_init () {
    echo "Creating postgresql Zoomdata user and schemas"
    su - postgres -c psql >>/tmp/zoomdata-installer.log 2>&1 <<EOF
CREATE USER ${ZOOMDATA_PG_USER} WITH PASSWORD '${zoomdata_pg_password}';
CREATE DATABASE "zoomdata" WITH OWNER ${ZOOMDATA_PG_USER};
CREATE DATABASE "zoomdata-scheduler" WITH OWNER ${ZOOMDATA_PG_USER};
EOF
    # Configure PostgreSQL for upload service
    pg_upload_service_configure
    # Configure PostgreSQL for keyset feature
    pg_keyset_configure
}

pg_detect_redhat_package () {
    echo "Detecting installed postgresql server"
    if yum list installed postgresql*-server >>/tmp/zoomdata-installer.log 2>&1 ; then
        return 0 # true
    else
        return 1 # false
    fi
}

pg_detect_redhat_data () {
    echo "Detecting initialized postgresql database"
    if [ -r /var/lib/pgsql/9.5/data/pg_hba.conf ] ; then
        return 0 # true
    else
        return 1 # false
    fi
}

pg_detect_debian_package () {
    echo "Detecting installed postgresql server"
    if dpkg-query -s postgresql-common 2>/dev/null | grep -q ^"Status: install ok installed" >>/tmp/zoomdata-installer.log 2>&1 ; then
        return 0 # true
    else
        return 1 # false
    fi
}

# ============ RabbitMQ + Erlang deployment section
rmq_add_repo_redhat () {
    # using https://packagecloud.io/rabbitmq/rabbitmq-server/install#bash to bootstrap RabbitMQ server repo
    echo "Setting up RabbitMQ server official repository"
    curl -sL https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash >>/tmp/zoomdata-installer.log 2>&1
}

rmq_add_repo_debian () {
    # using https://packagecloud.io/rabbitmq/rabbitmq-server/install#bash to bootstrap RabbitMQ server repo
    echo "Setting up RabbitMQ server official repository"
    curl -sL https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.deb.sh | bash >>/tmp/zoomdata-installer.log 2>&1
}

erlang_install_redhat () {
    echo "Setting up ERLang official repository"
    # Using zero dependency version of ERLang prepared by RabbitMQ team
#     curl -sL https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | bash >>/tmp/zoomdata-installer.log 2>&1
    echo "Installing ERLang"
    yum -y install erlang >>/tmp/zoomdata-installer.log 2>&1
}

erlang_install_debian () {
    # using https://www.erlang-solutions.com/resources/download.html to bootstrap ERLang repo
    echo "Setting up ERLang official repository"
    (
        curl -L -o /tmp/erlang-repo.deb https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && \
            dpkg -i /tmp/erlang-repo.deb && \
            apt-get update
    ) >>/tmp/zoomdata-installer.log 2>&1 || \
        __die 'Failed to set up ERLang official repository'
    echo "Installing ERLang"
    apt-get -y install esl-erlang >>/tmp/zoomdata-installer.log 2>&1
    rm -f /tmp/erlang-repo.deb
}

rmq_install_redhat () {
    # RabbitMQ server depends on package `socat` which available in EPEL repo
    echo "Enabling EPEL repo"
#    yum -y install epel-release >>/tmp/zoomdata-installer.log 2>&1
    echo "Installing RabbitMQ server"
    yum -y install socat rabbitmq-server >>/tmp/zoomdata-installer.log 2>&1
}

rmq_install_debian () {
    echo "Installing RabbitMQ server"
    apt-get -y install rabbitmq-server >>/tmp/zoomdata-installer.log 2>&1
}

rmq_enable_redhat () {
    echo "Enabling RabbitMQ service autostart"
    case "${redhat_release}" in
        6)
            chkconfig rabbitmq-server on >>/tmp/zoomdata-installer.log 2>&1
            ;;
        7)
            systemctl enable rabbitmq-server >>/tmp/zoomdata-installer.log 2>&1
            ;;
        *)
            __die "Error: unsupported OS version"
            ;;
    esac
}

rmq_enable_debian () {
    echo "Enabling RabbitMQ service autostart"
    case "${debian_codename}" in
        trusty)
            update-rc.d rabbitmq-server defaults >>/tmp/zoomdata-installer.log 2>&1
            ;;
        xenial)
            systemctl enable rabbitmq-server >>/tmp/zoomdata-installer.log 2>&1
            ;;
        *)
            __die "Error: unsupported OS version"
            ;;
    esac
}

rmq_start_redhat () {
    echo "Starting RabbitMQ service"
    case "${redhat_release}" in
        6)
            service rabbitmq-server start >>/tmp/zoomdata-installer.log 2>&1
            ;;
        7)
            systemctl start rabbitmq-server >>/tmp/zoomdata-installer.log 2>&1
            ;;
        *)
            __die "Error: unsupported OS version"
            ;;
    esac
}

rmq_start_debian () {
    echo "Starting RabbitMQ service"
    case "${debian_codename}" in
        trusty)
            if ! service rabbitmq-server status >/dev/null 2>&1; then
                service rabbitmq-server start >>/tmp/zoomdata-installer.log 2>&1
            fi
            ;;
        xenial)
            if ! systemctl status rabbitmq-server >/dev/null 2>&1; then
                systemctl start rabbitmq-server >>/tmp/zoomdata-installer.log 2>&1
            fi
            ;;
        *)
            __die "Error: unsupported OS version"
            ;;
    esac
}

rmq_detect_installed_redhat () {
    echo "Detecting if RabbitMQ is already installed"
    if yum list installed rabbitmq-server >>/tmp/zoomdata-installer.log 2>&1 ; then
        return 0 # true
    else
        return 1 # false
    fi
}

rmq_detect_installed_debian () {
    echo "Detecting if RabbitMQ is already installed"
    if dpkg-query -s rabbitmq-server 2>/dev/null | grep -q ^"Status: install ok installed" >>/tmp/zoomdata-installer.log 2>&1 ; then
        return 0 # true
    else
        return 1 # false
    fi
}

# =================================================

#zoomdata_add_gpgkey_redhat () {
#    echo "Add zoomdata repository key"
#    rpm --import "${ZOOMDATA_REPO_KEY}" >>/tmp/zoomdata-installer.log 2>&1
#}

zoomdata_add_repo_redhat () {
    echo "Adding zoomdata official repository"
    zoomdata_tools_repo_file="/etc/yum.repos.d/zoomdata-tools.repo"
    yum install -y /tmp/yum-local/Packages/createrepo_c-0.10.0-6.el7.x86_64.rpm 
    createrepo /tmp/yum-local	
    repo_file="/etc/yum.repos.d/${ZOOMDATA_REPO_NAME}.repo"
    if [ ! -r "${repo_file}" ] ; then
        cat <<EOF > "${repo_file}"
[${ZOOMDATA_REPO_NAME}]
name=Zoomdata ${ZOOMDATA_VERSION} stable RPMs
baseurl=${ZOOMDATA_REPO_URI}
enabled=1
gpgcheck=0

EOF
    fi
    yum makecache >>/tmp/zoomdata-installer.log 2>&1
}

zoomdata_add_gpgkey_debian () {
    echo "Add zoomdata repository key"
    curl "${ZOOMDATA_REPO_KEY}" 2>/dev/null | apt-key add - >>/tmp/zoomdata-installer.log 2>&1
}

zoomdata_add_repo_debian () {
    echo "Adding zoomdata official repository"
    zoomdata_tools_repo_file="/etc/apt/sources.list.d/zoomdata-tools.list"
    repo_file="/etc/apt/sources.list.d/${ZOOMDATA_REPO_NAME}.list"
    if [ ! -r "${repo_file}" ] ; then
        cat <<EOF > "${repo_file}"
# stable repo
deb ${ZOOMDATA_REPO_URI}/${ZOOMDATA_VERSION}/apt/${debian_dist} ${debian_codename} stable

# unstable repo
#deb ${ZOOMDATA_REPO_URI}/${ZOOMDATA_VERSION}/apt/${debian_dist} ${debian_codename} unstable
EOF
    fi
    if [ ! -r "${zoomdata_tools_repo_file}" ] ; then
        cat <<EOF > "${zoomdata_tools_repo_file}"
# zoomdata-tools
deb ${ZOOMDATA_REPO_URI}/tools/apt/${debian_dist} ${debian_codename} stable
EOF
    fi
    apt-get update >>/tmp/zoomdata-installer.log 2>&1
}

zoomdata_detect_config () {
    if [ -r /etc/zoomdata/zoomdata.properties ] ; then
        __die "Error: zoomdata already have configuration file: /etc/zoomdata/zoomdata.properties"
    fi
    if [ -r /etc/zoomdata/scheduler.properties ] ; then
        __die "Error: zoomdata-scheduler already have configuration file: /etc/zoomdata/scheduler.properties"
    fi
}

upload_configure () {
    # Add upload service configuration to default zoomdata.properties
    cat >> /etc/zoomdata/zoomdata.properties <<EOF
upload.destination.params.jdbc_url=${ZOOMDATA_PG_BASE_URL}/zoomdata-upload
upload.destination.params.user_name=${ZOOMDATA_PG_USER}
upload.destination.params.password=${zoomdata_pg_password}
upload.destination.schema=public
upload.batch-size=1000
EOF
}

keyset_configure () {
    # Add keyset feature configuration to default zoomdata.properties
    cat >> /etc/zoomdata/zoomdata.properties <<EOF
keyset.destination.params.jdbc_url=${ZOOMDATA_PG_BASE_URL}/zoomdata-keyset
keyset.destination.params.user_name=${ZOOMDATA_PG_USER}
keyset.destination.params.password=${zoomdata_pg_password}
keyset.destination.schema=public
EOF
}

zoomdata_configure () {
    echo "Configurating zoomdata"
    if [ ! -d /etc/zoomdata ] ; then
        install -d -m 0755 /etc/zoomdata >>/tmp/zoomdata-installer.log 2>&1
    fi
    # Prepare Zoomdata config
    cat > /etc/zoomdata/zoomdata.properties <<EOF
spring.datasource.url=${ZOOMDATA_PG_BASE_URL}/zoomdata
spring.datasource.username=${ZOOMDATA_PG_USER}
spring.datasource.password=${zoomdata_pg_password}
EOF

    # Add Upload Service properties
    upload_configure

    # Add Keyset feature properties
    keyset_configure

    # Prepare Scheduler config
    cat > /etc/zoomdata/scheduler.properties <<EOF
spring.datasource.url=${ZOOMDATA_PG_BASE_URL}/zoomdata-scheduler
spring.datasource.username=${ZOOMDATA_PG_USER}
spring.datasource.password=${zoomdata_pg_password}
EOF
}

zoomdata_edc_install_redhat () {
    edc_to_install=""
    for connector in $(__expand_list $connectors) ; do
        pkg="zoomdata-edc-${connector}"
        if yum list available "$pkg" >>/tmp/zoomdata-installer.log 2>&1 ; then
            edc_to_install="${edc_to_install} ${pkg}"
        else
            echo "Package ${pkg} not found"
        fi
    done
    echo "Installing connectors:${edc_to_install}"
    # shellcheck disable=SC2086
    yum install --enablerepo="${ZOOMDATA_REPO_NAME}" -y ${edc_to_install} >>/tmp/zoomdata-installer.log 2>&1
}

zoomdata_install_redhat () {
    echo "Installing zoomdata"
    # shellcheck disable=SC2046
    yum install --enablerepo="${ZOOMDATA_REPO_NAME}" -y $(__expand_list $PACKAGES) >>/tmp/zoomdata-installer.log 2>&1
    if [ "x" != "x${connectors}" ] ; then
        zoomdata_edc_install_redhat
    fi
}

zoomdata_edc_install_debian () {
    edc_to_install=""
    for connector in $(__expand_list $connectors) ; do
        pkg="zoomdata-edc-${connector}"
        if apt-cache show "$pkg" >>/tmp/zoomdata-installer.log 2>&1 ; then
            edc_to_install="${edc_to_install} ${pkg}"
        else
            echo "Package ${pkg} not found"
        fi
    done
    echo "Installing connectors:${edc_to_install}"
    # shellcheck disable=SC2086
    apt-get install -y ${edc_to_install} >>/tmp/zoomdata-installer.log 2>&1
}

zoomdata_install_debian () {
    echo "Installing zoomdata"
    # shellcheck disable=SC2046
    apt-get install -y $(__expand_list $PACKAGES) >>/tmp/zoomdata-installer.log 2>&1
    if [ "x" != "x${connectors}" ] ; then
        zoomdata_edc_install_debian
    fi
}

zoomdata_detect_redhat () {
    echo "Detecting installed zoomdata"
    if yum list installed zoomdata >>/tmp/zoomdata-installer.log 2>&1 ; then
        return 0 # true
    else
        return 1 # false
    fi
}

zoomdata_detect_debian () {
    echo "Detecting installed zoomdata"
    if dpkg-query -s zoomdata 2>/dev/null | grep -q ^"Status: install ok installed" >>/tmp/zoomdata-installer.log 2>&1 ; then
        return 0 # true
    else
        return 1 # false
    fi
}

zoomdata_stop_sysv () {
    for init in /etc/init.d/zoomdata-edc-* ; do
        service "$(basename "${init}")" stop >>/tmp/zoomdata-installer.log 2>&1
    done
    for service in $(__expand_list $SERVICES | tac); do
        service "$service" stop >>/tmp/zoomdata-installer.log 2>&1
    done
    # Stop legacy services
    for service in $(__expand_list $LEGACY_SERVICES); do
        if service --status-all | grep -q -w "$service" && \
            service "$service" status >/dev/null 2>&1; then
            service "$service" stop >>/tmp/zoomdata-installer.log 2>&1
        fi
    done
}

zoomdata_stop_systemd () {
    for init in /lib/systemd/system/zoomdata-edc-*.service ; do
        systemctl stop "$(basename "${init}")" >>/tmp/zoomdata-installer.log 2>&1
    done
    for service in $(__expand_list $SERVICES | tac); do
        systemctl stop "${service}.service" >>/tmp/zoomdata-installer.log 2>&1
    done
    # Stop legacy services
    for service in $(__expand_list $LEGACY_SERVICES); do
        if systemctl list-units | grep -q -w "${service}\.service" && \
            systemctl status "${service}.service" >/dev/null 2>&1; then
            systemctl stop "${service}.service" >>/tmp/zoomdata-installer.log 2>&1
        fi
    done
}

zoomdata_stop_redhat () {
    echo "Stopping zoomdata services"
    case "${redhat_release}" in
        6)
            zoomdata_stop_sysv
            ;;
        7)
            zoomdata_stop_systemd
            ;;
        *)
            __die "Error: unsupported OS version"
            ;;
    esac
}

zoomdata_stop_debian () {
    echo "Stopping zoomdata services"
    case "${debian_codename}" in
        trusty)
            zoomdata_stop_sysv
            ;;
        xenial)
            zoomdata_stop_systemd
            ;;
        *)
            __die "Error: unsupported OS version"
            ;;
    esac
}

zoomdata_start_sysv () {
    for service in $(__expand_list $SERVICES); do
        service "$service" start >>/tmp/zoomdata-installer.log 2>&1
    done
    for init in /etc/init.d/zoomdata-edc-* ; do
        service "$(basename "${init}")" start >>/tmp/zoomdata-installer.log 2>&1
    done
}

zoomdata_start_systemd () {
    for service in $(__expand_list $SERVICES); do
        systemctl start "${service}.service" >>/tmp/zoomdata-installer.log 2>&1
    done
    for init in /lib/systemd/system/zoomdata-edc-*.service ; do
        systemctl start "$(basename "${init}")" >>/tmp/zoomdata-installer.log 2>&1
    done
}

zoomdata_show_start_message() {
    echo "The Zoomdata service was started."
    echo "Please note that in upgrade scenarios it may take several minutes"
    echo "for the Zoomdata service to complete its upgrade of metadata."
    echo "Please wait a few minutes before stopping or restarting the Zoomdata service."
}

zoomdata_start_redhat () {
    echo "Starting zoomdata services"
    case "${redhat_release}" in
        6)
            zoomdata_start_sysv
            ;;
        7)
            zoomdata_start_systemd
            ;;
        *)
            __die "Error: unsupported OS version"
            ;;
    esac
    zoomdata_show_start_message
}

zoomdata_start_debian (){
    echo "Starting zoomdata services"
    case "${debian_codename}" in
        trusty)
            zoomdata_start_sysv
            ;;
        xenial)
            zoomdata_start_systemd
            ;;
        *)
            __die "Error: unsupported OS version"
            ;;
    esac
    zoomdata_show_start_message
}

zoomdata_enable_systemd () {
    for init in /lib/systemd/system/zoomdata-edc-*.service ; do
        systemctl enable "$(basename "${init}")" >>/tmp/zoomdata-installer.log 2>&1
    done
    for service in $(__expand_list $SERVICES); do
        systemctl enable "${service}.service" >>/tmp/zoomdata-installer.log 2>&1
    done
}

zoomdata_enable_redhat () {
    echo "Enabling zoomdata services"
    case "${redhat_release}" in
        6)
            for init in /etc/init.d/zoomdata-edc-* ; do
                chkconfig "$(basename "${init}")" on >>/tmp/zoomdata-installer.log 2>&1
            done
            for service in $(__expand_list $SERVICES); do
                chkconfig "$service" on >>/tmp/zoomdata-installer.log 2>&1
            done
            ;;
        7)
            zoomdata_enable_systemd
            ;;
        *)
            __die "Error: unsupported OS version"
            ;;
    esac
}

zoomdata_enable_debian () {
    echo "Enabling zoomdata services"
    case "${debian_codename}" in
        trusty)
            for init in /etc/init.d/zoomdata-edc-* ; do
                update-rc.d "$(basename "${init}")" defaults >>/tmp/zoomdata-installer.log 2>&1
            done
            for service in $(__expand_list $SERVICES); do
                update-rc.d "$service" defaults >>/tmp/zoomdata-installer.log 2>&1
            done
            ;;
        xenial)
            zoomdata_enable_systemd
            ;;
        *)
            __die "Error: unsupported OS version"
            ;;
    esac
}

check_if_upload_service_configured () {
    grep -q '^upload\.destination\.params\.jdbc_url' /etc/zoomdata/zoomdata.properties
}

add_upload_service_configuration () {
    # Upgrade Zoomdata with missing Upload Service components configuration
    url=$(grep '^spring\.datasource\.url=' /etc/zoomdata/zoomdata.properties | cut -f 2 -d'=')
    ZOOMDATA_PG_BASE_URL="${url%/*}"
    ZOOMDATA_PG_USER=$(grep '^spring\.datasource\.username=' /etc/zoomdata/zoomdata.properties | cut -f 2 -d'=')
    zoomdata_pg_password=$(grep '^spring\.datasource\.password=' /etc/zoomdata/zoomdata.properties | cut -f 2 -d'=')

    # Preparing upload service database and configuration
    pg_upload_service_configure
    upload_configure
}

check_if_keyset_feature_configured () {
    grep -q '^keyset\.destination\.params\.jdbc_url' /etc/zoomdata/zoomdata.properties
}

add_keyset_feature_configuration () {
    # Upgrade Zoomdata with missing Keyset feature configuration
    url=$(grep '^spring\.datasource\.url=' /etc/zoomdata/zoomdata.properties | cut -f 2 -d'=')
    ZOOMDATA_PG_BASE_URL="${url%/*}"
    ZOOMDATA_PG_USER=$(grep '^spring\.datasource\.username=' /etc/zoomdata/zoomdata.properties | cut -f 2 -d'=')
    zoomdata_pg_password=$(grep '^spring\.datasource\.password=' /etc/zoomdata/zoomdata.properties | cut -f 2 -d'=')

    # Preparing keyset feature database and configuration
    pg_keyset_configure
    keyset_configure
}

zoomdata_upgrade_redhat () {
    echo "Upgrading zoomdata"
    zoomdata_install_redhat
    if ! check_if_upload_service_configured ; then
        # Upload service configuration is missing - going to configure it
        add_upload_service_configuration
    fi
    if ! check_if_keyset_feature_configured ; then
        # Keyset feature configuration is missing - going to configure it
        add_keyset_feature_configuration
    fi
    # Remove legacy services
    for package in $(__expand_list $LEGACY_SERVICES); do
        if rpm -ql "$package" >/dev/null 2>&1; then
            yum remove -y "$package" >>/tmp/zoomdata-installer.log 2>&1
        fi
    done
    # Upgrade packages
    yum upgrade --enablerepo="${ZOOMDATA_REPO_NAME}" -y 'zoomdata*' >>/tmp/zoomdata-installer.log 2>&1
}

zoomdata_upgrade_debian () {
    echo "Upgrading zoomdata"
    zoomdata_install_debian
    if ! check_if_upload_service_configured ; then
        # Upload service configuration is missing - going to configure it
        add_upload_service_configuration
    fi
    if ! check_if_keyset_feature_configured ; then
        # Keyset feature configuration is missing - going to configure it
        add_keyset_feature_configuration
    fi
    # Remove legacy services
    for package in $(__expand_list $LEGACY_SERVICES); do
        if dpkg -L "$package" >/dev/null 2>&1; then
            apt-get purge -y "$package" >>/tmp/zoomdata-installer.log 2>&1
        fi
    done
    # Upgrade packages
    apt-get install -y --only-upgrade 'zoomdata*' >>/tmp/zoomdata-installer.log 2>&1
}

generate_password () {
    echo "Generating zoomdata postgresql password"
    # Do this as late as possible to gather enough entropy from the system
    zoomdata_pg_password="$( </dev/urandom stdbuf -o0 tr -cd ':;%^&*()+\-[]_A-Z-a-z-0-9' | head --bytes 16 )"
}

save_bootstrap_log () {
    if [ -d "${INSTALL_PATH}"/logs/ ] ; then
        mv /tmp/zoomdata-installer.log "${INSTALL_PATH}/logs/zoomdata-installer.$(date +"%Y%m%d_%H%M%S").log"
    fi
}

bootstrap_redhat () {
    zoomdata_add_repo_redhat
    install_deps_redhat
    if ! rmq_detect_installed_redhat ; then
        erlang_install_redhat
        rmq_install_redhat
        rmq_enable_redhat
        rmq_start_redhat
    fi
    if zoomdata_detect_redhat ; then
        echo "Zoomdata already installed, start upgrade"
        zoomdata_stop_redhat
        zoomdata_upgrade_redhat
    else
        echo "Zoomdata not installed, start installation"
        if pg_detect_redhat_package ; then
            __die "Postgresql already installed, zoomdata installer needs empty box to proceed"
        fi
        if pg_detect_redhat_data ; then
            echo "Error: found postgresql datadir at /var/lib/pgsql/9.5/data"
            __die "Error: seems like postgres server already been installed on this box"
        fi
        zoomdata_detect_config
        pg_install_redhat
        pg_configure_redhat
        pg_start_service_redhat
        generate_password
        pg_init
        zoomdata_install_redhat
        zoomdata_configure
    fi
    zoomdata_enable_redhat
    if [ "x$skip_start" = "xfalse" ] ; then
        zoomdata_start_redhat
    fi
}

bootstrap_debian () {
    install_deps_debian
    if ! rmq_detect_installed_debian ; then
        erlang_install_debian
        rmq_add_repo_debian
        rmq_install_debian
        rmq_enable_debian
        rmq_start_debian
    fi
    if zoomdata_detect_debian ; then
        echo "Zoomdata already installed, start upgrade"
        zoomdata_stop_debian
        zoomdata_add_gpgkey_debian
        zoomdata_add_repo_debian
        zoomdata_upgrade_debian
    else
        echo "Zoomdata not installed, start installation"
        if pg_detect_debian_package ; then
            __die "Postgresql already installed, zoomdata installer needs empty box to proceed"
        fi
        zoomdata_detect_config
        pg_add_repo_debian
        pg_install_debian
        generate_password
        pg_init
        zoomdata_add_gpgkey_debian
        zoomdata_add_repo_debian
        zoomdata_install_debian
        zoomdata_configure
    fi
    zoomdata_enable_debian
    if [ "x$skip_start" = "xfalse" ] ; then
        zoomdata_start_debian
    fi
}

usage () {
    echo "Usage: $0 [OPTION]..."
    echo "Zoomdata installation script"
    echo ""
    echo "  --connectors       comma separated list of edc servers"
    echo "                     which should be installed"
    echo "                     Default: $(echo ${connectors} | tr ',' ' ')"
    echo ""
    echo "  --skip-start       skip start of all Zoomdata services"
    echo ""
    echo "  --non-interactive  skip asking to accept license agreement"
    echo ""
    echo "  --help             display this help and exit"
    echo ""
}

check_permissions
detect_distrib

while [ "x$1" != "x" ]; do
    case $1 in
        --connectors)
            shift
            connectors="$1"
            ;;
        --skip-start)
            skip_start="true"
            ;;
        --non-interactive)
            ZOOMDATA_ASK_JAVA_INSTALL="false"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

[ "${dist_arch}" = "x86_64" ] || __die "Unsupported architecture"

if $ZOOMDATA_ASK_JAVA_INSTALL >/dev/null 2>&1; then
    echo 'Zoomdata requires and will install a current version of the Oracle Java 1.8.x JRE.'
    echo 'You can visit the Oracle web site for details on the Oracle Binary Code License (BCL) for Java license.'
    printf 'Do you wish to continue with install? [Y]es/[N]o '
    read -r REPLY
    case "$REPLY" in
        [Yy])
            :
            ;;
        [Yy][Ee][Ss])
            :
            ;;
        *)
            exit 0
            ;;
    esac
fi

case "${dist_type}" in
    redhat)
        bootstrap_redhat
        ;;
    debian)
        bootstrap_debian
        ;;
    *)
        __die "Error: unsupported OS version"
        ;;
esac

save_bootstrap_log
