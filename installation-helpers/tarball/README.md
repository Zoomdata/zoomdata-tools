# Copyright (C) Zoomdata, Inc. 2012-2017. All rights reserved.

Sample Bash script for deploying Zoomdata 2.3+ from tarball packaging. This script is most useful for situations where the user deploying Zoomdata does not have root or sudo access on the host OS.

## Prerequisites:
* Zoomdata components in tarball packaging (provided by your Zoomdata representative)
* Java 1.8 installed or available via `$JAVA_HOME` on the Zoomdata host
* Max open file limit adjusted for the OS user running the Zoomdata processes: http://docs.zoomdata.com/installation-prerequisites
* An accessible Postgresql 9.5 instance with a Zoomdata user account and databases setup: http://docs.zoomdata.com/install-and-set-up-zoomdata-metadata-store
* [OPTIONAL] Install Firefox to enable screenshotting of Zoomdata dashboards/visualizations: http://docs.zoomdata.com/post-installation-options

## Overview
This helper script

1. creates a `./zoomdata` directory within the `INSTALL_DIR`
1. unpacks all Zoomdata components to the `./zoomdata` directory
1. starts all Zoomdata component processes in the background

## Usage

1. Copy the Zoomdata tarballs and [the helper script](zoomdata-tarball-deployment.sh) to the same directory on the host
1. Edit the following variables in the helper script according to the environment

    | Variable | Description | Default |
    | ------------- | ------------- | ------------- |
    | PG_HOST | Postgres host | localhost |
    | PG_PORT | Postgres port | 5432 |
    | PG_USER | Postgres connection user name | zoomdata |
    | PG_PASSWORD | Postgres connection user password | password |
    | PG_ZOOMDATA_DB | Zoomdata metadata schema in Postgres| zoomdata |
    | PG_SCHEDULER_DB | Zoomdata-scheduler metadata schema in Postgres| zoomdata-scheduler |
1. Execute the script - `./zoomdata-tarball-deployment.sh`

