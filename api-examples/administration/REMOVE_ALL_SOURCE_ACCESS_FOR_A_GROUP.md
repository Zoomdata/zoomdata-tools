# Copyright (C) Zoomdata, Inc. 2012-2019. All rights reserved.

Sample Python utility for use with Zoomdata's 'Private' REST API.  Zoomdata uses the 'private API' as the REST endpoints for all AJAX calls between the Zoomdata web application and the Zoomdata server.  This API is not documented for public use, but can be used in cases where the public API does not offer the needed options.  The public API does provide methods to manage user groups; see the [documentation](https://developer.zoomdata.com/2.5/docs/rest-api/) for details on the public API.

## User-Group data source permissions removal in Zoomdata using scripted REST API calls
### Summary
The script provided here will read the provided `User-Group List` and remove that group's access to all data sources.


### Configuration
The `remove_group_datasource_permissions.py` script requires configuration in two files outlined below


##### Zoomdata Server
The script requires the following information about your Zoomdata instance to be configured in conf/zoomdata-server.json. Edit the zoomdata-server.json file included in this repository to reflect your server instance information.

| Parameter |  Description  |
| --- | --- |
| URL | Base HTTP(S) address of the Zoomdata application. For example `http://localhost:8080/zoomdata`|
| AdminUserName | Administrative user the script will use to access Zoomdata and create objects |
| AdminPassword | Password for the AdminUserName |
| zoomdataAccountID | Can be obtained by going to `http://<zoomdata-instance>:<zoomdata-port>/zoomdata/admin.html#accounts` and selecting the appropriate account. The numeric account ID will be appended to the URL in your address bar |
| debugMode | `yes` or `no`; Setting to `yes` will print verbose output to the console. This output contains all of the API HTTP request/response data (including message payloads). |


##### User-Group to Data Source Mapping
The script requires a CSV file input with the following column identifiy the User-Groups by name. 

| Column |  Required  |  Description  |
| --- | --- | --- |
| group | Yes | User-group in Zoomdata. Must be an exact match to the user group name in Zoomdata (case-sensitive) |

A sample of this CSV file is provided with this project and can be modified to fit your needs: `conf/sample-groups.csv`


### Usage
The script requires a single argument for the `User-Group List` file location. For example:

`python load_zoomdata_security_model.py conf/sample-groups.csv`
