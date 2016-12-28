#!/usr/bin/env python

from __future__ import print_function
import requests
import argparse
import json
from tempfile import gettempdir
from os.path import getmtime
from time import time


__author__ = 'eugene@zoomdata.com'

DEFAULT_IMPALAD_METRICS_PORT = 25000
DEFAULT_IMPALAD_METRICS_URI = "metrics"
DEFAULT_IMPALAD_SESSIONS_URI = "sessions"

DEFAULT_TIMEOUT = 60

DEFAULT_TMP_FILE_FORMAT = '{dir}/impalad-{host}-{uri}-cache.tmp'


def parse_args():
    parser = argparse.ArgumentParser(description='Zabbix external check for Zoomdata')
    parser.add_argument('host', help='Impalad host to collect metrics from')
    parser.add_argument('metric', help='Impalad metric to get')
    parser.add_argument('-p', '--port', dest='port', help='tcp port to connect to',
                        default=DEFAULT_IMPALAD_METRICS_PORT)
    parser.add_argument('-m', '--metrics_uri', dest='metrics_uri', help='Impalad server metrics stats URI',
                        default=DEFAULT_IMPALAD_METRICS_URI)
    parser.add_argument('-s', '--sessions_uri', dest='sessions_uri', help='Impalad server sessions stats URI',
                        default=DEFAULT_IMPALAD_SESSIONS_URI)
    return parser.parse_args()


def get_tmp_file_name(args, uri):
    return DEFAULT_TMP_FILE_FORMAT.format(dir=gettempdir(), host=args.host, uri=uri.replace('/', '-'))


def check_cache_valid(args, uri):
    # check if cache file is exist
    try:
        mtime = getmtime(get_tmp_file_name(args, uri))
    except OSError as e:
        return False

    # is this file was created within default interval?
    if (int(time()) - mtime) > DEFAULT_TIMEOUT:
        return False

    return True


def request_metrics_data(args, uri):
    # constructing URL to query metrics from
    url = 'http://{host}:{port}/{uri}?json'.format(host=args.host, port=args.port, uri=uri)
    # proceeding with query metrics
    try:
        r = requests.get(url, verify=False, allow_redirects=True)
    except requests.ConnectionError as e:
        print("Unable to connect to ", url, " error is ", e, file=sys.stderr)
        return False

    if r.status_code == 200:
        # got HTTP/200 for request - storing it in cache
        open(get_tmp_file_name(args, uri), mode="w").write(json.dumps(r.json()))
    else:
        return False

    return True


def search_for_key(dict, keyname):
    if keyname in dict:
        yield dict[keyname]
    for key in dict:
        if isinstance(dict[key], list):
            for item in dict[key]:
                for s in search_for_key(item, keyname):
                    yield s


def get_metric_by_key(args, uri):
    # loading cached file with metrics
    try:
        metrics = json.loads(open(get_tmp_file_name(args, uri), mode='r').read())
    except IOError as e:
        print("Error loading/parsing metrics cache file, ", e, file=sys.stderr)
        return None

    return list(search_for_key(metrics, args.metric))


def main():
    args = parse_args()
    res = []
    for uri in [args.metrics_uri, args.sessions_uri]:
        if not check_cache_valid(args, uri):
            if not request_metrics_data(args, uri):
                print("Unable to get metrics data", file=sys.stderr)

        res.extend(get_metric_by_key(args, uri))

    print(res[0] if len(res) > 0 else '')

if __name__ == "__main__":
    main()
