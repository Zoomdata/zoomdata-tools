# Copyright (C) Zoomdata, Inc. 2012-2018. All rights reserved.

Sample Python utility for use with Zoomdata's 'Private' REST API.  Zoomdata uses the 'private API' as the REST endpoints for all AJAX calls between the Zoomdata web application and the Zoomdata server.  This API is not documented for public use, but can be used in cases where the public API does not offer the needed options, such as creating a new data source with custom SQL.  In this document and the associated sample script we examine how to create a data source and user-group in Zoomdata, then assign a set of access permissions for the data source to the user-group.  The public API does provide methods to create data sources and user groups; see the [documentation](https://developer.zoomdata.com/2.5/docs/rest-api/) for details on the public API.

## Data Source creation with User-Group security in Zoomdata using scripted REST API calls
### Prerequisites:

* Developers creating a data source using the private API should be familiar with the administrative user interface in Zoomdata to create data sources.  Since the private API is used by the Web application each step corresponds to an API call.
* API calls require basic authentication.  Developers will need a username and password for a Zoomdata account with administrative privileges.
* The Zoomdata server should already be configured with a connection to the data source, such as the EDC connector for Impala.  The API calls require the connection ID.

_**Note:** Connection IDs can be obtained from the Zoomdata UI by clicking on **Manage Connections** from the **Sources** page. Select the desired connection and observe the ID appended to the URL: (https://server:port/zoomdata/admin.html#connections/**connectionID**)_

*  The connection details (JDBC connection string, user name, etc.) should already be defined in Zoomdata.  To define connection details, log in as an account with administrative rights.  Go to the 'Sources' page and click 'Manage Connections'.  If the data connection is not listed then create, including the JDBC URL, user, password, and any other information required by the connection.


### Summary
The script provided here will read the provided `User-Group to Data Source Mapping` and perform the following actions for each record found in the file:
*  Check that the `zoomdata_source_name` data source exists in Zoomdata. If the source does not exist, a new one will be created using the Impala connection configured in `conf/zoomdata-server.json`.
*  Check that the `group` user-group exists in Zoomdata. If the group exists, data source access permissions will be reset. If the user-group does not exist, a new one will be created. 
* Add data source access permissions to the user-group


### Configuration
The `load_zoomdata_security_model.py` script requires configuration in two files outlined below

##### Zoomdata Server
The script requires the following information about your Zoomdata instance to be configured in conf/zoomdata-server.json. Edit the zoomdata-server.json file included in this repository to reflect your server instance information.

| Parameter |  Description  |
| --- | --- |
| URL | Base HTTP(S) address of the Zoomdata application. For example `http://localhost:8080/zoomdata`|
| AdminUserName | Administrative user the script will use to access Zoomdata and create objects |
| AdminPassword | Password for the AdminUserName |
| ImpalaConnectionID | Can be obtained by going to `http://<zoomdata-instance>:<zoomdata-port>/zoomdata/admin.html#connections` and selecting the appropriate connection. The numeric connection ID will be appended to the URL in your address bar|
| zoomdataAccountID | Can be obtained by going to `http://<zoomdata-instance>:<zoomdata-port>/zoomdata/admin.html#accounts` and selecting the appropriate account. The numeric account ID will be appended to the URL in your address bar |
| debugMode | `yes` or `no`; Setting to `yes` will print verbose output to the console. This output contains all of the API HTTP request/response data (including message payloads). |


##### User-Group to Data Source Mapping
The script requires a CSV file input with the following columns to setup the Data Sources, User-Groups, and configure the appopriate access between the two. Note that the file can contain additional columns, but it should minimally have the columns noted as `Required` below (order does not matter). 

| Column |  Required  |  Description  |
| --- | --- | --- |
| db | Yes | Impala schema name |
| table_name | Yes | Impala table (collection) name |
| group | Yes | User-group in Zoomdata. Must be an exact match to an Active Directory group or SAML attribute when creating groups that Active Directory or SAML authenticated users will auto-join |
| zoomdata_source_name | Yes | What to name the source in Zoomdata (usually the same as the `table_name`) |
| time_partition_field | No | Field (single) that the Impala table has been partitioned by |
| time_partition_base_field | No | High-cardinality time field that the `time_partition_field` is derived from |

A sample of this CSV file is provided with this project and can be modified to fit your needs: `conf/sample-roles.csv`


### Usage
The script requires a single argument for the `User-Group to Data Source Mapping` file location. For example:

`python load_zoomdata_security_model.py conf/sample-roles.csv`
