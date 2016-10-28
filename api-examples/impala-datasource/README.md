# Copyright (C) Zoomdata, Inc. 2012-2016. All rights reserved.

Sample Python utility for use with Zoomdata's REST API

## Data Source Creation in Zoomdata using the REST API
### Summary
For a given collection (table), datasources are created in four synchronous REST API calls that

1. Initialize the collection's metadata for its fields
1. Construct the fields' metadata properties
1. Initialize the Zoomdata datasource definition, incorporating the fields' metadata
1. Finalize the datasource definition with visualization defaults

The Python classes provided here encapsulate these for easy use.
### Usage
The example provided here will create a new datasource for an Impala collection (table) using an existing Impala connection in Zoomdata.

When executed, the `create_impala_data_source.py` script will prompt for the following information:

* Zoomdata instance URL (i.e. https://_server_:_port_/zoomdata)
* Zoomdata administrator username (typically _admin_) and password
* Zoomdata Impala connection ID
* Impala schema
* Impala collection (table) name OR custom SQL statement
* Name for the new datasource in Zoomdata

_**Note:** Connection IDs can be obtained from the Zoomdata UI by clicking on **Manage Connections** from the **Sources** page. Select the desired connection and observe the ID appended to the URL: (https://server:port/zoomdata/admin.html#connections/**connectionID**)_

Additionally, the script prompts for debug mode which will print verbose output to the console. This output contains all of the API HTTP request/response data (including message payloads).
