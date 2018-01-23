# Copyright (C) Zoomdata, Inc. 2012-2018. All rights reserved.

Supplement for streaming user activity logs from the Zoomdata host to [Elasticsearch](https://www.elastic.co/). 

## Prerequisites:
* Prebuild the Docker image described in the [root of this repo](../../README.md)
* Confirm `$HELPER_ROOT` is set as described previously [in step 2](../../README.md)
* Confirm `$ZOOMDATA_INSTALL_ROOT` is set as described previously [in step 3](../../README.md)

## Configuration:

### Using an Existing Elasticsearch Instance:
1. Edit [es-env.list](es-env.list) in this directory and set the variable values (described below) appropriately for your Elasticsearch instance and save the changes. Additional detail regarding these and other available configuration options can be found on the [Fluentd documentation site](https://docs.fluentd.org/v1.0/articles/out_elasticsearch#).

| Variable |  Description  |  Example  | Required |
| --- | --- | --- | --- |
| ES_HOSTS | Elasticsearch nodename and its port pairs (comma-delimited). |`hosts host1:port1,host2:port2,host3:port3` OR `hosts https://customhost.com:443/path,https://username:password@host-failover.com:443` | Yes |
| ES_USER | X-Pack username | elastic | No |
| ES_PASSWORD | Password for `$ES_USER` | changeme | No |

2. Uncomment the following line in the root directory's [fluent.conf](../../fluent.conf) and save `@include outputs/elasticsearch/fluent-elasticsearch.conf` 

3. Start the activity log helper using the provided [helper script](helper-start-es.sh): `sh helper-start-es.sh`

### Additional Info:
[Elasticsearch output plugin for Fluentd](https://docs.fluentd.org/v1.0/articles/out_elasticsearch)

## Troubleshooting

* `docker logs zoomdata-activity-log-helper` is the best place to start.
