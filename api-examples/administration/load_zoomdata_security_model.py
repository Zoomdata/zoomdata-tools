#!/usr/bin/env python
from base_classes.zoomdata_api_base import ZoomdataRequest
from base_classes.zoomdata_api_impala import ImpalaDatasource
import sys,csv,json

def main():
  #load the Zoomdata instance info and credentials
  with open('conf/zoomdata-server.json') as data_file:
    zoomdataInfo = json.load(data_file)

  #set local Zoomdata instance info
  zoomdataBaseURL = zoomdataInfo["URL"]
  adminUser = zoomdataInfo["AdminUserName"]
  adminPassword = zoomdataInfo["AdminPassword"]
  zoomdataAccountID= zoomdataInfo["zoomdataAccountID"]
  ImpalaConnection = zoomdataInfo["ImpalaConnectionID"]
  debug = zoomdataInfo["debugMode"]

  #create the Zoomdata request object
  zoomdataServerRequest = ZoomdataRequest(zoomdataBaseURL, adminUser, adminPassword)
  # Enable verbose output if desired
  if debug.lower() == "yes":
    zoomdataServerRequest.enableDebug()

  resetGroupList = []

  #begin parsing the IDM Role configuration file; Its assumed this file has a column name header; Rows are processed one at a time
  roleConfigFile = sys.argv[1]
  rowCounter = 1

  with open(roleConfigFile, 'rU') as csvfile:
    print("-- Reading from "+roleConfigFile+" --")
    reader = csv.DictReader(csvfile)
    for row in reader:
      print("----------------------------------------")
      print("-- Processing row #"+str(rowCounter)+" --")
      #retrieve a list of available data source names in Zoomdata
      currentSources = json.loads(zoomdataServerRequest.submit(zoomdataBaseURL+'/service/sources?fields=name'))
      #retrieve a list of available user groups in Zoomdata
      currentGroups = json.loads(zoomdataServerRequest.submit(zoomdataBaseURL+'/service/groups?accountId='+zoomdataAccountID))

      groupID = None
      sourceID = None

      schemaName = row['db']
      tableName = row['table_name']
      adGroup = row['group']
      sourceName = row['zoomdata_source_name']
      partitionField = row['time_partition_field']
      partitionBaseField = row['time_partition_base_field'] #field that the partitionField is based on
      #Look up the source by name in the currently configured source list
      try:
        sourceID = [x for x in currentSources if x["name"] == sourceName][0]['id']
      except IndexError:
        sourceID = None

      #create the data source if doesn't already exist
      if sourceID is None:
        # Initialize the source object
        newSource = ImpalaDatasource(sourceName, zoomdataServerRequest, ImpalaConnection, tableName, schemaName,partitionField=partitionField,partitionBaseField=partitionBaseField)
        # Create the source in Zoomdata
        newSource.create()
        sourceID = newSource.id

      #Look up the group by name in the currently configured group list
      try:
        groupID = [x for x in currentGroups if x["label"] == adGroup][0]['id']
      except IndexError:
        groupID = None

      #create the AD group in Zoomdata if it doesn't already exist
      if groupID is None:
        data = '{"group":{"accountId":"'+zoomdataAccountID+'","configType":"manualAccess","label":"'+adGroup+'","description":"Auto Import AD Group","roles":["ROLE_SAVE_DASHBOARDS","ROLE_SAVE_FILTERS","ROLE_EDIT_FORMULAS","ROLE_READ_FORMULAS","ROLE_CREATE_SOURCES"]},"bookmarks":[],"sources":[],"userIds":[]}'

        try:
          groupID = json.loads(zoomdataServerRequest.submit(zoomdataBaseURL+'/service/groups',data))['group']['id']
          print("+ User Group "+adGroup+" successfully created")
        except:
            print("- User Group "+adGroup+" could not be created")
            e = sys.exc_info()
            print e
      #retrieve group object from the server
      groupObject = json.loads(zoomdataServerRequest.submit(zoomdataBaseURL+'/service/groups/'+groupID))

      #[IMPORTANT] the next line will remove all currently accessible datasources from the group the first time the group is encourntered. The assumption here is that they will be added back according to what is configured in the mapping csv.
      if groupID not in resetGroupList:
        groupObject["sources"] = json.loads('[]')
        resetGroupList.append(groupID)
        print("+ Data Source security reset for "+adGroup)

      #add source access to group object
      groupObject["sources"].append(json.loads('{"id":"'+sourceID+'","admin":false,"create":false,"delete":false,"read":true,"write":false,"type":"SOURCE"}'))
      #post updated group object back to server
      zoomdataServerRequest.submit(zoomdataBaseURL+'/service/groups',json.dumps(groupObject))
      print("+ Access to data source "+sourceName+" added for group "+adGroup)

      rowCounter += 1
main()
