#!/usr/bin/env python

from __future__ import print_function
import requests
import argparse
import json
import sys

from requests.packages.urllib3.exceptions import InsecureRequestWarning
from os.path import getmtime
from time import time
from tempfile import gettempdir
try:
    from urllib.parse import urlparse
except ImportError:
    from urlparse import urlparse


__author__ = 'eugene@zoomdata.com'


DEF_SCHEMA = 'http'
DEF_PORT = '8080'
DEF_CONTEXT = 'zoomdata'


class MetricsCollector(object):
    def __init__(self, base_url, cache_lifetime=30):
        self.data_url = base_url
        self.parsed_url = urlparse(self.data_url)
        self.cache_lifetime = cache_lifetime
        self.last_request_status = False
        self.temp_file_name = "{tmpdir}/metrics-cache-{host}-{port}{uri}.tmp".format(
            tmpdir = gettempdir(),
            host = self.parsed_url.hostname,
            port = self.parsed_url.port,
            uri = self.parsed_url.path.replace('/', '-')
        )

    def get_last_request_status(self):
        return self.last_request_status

    def __is_cache_valid(self):
        # check if cache file is exist
        try:
            mtime = getmtime(self.temp_file_name)
        except OSError as e:
            return False

        # is this file was created within default interval?
        if (int(time()) - mtime) > self.cache_lifetime:
            return False

        return True

    def __request_data(self):
        if self.__is_cache_valid():
            return True

        # requesting data
        try:
            # setting 5 sec timeouts for connect and read
            r = requests.get(self.data_url, verify=False, allow_redirects=True, timeout=(5, 5))
        except requests.ConnectionError as e:
            print("Unable to connect to ", self.data_url, " error is ", e, file=sys.stderr)
            return False
        except requests.ConnectTimeout as e:
            print("Timed out connection to ", self.data_url, " error is ", e, file=sys.stderr)
            return False
        except requests.ReadTimeout as e:
            print("Timed out while reading data from ", self.data_url, " error is ", e, file=sys.stderr)
            return False

        if r.status_code == 200:
            # got HTTP/200 for request - storing it in cache
            try:
                open(self.temp_file_name, mode="w").write(json.dumps(r.json()))
            except IOError as e:
                print("IO error while trying to store cache into file ", self.temp_file_name, " error is ",
                      e, file=sys.stderr)
                return False
            return True
        else:
            return False

    def get_key(self, key):
        # mandatory call to fetch data / refresh cache
        self.last_request_status = self.__request_data()
        if not self.last_request_status:
            return None

        metrics = {}

        try:
            metrics = json.loads(open(self.temp_file_name, mode='r').read())
        except IOError as e:
            print("Error loading/parsing metrics cache file ", self.temp_file_name, " error is ", e, file=sys.stderr)
            return None

        try:
            for key in key.split(':'):
                # looking for '*' in key
                if '*' in key:
                    (key_starts_with, sep, key_ends_with) = key.rpartition('*')
                    new_key = list(filter(lambda x: x.startswith(key_starts_with) and x.endswith(key_ends_with),
                                          list(metrics.keys())))[0]
                    metrics = metrics[new_key]
                else:
                    metrics = metrics[key]
            return metrics
        except:
            #print("Key ", key, " not found in data received from ", self.data_url, file=sys.stderr)
            return None


def parse_args():
    parser = argparse.ArgumentParser(description='Zabbix external check for Zoomdata')
    parser.add_argument('host', help='host to collect metrics from')
    parser.add_argument('metric', help='host to collect metrics from')
    parser.add_argument('-s', '--schema', dest='schema', help='http/https', default=DEF_SCHEMA)
    parser.add_argument('-p', '--port', dest='port', help='tcp port to connect to', default=DEF_PORT)
    parser.add_argument('-c', '--context', dest='context', help='Zoomdata server context', default=DEF_CONTEXT)

    return parser.parse_args()


def main():
    args = parse_args()

    # Construct base url for zoomdata:
    zoomdata_base_url = "{schema}://{host}:{port}/{context}".format(
        schema=args.schema,
        host=args.host,
        port=args.port,
        context=args.context
    )

    spark_base_url = "{schema}://{host}:{port}".format(
        schema=args.schema,
        host=args.host,
        port=4040
    )

    data_endpoints = []
    data_endpoints.append(MetricsCollector(zoomdata_base_url + '/service/system/info/metrics'))
    data_endpoints.append(MetricsCollector(zoomdata_base_url + '/service/metrics_grouped'))
    data_endpoints.append(MetricsCollector(spark_base_url + '/metrics/json'))

    result = None
    for dep in data_endpoints:
        result = dep.get_key(args.metric)
        if result is not None:
            break

    print(result if result is not None else '')


if __name__ == '__main__':
    # switch off warings for self signed certificates
    requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
    main()
