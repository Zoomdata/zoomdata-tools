#!/usr/bin/env python3
"""
Script to auto adjust memory settings for Zoomdata application.
"""

from __future__ import print_function
import sys
import logging
import argparse
import subprocess
from os import sysconf, rename
from os.path import isfile, join as path_join
from re import match as re_match, sub as re_sub


APP_NAME = "zoomdata"
DEFAULT_CONF_DIR = f"/etc/{APP_NAME}"
DEFAULT_INSTALL_DIR = f"/opt/{APP_NAME}"

JVM_MEMORY_REGEXP = r'^-X(?P<mem_type>mx|ms)(?P<mem_amount>\d+)(?P<mem_unit>k|m|g)?$'
JVM_MEMORY_MX_REGEXP = r'^-Xmx\d+(k|m|g)?$'

# Amount of memory consumed by OS+Zoomdata metadata storage (PostgreSQL) in Mb
MINIMUM_NON_ZOOMDATA_MEMORY = 1000


parser = argparse.ArgumentParser(description="Script to auto adjust memory settings for Zoomdata application.")
parser.add_argument('allowed_memory', metavar='ALLOWED_MEMORY', type=int, nargs='?',
                    help='allowed memory to adjust (Optional, default: all memory)')
parser.add_argument('--config-dir', dest='config_location',
                    default=DEFAULT_CONF_DIR, type=str,
                    help=f"Config dir to put <component>.env files. (default: {DEFAULT_CONF_DIR})")
parser.add_argument('--install-path', dest='install_location',
                    default=DEFAULT_INSTALL_DIR, type=str,
                    help=f"Zoomdata installation folder. (default: {DEFAULT_INSTALL_DIR})")
parser.add_argument('--verbose', dest='verbose',
                    default=False, action="store_true",
                    help="Allow extended output")
args = vars(parser.parse_args())


# Preparing Logger
logging.basicConfig(format='%(levelname)s - %(message)s')
logger = logging.getLogger(__name__)
logger.setLevel('INFO')


def get_total_memory() -> int:
    """
    Get total memory in mb.
    :return:
    """
    return int(sysconf('SC_PAGE_SIZE') * sysconf('SC_PHYS_PAGES') / (1024.0 ** 2))


def lookup_installed_services() -> list:
    """
    Returns list of installed Zoomdata services like: ['zoomdata', 'query-engine', 'scheduler'...]
    :return: list of service names
    """

    command = f"systemctl list-units --type=service --state=active --no-pager --no-legend --full {APP_NAME}*"
    proc = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.wait() != 0:
        logger.error('Command "%s" returned non-zero exit code! Error: %s',
                     command, proc.stderr.read())
        sys.exit(1)

    services_list = list(filter(None, [string.split('.service')[0] for string in proc.stdout.read().decode('utf-8').split('\n')]))

    if args['verbose']:
        logger.info("Found %s installed Zoomdata services: %s", len(services_list), services_list)

    # remove prefix from systemd service names
    return [service.replace(f"{APP_NAME}-", "") for service in services_list]


def parse_jvm_mem_option(jvm_mem_option: str) -> dict:
    """
    Parse JVM memory option.
    :param jvm_mem_option:
    :return:
    """
    jvm_mem_info = re_match(JVM_MEMORY_REGEXP, jvm_mem_option)
    if not jvm_mem_info:
        return {}

    mem_unit = jvm_mem_info.group('mem_unit')
    mem_amount = int(jvm_mem_info.group('mem_amount'))
    mem_type = 'min' if jvm_mem_info.group('mem_type') == 'ms' else 'max'

    if mem_unit:
        if mem_unit == 'g':
            return {mem_type: mem_amount * 1024}
        elif mem_unit == 'k':
            return {mem_type: mem_amount / 1024}
        else:
            return {mem_type: mem_amount}
    else:
        return {mem_type: mem_amount / (1024 ** 2)}


def load_service_memory_defaults(service_name: str) -> dict:
    """
    Loads service's memory defaults for given service name.
    Returns dict with 'min':val and 'max':val memory configured options
    Config files lookup location order:
     - install_path/conf/
     - /etc/zoomdata/
    :param service_name: Zoomdata service name to load memory into for
    :return:
    """

    service_memory_info = {}
    raw_mem_max = []
    user_mod_conf = False

    # looking for config in <install_path>/conf/
    service_conf_file = path_join(args['install_location'], "conf/" + service_name + ".jvm")
    if isfile(service_conf_file):
        if args['verbose']:
            logger.info("Found default config for '%s' service", service_name)
        raw_mem_max = list(filter(lambda x: x.startswith("-Xmx"), open(service_conf_file).readlines()))
    else:
        logger.error("Can't access config file: %s", service_conf_file)
        sys.exit(1)

    # looking for config in /etc/zoomdata/ (possibly overriding previously loaded options)
    service_conf_file = path_join(args['config_location'], service_name + ".jvm")
    if isfile(service_conf_file):
        if args['verbose']:
            logger.info("Found user modified config for '%s' service", service_name)
        raw_mem_max = list(filter(lambda x: x.startswith("-Xmx"), open(service_conf_file).readlines()))
        user_mod_conf = True


    service_memory_info.update(parse_jvm_mem_option(raw_mem_max[0]) if len(raw_mem_max) > 0 else {})

    if user_mod_conf:
        service_memory_info['user_modified'] = True

    if args['verbose']:
        logger.info("Loaded '%s' memory max is: %sMb",
            service_name,
            service_memory_info['max'] if 'max' in service_memory_info.keys() else 0
        )

    return service_memory_info


def prepare_memory_map(available_memory: int) -> dict:
    """
    Load memory setting for each Zoomdat service, prepares memory map
    :param available_memory: Memory amount available for distribution
    :return:
    """

    installed_services = lookup_installed_services()

    if not installed_services:
        logger.error("No installed Zoomdata services found! Aborting.")
        sys.exit(1)


    services = {}
    for service in installed_services:
        services.update({service: load_service_memory_defaults(service)})

    # Calc all amount of memory consumed by all services with default config.
    all_requested_memory = sum(
        [services[srv]['max'] if 'max' in services[srv] else 0 for srv in services]
    )

    if args['verbose']:
        logger.info("All memory requested by %s Zoomdata services is %sMb",
                    installed_services, all_requested_memory)

    if all_requested_memory > available_memory:
        # instance doesn't have enough memory to run all installed services
        # possible memory overcommitment
        logger.error("Physical available memory (%sMb) is less then requested "
              "by Zoomdata components (%sMb). Aborting.", available_memory, all_requested_memory)
        sys.exit(1)
    else:
        # no memory overcommitment - proceed with mapping memory.
        for service in services:
            if 'max' in services[service]:
                services[service]['adj-max'] = int(available_memory * services[service]['max']
                                                   / float(all_requested_memory))

    return services


def apply_memory_map(services_memory_map: dict) -> bool:
    """
    Generates new config files for each Zoomdat aservice with new, adjusted memory settings
    :param services_memory_map:
    :return:
    """

    adjusted_services_count = sum(
        [1 if 'adj-max' in services_memory_map[service].keys() else 0 for service in services_memory_map.keys()]
    )

    if adjusted_services_count == 0:
        logger.info("Nothing to apply.")
        sys.exit(0)

    for service in services_memory_map.keys():

        if args['verbose']:
            logger.info("Applying memory settings for service: %s, Xmx%sm(%s)", service,
                        services_memory_map[service]['adj-max'],
                        services_memory_map[service]['max'])

        if 'adj-max' not in services_memory_map[service].keys():
            # no adjusted memory setting found.
            if args['verbose']:
                logger.info("No adjusted max memory settings for service: %s", service)
            continue

        source_file_name = path_join(args['install_location'], "conf/" + service + ".jvm")
        target_file_name = path_join(args['config_location'], service + ".jvm")
        if 'user_modified' in services_memory_map[service].keys():
            # we have some custom modifications in /etc/zoomdata/service.jvm
            # rename old file to ".bak" to store previous state
            try:
                rename(target_file_name, target_file_name + ".bak")
            except IOError as error:
                logger.error("Unable to make backup of config file %s\nReason: %s",
                             target_file_name, error)
                return False
            source_file_name = path_join(args['config_location'], service + ".jvm.bak")

        with open(source_file_name, "r") as source, open(target_file_name, "w") as target:
            for line in source.readlines():
                target.write(
                    re_sub(JVM_MEMORY_MX_REGEXP, "-Xmx{}m".format(
                        services_memory_map[service]['adj-max']), line)
                )

    return True


def main():
    """
    Main
    :return:
    """

    mem_total = args.get('allowed_memory') if args.get('allowed_memory') else get_total_memory()
    mem_avail = mem_total - MINIMUM_NON_ZOOMDATA_MEMORY

    logger.info("Total memory: %sMb, Available for distribution: %sMb", mem_total, mem_avail)

    if not apply_memory_map(prepare_memory_map(mem_avail)):
        logger.error("Failed to apply memory settings for Zoomdata services")
        sys.exit(1)

    logger.info("Successfully applied new memory settings for Zoomdata services")


if __name__ == "__main__":
    main()
