#!/usr/bin/python

import sys
import json
import requests
import socket
import md5

from os.path import getmtime
from time import time
from tempfile import gettempdir

nodeName = socket.gethostname()
#print nodeName

url = 'http://127.0.0.1:8500/v1/health/node/{0}'.format(nodeName)
#print url

CACHE_TIMEOUT=60
TEMP_FILE_NAME="{}/consul-zabbix-checker-cache.dat".format(gettempdir())

def is_cache_valid():
    # check if cache file is exist
    try:
        mtime = getmtime(TEMP_FILE_NAME)
    except OSError as e:
        return False

    # is this file was created within default interval?
    if (int(time()) - mtime) > CACHE_TIMEOUT:
        return False

    return True

def getDiscovery():
    discovery_list = {}
    discovery_list['data'] = []

    nodeServices = requests.get(url).text

    services = json.loads(nodeServices)
    for service in services:
        if service['CheckID'] != 'serfHealth':
            #print service['Status']
            #print service['ServiceName']
            zbx_item = {"{#SERVICEID}": service['ServiceID']}
            discovery_list['data'].append(zbx_item)
    print json.dumps(discovery_list, indent=4, sort_keys=True)

def getStatus(ServiceID):
    if not is_cache_valid():
        nodeServices = requests.get(url).text
        try:
            open(TEMP_FILE_NAME, mode="w").write(nodeServices)
        except OSError as e:
            pass
        services = json.loads(nodeServices)
    else:
        try:
            services = json.loads(open(TEMP_FILE_NAME, mode='r').read())
        except IOError as e:
            status=0
            print status
            return
    status = 0
    for service in services:
        if service['ServiceID'] == ServiceID:
            if service['Status'] == 'passing':
                status = 1
            else:
                status = 0
    print status

action = sys.argv[1].lower()
if action == 'discovery':
    getDiscovery()
elif action == 'status':
    serviceID = sys.argv[2]
    getStatus(serviceID)

