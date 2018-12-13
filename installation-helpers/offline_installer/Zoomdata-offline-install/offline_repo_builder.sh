#!/bin/bash

#Make a dir to hold the repo
mkdir -p ./yum-local/Packages/

#Zoomdata Core
wget  -P ./yum-local/Packages/  http://repo.zoomdata.com/3.7/yum/redhat/7/x86_64/stable/zoomdata-3.7.1-22.el7.stable.x86_64.rpm
wget  -P ./yum-local/Packages/  http://repo.zoomdata.com/3.7/yum/redhat/7/x86_64/stable/zoomdata-consul-3.7.0-2.el7.stable.x86_64.rpm
wget  -P ./yum-local/Packages/  http://repo.zoomdata.com/3.7/yum/redhat/7/x86_64/stable/zoomdata-query-engine-3.7.1-22.el7.stable.noarch.rpm
wget  -P ./yum-local/Packages/  http://repo.zoomdata.com/3.7/yum/redhat/7/x86_64/stable/zoomdata-scheduler-3.7.1-22.el7.stable.noarch.rpm
wget  -P ./yum-local/Packages/  http://repo.zoomdata.com/3.7/yum/redhat/7/x86_64/stable/zoomdata-stream-writer-postgresql-3.7.0-2.el7.stable.noarch.rpm
wget  -P ./yum-local/Packages/  http://repo.zoomdata.com/3.7/yum/redhat/7/x86_64/stable/zoomdata-upload-service-3.7.0-2.el7.stable.noarch.rpm
wget  -P ./yum-local/Packages/  http://repo.zoomdata.com/3.7/yum/redhat/7/x86_64/stable/zoomdata-screenshot-service-3.7.0-1.el7.stable.noarch.rpm
wget  -P ./yum-local/Packages/  http://repo.zoomdata.com/tools/yum/redhat/7/x86_64/stable/zoomdata-zdmanage-1.0.0-stable.noarch.rpm


#EDCs (assuming they'll only want Impala, cloudera search and possibly postgres since it's needed to enable file upload)
wget  -P ./yum-local/Packages/  http://repo.zoomdata.com/3.7/yum/redhat/7/x86_64/stable/zoomdata-edc-cloudera-search-3.7.1-4.el7.stable.noarch.rpm
wget  -P ./yum-local/Packages/  http://repo.zoomdata.com/3.7/yum/redhat/7/x86_64/stable/zoomdata-edc-impala-3.7.1-4.el7.stable.noarch.rpm
wget  -P ./yum-local/Packages/  http://repo.zoomdata.com/3.7/yum/redhat/7/x86_64/stable/zoomdata-edc-postgresql-3.7.1-4.el7.stable.noarch.rpm

#Postgres
wget  -P ./yum-local/Packages/  https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/postgresql95-server-9.5.15-1PGDG.rhel7.x86_64.rpm
wget  -P ./yum-local/Packages/  https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/postgresql95-libs-9.5.15-1PGDG.rhel7.x86_64.rpm
wget  -P ./yum-local/Packages/  https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/postgresql95-9.5.15-1PGDG.rhel7.x86_64.rpm
wget  -P ./yum-local/Packages/  https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/pgdg-redhat95-9.5-3.noarch.rpm

#Others
wget  -P ./yum-local/Packages/  http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/c/createrepo_c-0.10.0-6.el7.x86_64.rpm
wget  -P ./yum-local/Packages/  https://dl.bintray.com/rabbitmq/all/rabbitmq-server/3.7.5/rabbitmq-server-3.7.5-1.el7.noarch.rpm

#erlang:
wget  -P ./yum-local/Packages/  https://packages.erlang-solutions.com/erlang/esl-erlang/FLAVOUR_1_general/esl-erlang_20.3-1~centos~7_amd64.rpm
wget  -P ./yum-local/Packages/  https://github.com/rabbitmq/erlang-rpm/releases/download/v20.3.6/erlang-20.3.6-1.el7.centos.x86_64.rpm 

#epel:
wget  -P ./yum-local/Packages/  https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

#socat:
wget  -P ./yum-local/Packages/ https://forensics.cert.org/centos/cert/7/x86_64/socat-1.7.3.2-1.1.el7.x86_64.rpm 

#openssl-libs:
wget  -P ./yum-local/Packages/  http://mirror.centos.org/centos/7/os/x86_64/Packages/openssl-libs-1.0.2k-16.el7.x86_64.rpm

#openssl-server:
wget  -P ./yum-local/Packages/  http://mirror.centos.org/centos/7/os/x86_64/Packages/openssl-1.0.2k-16.el7.x86_64.rpm

tar zcpf zoom_install.tgz -P ./yum-local/
