#!/usr/bin/env python
from base_classes.zoomdata_api_base import ZoomdataRequest
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
  #ImpalaConnection = zoomdataInfo["ImpalaConnectionID"]
  debug = zoomdataInfo["debugMode"]

  #create the Zoomdata request object
  zoomdataServerRequest = ZoomdataRequest(zoomdataBaseURL, adminUser, adminPassword)
  # Enable verbose output if desired
  if debug.lower() == "yes":
    zoomdataServerRequest.enableDebug()

  #begin parsing the group file; Its assumed this file has a column name header; Rows are processed one at a time
  roleConfigFile = sys.argv[1]
  rowCounter = 1

  with open(roleConfigFile, 'rU') as csvfile:
    print("-- Reading from "+roleConfigFile+" --")
    reader = csv.DictReader(csvfile)
    for row in reader:
      print("----------------------------------------")
      print("-- Processing row #"+str(rowCounter)+" --")
      #retrieve a list of available user groups in Zoomdata
      currentGroups = json.loads(zoomdataServerRequest.submit(zoomdataBaseURL+'/service/groups?accountId='+zoomdataAccountID))

      groupID = None
      groupName = row['group']

      #Look up the group by name in the currently configured group list
      try:
        groupID = [x for x in currentGroups if x["label"] == groupName][0]['id']

        groupObject = json.loads(zoomdataServerRequest.submit(zoomdataBaseURL+'/service/groups/'+groupID))

        groupObject["sources"] = json.loads('[]')

        zoomdataServerRequest.submit(zoomdataBaseURL+'/service/groups',json.dumps(groupObject))
        print("+ [ROW:"+str(rowCounter)+"] Access to all data sources has been removed for group "+groupName)
      except IndexError:
        groupID = None
        print("- [ROW:"+str(rowCounter)+"] User Group "+groupName+" could not be found. Check spelling and case")
      except:
        print("- [ROW:"+str(rowCounter)+"] Unkown Error:")
        e = sys.exc_info()
        print e

      rowCounter += 1
main()
