#!/usr/bin/env python
from zoomdata_api_base import ZoomdataRequest,ZoomdataObject
import sys,json

template_directory = 'object_templates'

class ImpalaConnection(ZoomdataObject):
    # Create a new connection to an instance of Impala
    def __init__(self, name, request, jdbc_url, connectionUser, connectionPassword, connectionTypeId=None):
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
        if connectionTypeId is None:
            # Assume we are creating a connection with the "CORE" (legacy) connector in Zoomdata
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
    def __init__(self, name, request, connectionID, collection, schema, customSQLFlag="false"):
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
        self.payload["type"] = "IMPALA"
        self.payload["subStorageType"] = "IMPALA" # Not necessary for core connectors, but doesn't hurt
        self.payload["storageConfiguration"]["collection"] = collection
        self.payload["storageConfiguration"]["schema"] = schema 
        self.payload["storageConfiguration"]["connectionId"] = connectionID
        self.payload["storageConfiguration"]["collectionParams"]["CUSTOM_SQL"] = customSQLFlag

    def create(self):
        # Overrides create() in the inherited ZoomdataObject (parent)
        # Create the datasource in Zoomdata and record the assigned ID
        stepCount = 0
        print "Creating datasource "+self.name+" for collection "+self.collection
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
            print "- Data source "+self.name+" successfully created"
        except:
            print "* Data source for collection "+self.collection+" could not be created" 
            print "* Last step completed: "+str(stepCount)
            e = sys.exc_info()
            print e

    def __constructFields__(self,endpoint=""):
        url = self.apiEndpoint+'/fields'+endpoint
        #data = json.dumps(self.payload)
        #print data
        self.payload['objectFields'] = self.submit(url)
        #self.payload['objectFields'] = json.loads(self.serverRequest.submit(url,data=data))

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

        #data = json.dumps(self.payload)
        #print data
        return self.submit()
        #return self.serverRequest.submit(url,data=data)

    def __finalizeDataSource__(self, data):
        # Pass datasource definition back to Zoomdata. Visualization defaults will be set
        url = self.apiEndpoint+'/'+self.id
        return self.serverRequest.submit(url,data=json.dumps(data),lmda='PATCH')

    def delete(self):
        # Delete the given datasource in Zoomdata
        url = self.apiEndpoint+'/'+self.id
        return self.serverRequest.submit(url,lmda='DELETE')
