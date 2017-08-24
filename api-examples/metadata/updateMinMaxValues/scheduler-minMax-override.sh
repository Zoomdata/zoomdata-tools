#!/bin/bash

#####
#	Zoomdata and Source Config
#####
USERNAME="admin" # Account with Admin Credentials
PASSWORD="password" # Account Password
HOST="https://sub.domain.com" # Host (and Port if required)
SOURCEID="uuid" # Source ID
FIELDNAME="FieldName" # Human Readable Field Name
MINIMUM=740102400000 #Epoch Time in Milliseconds (beginning)
MAXIMUM=960768000000 #Epoch Time in Milliseconds (end)

#####
#	API Call to get Source Config
#####
PAYLOAD="$(curl -s --user $USERNAME:$PASSWORD -XGET $HOST/zoomdata/service/sources/$SOURCEID)"

#echo $PAYLOAD > ~/Desktop/initialcurl.out
#####
#	Modify JSON by sending it to Python Script
#####
PYLOAD=`python parser-minMax.py "$PAYLOAD" "$FIELDNAME" $MINIMUM $MAXIMUM`

#echo "$PYLOAD" > ~/Desktop/pyload.out


#####
#	Update the Source Config with a PUT/PATCH call
#####
curl -s --user $USERNAME:$PASSWORD $HOST/zoomdata/service/sources/$SOURCEID -X PATCH -H 'Content-Type: application/json' -d "$PYLOAD" > /dev/null
