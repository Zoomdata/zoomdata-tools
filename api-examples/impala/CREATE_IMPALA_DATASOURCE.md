# Copyright (C) Zoomdata, Inc. 2012-2017. All rights reserved.

Sample Python utility for use with Zoomdata's 'Private' REST API.  Zoomdata uses the 'private API' as the REST endpoints for all AJAX calls between the Zoomdata web application and the Zoomdata server.  This API is not documented for public use, but can be used in cases where the public API does not offer the needed options, such as creating a new data source with custom SQL.  In this document and the associated sample script we examine how to create a data source in Zoomdata that has more complex settings than allowed by the public API.  The public API does provide a method to create a data source; see the [documentation](https://developer.zoomdata.com/2.2/docs/rest-api/#!/sources/createUsingPOST_5) for details on the public API.

## Data Source creation in Zoomdata using the REST API
### Prerequisites:
* Developers creating a data source using the private API should be familiar with the administrative user interface in Zoomdata to create data sources.  Since the private API is used by the Web application each step corresponds to an API call.
* API calls require basic authentication.  Developers will need a username and password for a Zoomdata account with administrative privileges.
* The Zoomdata server should already be configured with the connector for the data source, such as the EDC connector for Impala.  The API calls require the connection ID.

_**Note:** Connection IDs can be obtained from the Zoomdata UI by clicking on **Manage Connections** from the **Sources** page. Select the desired connection and observe the ID appended to the URL: (https://server:port/zoomdata/admin.html#connections/**connectionID**)_

*  The connection details (JDBC connection string, user name, etc.) should already be defined in Zoomdata.  To define connection details, log in as an account with administrative rights.  Go to the 'Sources' page and click 'Manage Connections'.  If the data connection is not listed then create, including the JDBC URL, user, password, and any other information required by the connection.

### Summary
The private API follows a series of steps to create a data source; information retrieved from one step is used in subsequent steps to configure the source.  For a given collection (table), datasources are created in four synchronous REST API calls that

1. Initialize the collection's metadata for its fields.  POST `https://<server>:<port>/<path>/service/source/fields` 
  _Note: this request payload contains the collection's schema name, collection name, and Zoomdata connection ID_
1. Construct the fields' metadata properties. POST `https://<server>:<port>/<path>/service/source/fields/construct`
1. Initialize the Zoomdata datasource definition, incorporating the fields' metadata. POST `https://<server>:<port>/<path>/service/source`
1. Finalize the datasource definition with visualization defaults PATCH `https://<server>:<port>/<path>/service/source/
Optionally, the defaults for the visualizations can be overridden by customizing the visualization collection and re-invoking the POST statement to create the data source.  Obtain the visualization and other source settings by calling `https://<server>:<port>/<path>/service/sources/<sourceId>`

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


Additionally, the script prompts for debug mode which will print verbose output to the console. This output contains all of the API HTTP request/response data (including message payloads).
