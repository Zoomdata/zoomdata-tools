# Copyright (C) Zoomdata, Inc. 2012-2016. All rights reserved.

Sample Python utilities for use with Zoomdata's 'Private' REST API.  Zoomdata uses the 'private API' as the REST endpoints for all AJAX calls between the Zoomdata web application and the Zoomdata server.  This API is not documented for public use, but can be used in cases where the public API does not offer the needed options, such as creating a new data source with custom SQL.  In this document and the associated sample script we examine how to create a data source in Zoomdata that has more complex settings than allowed by the public API.  The public API does provide a method to create a data source; see the [documentation](https://developer.zoomdata.com/2.2/docs/rest-api/#!/sources/createUsingPOST_5) for details on the public API.

## General Prerequisites:
* Developers creating Zoomdata objects using the private API should be familiar with the administrative user interface in Zoomdata to create these objects.  Since the private API is used by the Web application each step corresponds to an API call.
* API calls require basic authentication.  Developers will need a username and password for a Zoomdata account with administrative privileges.

## API Samples Currently Available:
* [Connection Creation](CREATE_IMPALA_CONNECTION.md)
* [Data Source Creation](CREATE_IMPALA_DATASOURCE.md)
