#!/usr/bin/env python
from base_classes.zoomdata_api_base import ZoomdataRequest,ZoomdataObject
import sys,json

template_directory = 'base_classes/object_templates'

class ImpalaConnection(ZoomdataObject):
    # Create a new connection to an instance of Impala
    def __init__(self, name, request, jdbc_url, connectionUser, connectionPassword, connectionTypeId=""):
        #Initialize the new connection
        self.name = name
        self.serverRequest = request
        # Set the API address
        self.apiEndpoint = request.zoomdataServer+'/service/connections'
        # Read the request payload template into this object
        self.initPayload(template_directory+"/connection/jdbc.json")
        # Populate the request payload
        self.payload["name"] = name
        self.payload["subStorageType"] = "IMPALA"
        self.payload["parameters"]["JDBC_URL"] = jdbc_url
        self.payload["parameters"]["USER_NAME"] = connectionUser 
        self.payload["parameters"]["PASSWORD"] = connectionPassword
        # Connection types are only associated with EDC2 connector servers
        if connectionTypeId == "":
            # Assume we are creating a connection with the "CORE" (legacy) connector in Zoomdata
            self.payload["connectionTypeId"] = "IMPALA_IMPALA"
            self.payload["type"] = "IMPALA"
        else:
            # Assume we are creating a connection with the an EDC2 connector server
            self.payload["connectionTypeId"] = connectionTypeId
            self.payload["type"] = "EDC2"

    def getSchemas(self):
        # Return a list of schemas found through the connection
        url = self.apiEndpoint+'/'+self.id+'/schema'
        return self.serverRequest.submit(url)

    def getCollections(self, schemaName=None):
        # Return a list of all collections(tables) found through the connection
        if schemaName is None:
            # Return a list of all collections(tables) found through the connection
            url = self.apiEndpoint+'/'+self.id+'/objects'
        else:
            # Return a list of collections(tables) in the given schema
            url = self.apiEndpoint+'/'+self.id+'/objects?schema='+schemaName
        return self.serverRequest.submit(url)

class ImpalaDatasource(ZoomdataObject):
    # Create a new datasource for a collection(table) in Impala
    def __init__(self, name, request, connectionID, collection, schema, customSQLFlag="false", connectorType="IMPALA", partitionField="",partitionBaseField=""):
        # Initialize the data source object
        self.name = name
        self.serverRequest = request
        # Set the API address
        self.apiEndpoint = request.zoomdataServer+'/service/sources'
        # Set the connection ID to be used
        self.connectionID = connectionID
        # Set the collection (table) schema
        self.schema = schema
        # Set the collection (table) to be used. This is expected to be a SQL statement when customSQLFlag is set to "true"
        self.collection = collection
        # Set customSQLFlag to "true" when collection is a SQL statement
        self.customSQLFlag = customSQLFlag
        # Read the request payload template into this object
        self.initPayload(template_directory+"/datasource/impala.json")
        # Populate the request payload
        self.payload["name"] = name
        self.payload["type"] = connectorType # Should be set to "IMPALA" for legacy connections; "EDC2" for EDC 
        self.payload["subStorageType"] = "IMPALA" # Not necessary for core connectors, but doesn't hurt
        self.payload["storageConfiguration"]["collection"] = collection
        self.payload["storageConfiguration"]["schema"] = schema 
        self.payload["storageConfiguration"]["connectionId"] = connectionID
        self.payload["storageConfiguration"]["collectionParams"]["CUSTOM_SQL"] = customSQLFlag
        # Set the time partition field
        self.partitionField = partitionField.lower()
        # Set the time partition field and base field at the source level
        if partitionField != "" and partitionBaseField != "":
            self.payload["storageConfiguration"]["partitions"] = json.loads('{"'+partitionBaseField+'": {"field": "'+partitionField+'"} }')
            print "+ Time partition configured for "+partitionField+" based on "+partitionBaseField

    def create(self):
        # Overrides create() in the inherited ZoomdataObject (parent)
        # Create the datasource in Zoomdata and record the assigned ID
        stepCount = 0
        print "+ Creating datasource "+self.name+" for collection "+self.collection
        try:
            # Initialize fields metadata for the given collection (table)
            # Includes basic field metadata: datatype, etc
            self.__constructFields__()
            stepCount += 1 #1
            # Construct fields metadata for the given collection (table)
            # Includes detailed field properties: min/max values, etc
            self.__constructFields__('/construct')
            stepCount += 1 #2
            # Initialize the datasource definition
            dataSource = self.__initializeDataSource__()
            # Capture the datasource ID
            self.id = dataSource['id']
            stepCount += 1 #3
            # Finalize and create the datasource definition with visualization defaults
            self.__finalizeDataSource__(dataSource)
            stepCount += 1 #4
            print "+ Data source "+self.name+" successfully created"
        except:
            print "- Data source for collection "+self.collection+" could not be created" 
            print "- Last step completed: "+str(stepCount)
            e = sys.exc_info()
            print "- "+str(e)

    def __constructFields__(self,endpoint=""):
        url = self.apiEndpoint+'/fields'+endpoint
        fields = self.submit(url)

        if self.partitionField != "":
            for field in fields:
                if field["name"].lower() == self.partitionField:
                    field["storageConfig"]["metaFlags"] = ["PLAYABLE","PARTITION"]

        self.payload['objectFields'] = fields


    def __initializeDataSource__(self):
        # Return the initial datasource definition from Zoomdata
        # Populate payload
        self.payload["playbackMode"] = False
        self.payload["timeFieldName"] = "none"
        self.payload["visualizations"] = json.loads('[]')
        self.payload["textSearchEnabled"] = False
        self.payload["cacheable"] = False
        self.payload["controlsCfg"] = None
        self.payload["formulas"] = json.loads('[]')
        self.payload["isConnectionValid"] = True
        self.payload["volumeMetric"] = json.loads('{"label": "Volume","name": "count","storageConfig": {},"type": "NUMBER","visible": true}')

        return self.submit()

    def __finalizeDataSource__(self, data):
        # if time partition field is defined, then set it as the global time attribute
        if self.partitionField != "":
            data["controlsCfg"]["timeControlCfg"]["timeField"] = self.partitionField

        # Pass datasource definition back to Zoomdata. Visualization defaults will be set
        url = self.apiEndpoint+'/'+self.id
        return self.serverRequest.submit(url,data=json.dumps(data),lmda='PATCH')
