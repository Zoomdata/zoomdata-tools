# Copyright (C) Zoomdata, Inc. 2012-2019. All rights reserved.

Sample Bash script for deploying Zoomdata 2.3 to 2.5 from tarball packaging. This script is most useful for situations where the user deploying Zoomdata does not have root or sudo access on the host OS.

## Prerequisites:
* Zoomdata components in tarball packaging (provided by your Zoomdata representative)
* Java 1.8 installed or available via `$JAVA_HOME` on the Zoomdata host
* Max open file limit adjusted for the OS user running the Zoomdata processes: https://www.zoomdata.com/docs/2.5/installation-prerequisites.html
* An accessible Postgresql 9.5 instance with a Zoomdata user account and databases setup: http://docs.zoomdata.com/2.5/install-and-set-up-zoomdata-metadata-store
* [OPTIONAL] Install Firefox to enable screenshotting of Zoomdata dashboards/visualizations: https://www.zoomdata.com/docs/2.5/post-installation-options.html

## Overview
This manager script provides the following functions:

#### Deployment
1. Creates a `./zoomdata` directory within the `INSTALL_DIR`
1. Unpacks all Zoomdata components to the `./zoomdata` directory

#### Zoomdata Process Management
1. Start an individual or all Zoomdata processes in the background
1. Stop an individual or all Zoomdata processes
1. Restart an individual or all Zoomdata processes in the background
1. Status of an individual or all running Zoomdata processes

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
    | Deployment | `./zoomdata-process-manager.sh deploy` |
    | Start All Processes | `./zoomdata-process-manager.sh start` |
    | Stop All Processes | `./zoomdata-process-manager.sh stop` |
    | Restart All Processes | `./zoomdata-process-manager.sh restart` |
    | Start a Single Process | `./zoomdata-process-manager.sh start <process>` |
    | Stop a Single Process | `./zoomdata-process-manager.sh stop <process>` |
    | Restart a Single Process | `./zoomdata-process-manager.sh restart <process>` |

    *Note:* the single process functions above accept the following process names in lowercase

    | Process Name | Description |
    | ------------- | ------------- |
    | consul | Zoomdata service registry |
    | zoomdata-edc-`*` | Zoomdata connectors. Replace `*` with the connector executable name from `zoomdata/bin` |
    | zoomdata-scheduler | Zoomdata's metadata refresh scheduler |
    | zoomdata-spark-proxy | Provides the in-memory flatfile cache for [SparkIt](https://www.zoomdata.com/docs/2.5/how-zoomdata-caches-the-data.html) |
    | zoomdata | Core application |
