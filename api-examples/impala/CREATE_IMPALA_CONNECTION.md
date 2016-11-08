# Copyright (C) Zoomdata, Inc. 2012-2016. All rights reserved.

Sample Python utility for use with Zoomdata's 'Private' REST API.  Zoomdata uses the 'private API' as the REST endpoints for all AJAX calls between the Zoomdata web application and the Zoomdata server.  This API is not documented for public use, but can be used in cases where the public API does not offer the needed options, such as creating a new data source with custom SQL.  In this document and the associated sample script we examine how to create a connection in Zoomdata in addition to what is allowed by the public API.  The public API does provide a method to create a connection; see the [documentation](https://developer.zoomdata.com/2.2/docs/rest-api/#!/connection-controller/updateConnectionUsingPUT) for details on the public API.

## Connection creation in Zoomdata using the REST API
## Prerequisites:
* Developers creating a connection using the private API should be familiar with the administrative user interface in Zoomdata to create connections.  Since the private API is used by the Web application each step corresponds to an API call.
* API calls require basic authentication.  Developers will need a username and password for a Zoomdata account with administrative privileges.
* The connection details (JDBC connection string, user name, password) should be available to the user of this utility.
* For EDC based connections, the connection definition requires a `connection type ID` which should be obtained prior to running the script. To obtain the connection type ID: GET `http://<server>:<port>/<path>/service/connection/types` (Requires supervisor authentication)

### Summary
The private API requires a single a REST call to create a new connection:

* Pass the connection definition.  POST `https://<server>:<port>/<path>/service/connections` 
  _Note: the connection definition requires a `connectionTypeId` for EDC based connectors. This ID tells the connection what the parent EDC connection type will be. For legacy connectors this ID has a static value._

The Python classes provided here encapsulate this for easy use.

### Usage
The example provided here will create a new JDBC connection to a given Impala instance (cluster).

When executed, the `create_impala_connection.py` script will prompt for the following information:

* Zoomdata instance URL (i.e. https://_server_:_port_/zoomdata)
* Zoomdata administrator username (typically _admin_) and password
* JDBC connection string
* JDBC connection user and password
* Zoomdata EDC connection type ID (for EDC based connections only)
* Name for the new connection in Zoomdata


Additionally, the script prompts for debug mode which will print verbose output to the console. This output contains all of the API HTTP request/response data (including message payloads).
