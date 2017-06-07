# Copyright (C) Zoomdata, Inc. 2012-2017. All rights reserved.

Sample Bash script for deploying Zoomdata 2.3+ from tarball packaging. This script is most useful for situations where the user deploying Zoomdata does not have root or sudo access on the host OS.

## Prerequisites:
* Zoomdata components in tarball packaging (provided by your Zoomdata representative)
* Java 1.8 installed or available via `$JAVA_HOME` on the Zoomdata host
* Max open file limit adjusted for the OS user running the Zoomdata processes: http://docs.zoomdata.com/installation-prerequisites
* An accessible Postgresql 9.5 instance with a Zoomdata user account and databases setup: http://docs.zoomdata.com/install-and-set-up-zoomdata-metadata-store
* [OPTIONAL] Install Firefox to enable screenshotting of Zoomdata dashboards/visualizations: http://docs.zoomdata.com/post-installation-options

## Overview
This manager script provides the following functions:

1. Deployment
1.1. Creates a `./zoomdata` directory within the `INSTALL_DIR`
1.1. Unpacks all Zoomdata components to the `./zoomdata` directory
1. Zoomdata Process Management
1.1. Start an individual or all Zoomdata processes in the background
1.1. Stop an individual or all Zoomdata processes
1.1. Restart an individual or all Zoomdata processes in the background
1.1. Status of an individual or all running Zoomdata processes

## Usage

1. Copy the Zoomdata tarballs and [the manager script](zoomdata-process-manager.sh) to the same directory on the host
1. Edit the following variables in the helper script according to the environment

    | Variable | Description | Default |
    | ------------- | ------------- | ------------- |
    | PG_HOST | Postgres host | localhost |
    | PG_PORT | Postgres port | 5432 |
    | PG_USER | Postgres connection user name | zoomdata |
    | PG_PASSWORD | Postgres connection user password | password |
    | PG_ZOOMDATA_DB | Zoomdata metadata schema in Postgres| zoomdata |
    | PG_SCHEDULER_DB | Zoomdata-scheduler metadata schema in Postgres| zoomdata-scheduler |
1. Execute the script with one of the following options.

    | Function | Command |
    | ------------- | ------------- |
    | Deployment | `./zoomdata-tarball-manager.sh deploy` |
    | Start All Processes | `./zoomdata-tarball-manager.sh start` |
    | Stop All Processes | `./zoomdata-tarball-manager.sh stop` |
    | Restart All Processes | `./zoomdata-tarball-manager.sh restart` |
    | Start a Single Process | `./zoomdata-tarball-manager.sh start <process>` |
    | Stop a Single Process | `./zoomdata-tarball-manager.sh stop <process>` |
    | Restart a Single Process | `./zoomdata-tarball-manager.sh restart <process>` |

    Note: the single process functions accept the following process 
