#!/usr/bin/env python

from __future__ import print_function
import sys
import datetime
from os import (sysconf, listdir, rename)
from os.path import (basename, dirname, exists,
                     isfile, realpath, join as path_join)
from re import (match as re_match,
                sub as re_sub)
from fnmatch import filter as fnfilter
from optparse import OptionParser

# where to store components configs
DEFAULT_CONF_DIR = "/etc/zoomdata"
DEFAULT_INSTALL_DIR = "/opt/zoomdata"

JVM_MEMORY_REGEXP = r'^-X(?P<mem_type>mx|ms)(?P<mem_amount>\d+)(?P<mem_unit>k|m|g)?$'
JVM_MEMORY_MX_REGEXP = r'^-Xmx\d+(k|m|g)?$'

DEFAULT_INFO_STAMP_TEMPLATE = "# Total instance memory: {0}, Generation date: {1}\n"

# Amount of memory consumed by OS+Zoomdata metadata storage (PostgreSQL) in Mb
MINIMUM_NON_ZOOMDATA_MEMORY = 1000

HELP_MESSAGE = """%prog [options] allowed_mem

  Script to auto adjust memory settings for Zoomdata application and components.

"""


def get_total_memory():
    return int(sysconf('SC_PAGE_SIZE') * sysconf('SC_PHYS_PAGES') / (1024.0 ** 2))


def parse_args():
    parser = OptionParser(usage=HELP_MESSAGE)
    parser.add_option("--config-dir", dest="config_location",
                      default=DEFAULT_CONF_DIR, type="string",
                      help="Config dir to put <component>.env files. Default: {0}".format(DEFAULT_CONF_DIR)
                      )
    parser.add_option("--install-path", dest="install_location",
                      default=DEFAULT_INSTALL_DIR, type="string",
                      help="Zoomdata installation folder"
                      )
    parser.add_option("--verbose", dest="verbose",
                      default=False, action="store_true",
                      help="Allow extended output"
                      )
    return parser.parse_args()


def lookup_installed_services(app_options):
    """
    Returns list of installed Zoomdata services like: ['zoomdata', 'query-engine', 'scheduler', 'edc-impala']
    :param app_options: options passed to application
    :return: list on names
    """

    services_list = []

    if not isfile(path_join(app_options.install_location, "bin/zoomdata")):
        # main Zoomdata startup script not found - failing by returning empty list
        print("[Error] No Zoomdata executable found while looking up for installed services.")
        return services_list
    else:
        services_list.append("zoomdata")

    services_list.extend([filename.split('-', 1)[1] for filename in
                          fnfilter(listdir(path_join(app_options.install_location, "bin/")), "zoomdata-*")])
    if app_options.verbose:
        print("Found {} installed Zoomdata services: {}".format(len(services_list), services_list))

    return services_list


def parse_jvm_mem_option(jvm_mem_option):
    m = re_match(JVM_MEMORY_REGEXP, jvm_mem_option)
    if not m:
        # given option is not matched by Regular expression, failing with return None
        return None

    unit = m.group('mem_unit')
    amount = int(m.group('mem_amount'))
    type = 'min' if m.group('mem_type') == 'ms' else 'max'

    if unit:
        if unit == 'g':
            return {type: amount * 1024}
        elif unit == 'k':
            return {type: amount / 1024}
        else:
            return {type: amount}
    else:
        return {type: amount / (1024 ** 2)}


def load_service_memory_defaults(service_name, app_options):
    """
    Loads service's memory defaults for given service name.
    Returns dict with 'min':val and 'max':val memory configured options
    Config files lookup location order:
     - install_path/conf/
     - /etc/zoomdata/
    :param service_name: Zoomdata service name to load memory into for
    :param app_options: options passed to application
    :return: dict
    """

    service_memory_info = {}
    raw_mem_max = []
    user_mod_conf = False

    # looking for config in <install_path>/conf/
    service_conf_file = path_join(app_options.install_location, "conf/" + service_name + ".jvm")
    if isfile(service_conf_file):
        if app_options.verbose:
            print("Found default config for '{}' service".format(service_name))
        raw_mem_max = list(filter(lambda x: x.startswith("-Xmx"), open(service_conf_file).readlines()))

    # looking for config in /etc/zoomdata/ (possibly overriding previously loaded options)
    service_conf_file = path_join(app_options.config_location, service_name + ".jvm")
    if isfile(service_conf_file):
        if app_options.verbose:
            print("Found user modified config for '{}' service".format(service_name))
        raw_mem_max = list(filter(lambda x: x.startswith("-Xmx"), open(service_conf_file).readlines()))
        user_mod_conf = True

    service_memory_info.update(parse_jvm_mem_option(raw_mem_max[0]) if len(raw_mem_max) > 0 else {})

    if user_mod_conf:
        service_memory_info['user_modified'] = True

    if app_options.verbose:
        print("Loaded '{}' memory max is: {}Mb".format(
            service_name,
            service_memory_info['max'] if 'max' in service_memory_info.keys() else 0
        ))

    return service_memory_info


def prepare_memory_map(available_memory, app_options):
    """
    Load memory setting for each Zoomdat service, prepares memory map
    :param available_memory: Memory amount available for distribution
    :param app_options: options passed to application
    :return:
    """

    installed_services = lookup_installed_services(app_options)
    services = {}

    if installed_services == {}:
        print("Error! No installed Zoomdata services found! Aborting.")
        return services

    for service in installed_services:
        services.update({service: load_service_memory_defaults(service, app_options)})

    # Calc all amount of memory consumed by all services with default config.
    all_requested_memory = sum(
        [services[srv]['max'] if 'max' in services[srv].keys() else 0 for srv in services.keys()]
    )

    if app_options.verbose:
        print("All memory requested by {} Zoomdata services is {}Mb".format(len(installed_services),
                                                                            all_requested_memory))

    if all_requested_memory > available_memory:
        # instance doesn't have enough memory to run all installed services
        # possible memory overcommitment
        print("Error! Physical available memory ({}Mb) is less then requested "
              "by Zoomdata components ({}Mb). Aborting.".format(available_memory, all_requested_memory))
        return services
    else:
        # no memory overcommitment - proceed with mapping memory.
        for service in services.keys():
            if 'max' in services[service].keys():
                services[service]['adj-max'] = int(available_memory * services[service]['max']
                                                   / float(all_requested_memory))

    return services


def apply_memory_map(services_memory_map, app_options):
    """
    Generates new config files for each Zoomdat aservice with new, adjusted memory settings
    :param services_memory_map:
    :param app_options: options passed to application
    :return:
    """

    adjusted_services_count = sum(
        [1 if 'adj-max' in services_memory_map[service].keys() else 0 for service in services_memory_map.keys()]
    )

    if adjusted_services_count == 0:
        print("Error! Nothing to apply.")
        return False

    for service in services_memory_map.keys():

        if app_options.verbose:
            print("Applying memory settings for service: ", service)

        if 'adj-max' not in services_memory_map[service].keys():
            # no adjusted memory setting found.
            if app_options.verbose:
                print("  No adjusted max memory settings for service: ", service)
            continue

        source_file_name = path_join(app_options.install_location, "conf/" + service + ".jvm")
        target_file_name = path_join(app_options.config_location, service + ".jvm")
        if 'user_modified' in services_memory_map[service].keys():
            # we have some custom modifications in /etc/zoomdata/service.jvm
            # rename old file to ".bak" to store previous state
            try:
                rename(target_file_name, target_file_name + ".bak")
            except IOError as e:
                print("Error! Unable to make backup of config file {}\nReason: {}".format(target_file_name, e.stderror))
                return False
            source_file_name = path_join(app_options.config_location, service + ".jvm.bak")

        with open(source_file_name, mode="r") as source:
            with open(target_file_name, mode="w") as target:
                for line in source.readlines():
                    target.write(
                        re_sub(JVM_MEMORY_MX_REGEXP, "-Xmx{}m".format(
                            services_memory_map[service]['adj-max']), line)
                    )

    return True


def main():
    opts, args = parse_args()

    mem_total_instance = get_total_memory()

    if len(args) >= 1:
        mem_total = int(sys.argv[1])
    else:
        mem_total = mem_total_instance

    # reducing avail memory by minimum non zoomdata memory
    mem_avail = mem_total - MINIMUM_NON_ZOOMDATA_MEMORY

    mem_left = mem_avail

    print("Total memory: {0}Mb, Available for distribution: {1}Mb".format(mem_total, mem_avail))

    if apply_memory_map(prepare_memory_map(mem_left, opts), opts):
        print("Successfully applied new memory settings for Zoomdata services")
    else:
        print("Failed to apply memory settings for Zoomdata services")


if __name__ == "__main__":
    main()
