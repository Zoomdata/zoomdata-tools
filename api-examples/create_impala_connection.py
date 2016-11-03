#!/usr/bin/env python
from base_classes.zoomdata_api_base import ZoomdataRequest
from base_classes.zoomdata_api_impala import ImpalaConnection

zoomdataBaseURL = raw_input("Enter the Zoomdata instance URL (https://<server>:<port>/zoomdata): ")
adminUser = raw_input("Enter the Zoomdata administrator username (typically 'admin'): ")
adminPassword = raw_input("Enter the password for the Zoomdata administrator: ")

jdbc_url = raw_input("Enter the JDBC connection string for your Impala instance (i.e. jdbc:hive2://<server>:<port>/;auth=noSasl): ")
connectionUser = raw_input("Enter the connection username (optional): ")
if connectionUser != "":
  connectionPassword = raw_input("Enter the connection user's password (optional): ")
else:
  connectionPassword = ""
connectorTypeInput = raw_input("Is this connector an EDC? (yes or no): ")
if connectorTypeInput.lower() == "yes":
  connectionTypeID = raw_input("Enter the connection type ID (required for EDC): ")
else:
  connectionTypeID = ""
debug = raw_input("Do you want to enable verbose output (debug mode; prints all API request data to the console)? (yes or no): ")
connectionName = raw_input("Finally, enter a name for the new connection: ")

# Create the Zoomdata server request
zoomdataServerRequest = ZoomdataRequest(zoomdataBaseURL, adminUser, adminPassword)
# Enable verbose output if desired
if debug.lower() == "yes":
  zoomdataServerRequest.enableDebug()
# Initialize the connection object
connection = ImpalaConnection(connectionName, zoomdataServerRequest, jdbc_url, connectionUser, connectionPassword, connectionTypeID)
# Finally, create the connection in Zoomdata
connection.create()
# Return the Zoomdata connection id of the newly created connection
print "connection: "+connection.id
# Uncomment the line below to delete the connection after creation (for testing purposes)
#connection.delete()
