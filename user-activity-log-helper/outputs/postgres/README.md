# Copyright (C) Zoomdata, Inc. 2012-2018. All rights reserved.

Supplement for streaming user activity logs from the Zoomdata host to [PostgreSQL 9.5](https://www.postgresql.org/). 

## Prerequisites:
* Prebuild the Docker image described in the [root of this repo](../../README.md)
* Confirm `$HELPER_ROOT` is set as described previously [in step 2](../../README.md)
* Confirm `$ZOOMDATA_INSTALL_ROOT` is set as described previously [in step 3](../../README.md)

## Configuration:

### Using an Existing PostgreSQL Instance:
1. Connect to your PostgreSQL instance and run [table_setup.sql](table_setup.sql). This script will create a table for each activity type logged by Zoomdata (about 21). _Note: it is recommended to use a separate database from Zoomdata's metastore._
2. Edit [pg-env.list](pg-env.list) in this directory and set the variable values (described below) appropriately for your PostgreSQL instance and save the changes.

| Variable |  Description  |  Example  |
| --- | --- | --- |
| PG_HOST | PostgreSQL host | localhost |
| PG_PORT | PostgreSQL port | 5432 |
| PG_DATABASE | Database where created the tables in step 1 | zoomdata_logs |
| PG_USERNAME | PostgreSQL login. Must have write access all tables created in step 1 | zoomdata_logs |
| PG_PASSWORD | Password for the PG_USERNAME login | Changeit! |

3. Uncomment the following line in the root directory's [fluent.conf](../../fluent.conf) and save `@include outputs/postgres/fluent-postgres.conf` 

4. Start the activity log helper using the provided [helper script](helper-start-pg.sh): `sh helper-start-pg.sh`

### Additional Info:
[PostgreSQL output plugin for Fluentd](https://github.com/uken/fluent-plugin-postgres)

## Troubleshooting

* `docker logs zoomdata-activity-log-helper` is the best place to start.
