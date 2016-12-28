#!/usr/bin/env python

from __future__ import print_function
import requests
import argparse
import json

from os.path import getmtime
from time import time
from tempfile import gettempdir

__author__ = 'eugene@zoomdata.com'

DEF_TIMEOUT = 60
DEF_CONTEXT = 'zoomdata'
DEF_METRICS_URI = 'service/system/info/metrics'
DEF_SCHEMA = 'http'
DEF_PORT = '8080'
DEF_TMP_FILE_FORMAT = '{0}/{1}-{2}-{3}-metrics-cache.tmp'


def parse_args():
    parser = argparse.ArgumentParser(description='Zabbix external check for Zoomdata')
    parser.add_argument('host', help='host to collect metrics from')
    parser.add_argument('metric', help='host to collect metrics from')
    parser.add_argument('-s', '--schema', dest='schema', help='http/https', default=DEF_SCHEMA)
    parser.add_argument('-p', '--port', dest='port', help='tcp port to connect to', default=DEF_PORT)
    parser.add_argument('-c', '--context', dest='context', help='Zoomdata server context', default=DEF_CONTEXT)
    parser.add_argument('-u', '--metrics_uri', dest='metrics_uri', help='Zoomdata server metrics URI', default=DEF_METRICS_URI)

    return parser.parse_args()


def get_tmp_file_name(args):
    return DEF_TMP_FILE_FORMAT.format(gettempdir(), args.host, args.context, args.metrics_uri.replace('/', '-'))


def check_cache_valid(args):
    # check if cache file is exist
    try:
        mtime = getmtime(get_tmp_file_name(args))
    except OSError as e:
        return False

    # is this file was created within default interval?
    if (int(time()) - mtime) > DEF_TIMEOUT:
        return False

    return True


def request_metrics_data(args):
    # constructing URL to query metrics from
    url = '{0}://{1}:{2}/{3}/{4}'.format(args.schema, args.host, args.port, args.context, args.metrics_uri)
    # proceeding with query metrics
    try:
        r = requests.get(url)
    except requests.ConnectionError as e:
        print("Unable to connect to ", url, " error is ", e, file=sys.stderr)
        return False

    if r.status_code == 200:
        # got HTTP/200 for request - storing it in cache
        open(get_tmp_file_name(args), mode="w").write(json.dumps(r.json()))
    else:
        return False

    return True


def get_metric_by_key(args):
    # loading cached file with metrics
    try:
        metrics = json.loads(open(get_tmp_file_name(args), mode='r').read())
    except IOError as e:
        print("Error loading/parsing metrics cache file, ", e, file=sys.stderr)

    try:
        dt = metrics
        for key in args.metric.split(':'):
            dt = dt[key]
        return dt
    except IndexError as e:
        print("Incorrect key, ", e, file=sys.stderr)
        return None


def main():
    args = parse_args()
    if not check_cache_valid(args):
        if not request_metrics_data(args):
            print("Unable to get metrics data", file=sys.stderr)

    res = get_metric_by_key(args)
    print(res if res else '')


if __name__ == '__main__':
    main()