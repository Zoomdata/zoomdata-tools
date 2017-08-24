#!/usr/bin/python
import sys
import json

if len(sys.argv) == 5:
	inputJson = sys.argv[1]
	fieldName = sys.argv[2]
	minimum = sys.argv[3]
	maximum = sys.argv[4]

	parsed = json.loads(inputJson)
	objectFields = parsed["objectFields"]
	count = 0
	for field in objectFields:
	    if field["label"] == fieldName:
			field["overrideMin"] = int(minimum)
			field["overrideMax"] = int(maximum)
			field["refreshable"] = False
	print json.dumps(parsed, indent=4, sort_keys=True)
else:
	log = "\033[1;31;40m ERROR: Requires 4 arguments to be passed to Python Script:\n" 
	log += "\033[0;37;40m(1) The Source Config JSON\n(2) The Field Name to be Changed\n(3) The Minimum Value for this Field Name\n(4) The Maximum Value for this Field Name\n"
	raise Exception(log)
