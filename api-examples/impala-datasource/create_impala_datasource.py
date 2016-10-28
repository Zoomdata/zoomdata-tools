#!/usr/bin/env python
from zoomdata_api_base import ZoomdataRequest
from zoomdata_api_impala import ImpalaDatasource

zoomdataBaseURL = raw_input("Enter the Zoomdata instance URL (https://<server>:<port>/zoomdata): ")
adminUser = raw_input("Enter the Zoomdata administrator username (typically 'admin'): ")
adminPassword = raw_input("Enter the password for the Zoomdata administrator: ")

connectionID = raw_input("Enter the Zoomdata connection ID to use: ")
collectionName = raw_input("Enter the Impala collection name, or custom SQL statement: ")
customSQL = raw_input("Did you enter a custom SQL statement in the previous step? (yes or no): ")
if customSQL.lower() == "yes":
  customSQLFlag = "true"
else:
  customSQLFlag = "false"
schemaName = raw_input("Enter the Impala schema name that contains the collection: ")
debug = raw_input("Do you want to enable verbose output (debug mode; prints all API request data to the console)? (yes or no): ")
sourceName = raw_input("Finally, enter a name for the new datasource: ")

# Create the Zoomdata server request
zoomdataServerRequest = ZoomdataRequest(zoomdataBaseURL, adminUser, adminPassword)
# Enable verbose output if desired
if debug.lower() == "yes":
  zoomdataServerRequest.enableDebug()

# Initialize the source object
source = ImpalaDatasource(sourceName, zoomdataServerRequest, connectionID, collectionName, schemaName, customSQLFlag)
# Finally, create the source in Zoomdata
source.create()
# Uncomment the line below to delete the datasource after creation (for testing purposes)
#source.delete()
# Return the Zoomdata source id of the newly created source
print "source: "+source.id