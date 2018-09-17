# Copyright (C) Zoomdata, Inc. 2012-2018. All rights reserved.

Supplement for streaming user activity logs from the Zoomdata host to [MySQL](https://dev.mysql.com/doc/refman/5.7/en/introduction.html). 

## Prerequisites:
* Prebuild the Docker image described in the [root of this repo](../../README.md)
* Confirm `$HELPER_ROOT` is set as described previously [in step 2](../../README.md)
* Confirm `$ZOOMDATA_INSTALL_ROOT` is set as described previously [in step 3](../../README.md)

## Configuration:

### Using an Existing MySQL Instance:
1. Connect to your MySQL instance and run [mysql_table_setup.sql](mysql_table_setup.sql). This script will create a table for each activity type logged by Zoomdata (about 21).
2. Edit [mysql-env.list](mysql-env.list) in this directory and set the variable values (described below) appropriately for your MySQL instance and save the changes. Additional detail regarding these and other available configuration options can be found on the [Fluentd documentation site](https://github.com/tagomoris/fluent-plugin-mysql).

| Variable |  Description  |  Example  |
| --- | --- | --- |
| MYSQL_HOST | MySQL host | localhost |
| MYSQL_PORT | MySQL port | 3306 |
| MYSQL_DATABASE | Database where the tables were created step 1 | mysql |
| MYSQL_USERNAME | MySQL login. Must have write access all tables created in step 1 | root |
| MYSQL_PASSWORD | Password for $MYSQL_USERNAME | my-secret-pw |

3. Start the activity log helper using the provided [helper script](helper-start-mysql.sh): `sh helper-start-mysql.sh`

### Additional Info:
[MySQL output plugin for Fluentd](https://github.com/tagomoris/fluent-plugin-mysql)

## Troubleshooting

* `docker logs zoomdata-activity-log-helper` is the best place to start.
