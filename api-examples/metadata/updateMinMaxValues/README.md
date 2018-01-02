# Copyright (C) Zoomdata, Inc. 2012-2018. All rights reserved.

# Purpose of this Example
 
This example code enables a user to programmatically update the minimum and maximum values for a source's field in Zoomdata. The example will take the following configuration parameters in `scheduler-minMax-override.sh`:
* `Username` - The admin account that will be invoking the API calls.
* `Password` - The admin account's password
* `Host` - The host location where Zoomdata exists
* `Source ID` - The Source's Identifier (determined by looking at the last bit of the source's URL)
* `Field Name` - The Field you are looking to set the minimum and maximum for
* `Minimum` - The minimum for the field (as a Epoch in Milliseconds for Time fields, or as an integer for Numeric fields)
* `Maximum` - The maximum for the field (as a Epoch in Milliseconds for Time fields, or as an integer for Numeric fields)

## How does it work?

The code will:
1. Make an internal API call in order to get the Source's initial configuration JSON
2. This configuration JSON is passed off to the python script for parsing and updating
3. This updated configration JSON is passed back and send off via another internal API call to update the source configuration

## Version Recommendations

Tested against Zoomdata 2.5.x and 2.6.x
